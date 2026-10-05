# Win11 Box

Libvirt domain for the Windows 11 VM that GNOME Boxes runs, plus the guest
provisioning that goes with it.

`Win11.xml` (a template; `apply.sh` fills in `${HOME}`) lives in the **session** libvirt daemon (`qemu:///session`), not the
system one — that is where Boxes keeps its VMs.

## What this gives you

| | |
|---|---|
| Shared folder | `~/Shared` on the host → `Z:\` in the guest (virtiofs) |
| Remote Desktop | `127.0.0.1:3389` |
| WinRM (HTTP) | `127.0.0.1:5985` |
| WinRM (HTTPS) | `127.0.0.1:5986` |
| Go | installed and kept current automatically |

## Applying it

```bash
cd ~/Work/github/setup/linux/arch/boxes
./apply.sh
```

The VM must be shut down. `apply.sh` installs `passt`, creates `~/Shared`,
builds the provisioning ISO, backs up the current domain definition and
redefines the domain.

Then boot the VM, open `D:\` and run **`Bootstrap.cmd` as administrator**. That
one manual step is unavoidable — see [First run](#first-run) below.

## How each piece works

### Port forwarding (WinRM + RDP)

The interface stays `type="user"` (no root, no bridge) but switches its backend
from slirp to **passt**:

```xml
<interface type="user">
  <backend type="passt"/>
  <portForward proto="tcp" address="127.0.0.1">
    <range start="3389"/>
  </portForward>
  <portForward proto="tcp" address="127.0.0.1">
    <range start="5985" end="5986"/>
  </portForward>
</interface>
```

`<portForward>` is only implemented on the passt backend — libvirt has no
port-forwarding support for slirp at all, so **the domain will not start unless
`passt` is installed**. `apply.sh` installs it and refuses to define the domain
if it is still missing, because the failure is otherwise near-silent: Boxes just
says the VM could not start, and `~/.cache/gnome-boxes/logs/win11.logs` shows
only

```
Starting external device: passt
passt --one-off --socket ... --tcp-ports 127.0.0.1/3389 --tcp-ports 127.0.0.1/5985-5986
shutting down, reason=failed
```

with no error text and a timestamp one millisecond later. That is libvirt
failing to exec the binary. Same applies to `virtiofsd` and the shared folder.

Ports bind to `127.0.0.1`, so the guest is reachable from this machine only.
Drop the `address` attribute to expose them on the LAN.

### Shared folder

A virtiofs `<filesystem>` device, which needs shared memory on the domain:

```xml
<memoryBacking>
  <source type="memfd"/>
  <access mode="shared"/>
</memoryBacking>
```

Host side needs `virtiofsd`; guest side needs WinFsp plus the virtio-win
virtiofs driver and service, both installed by `provision.ps1`. To share a
different directory, edit `<source dir="..."/>` in `Win11.xml` and `SHARE_DIR`
in `apply.sh`.

The sandbox mode must be `namespace`. Session-daemon domains run virtiofsd as
your own user, and `chroot` mode needs root — it fails with `sandbox mode
'chroot' can only be used by root`, which surfaces in the domain log only as
QEMU failing to connect to `fs0-fs.sock`. The real message is in
`~/.cache/libvirt/qemu/log/win11-fs0-virtiofsd.log`. Two warnings in that log
are normal when unprivileged: the open-file-descriptor limit getting clamped,
and `Failed to open file handle for the root node` (needs `CAP_DAC_READ_SEARCH`;
virtiofsd falls back to path lookups).

The device deliberately has no `<address>` — libvirt assigns a free PCIe slot on
define. `virsh -c qemu:///session dumpxml win11` shows what it picked.

### First run

Windows is already installed on this disk, so `autounattend.xml` no longer
applies — Windows Setup only reads it during installation. Libvirt XML cannot
execute anything inside a guest either. So provisioning is delivered as a
CD-ROM (`win11-provision.iso`, built from `provision/`) and bootstrapped once by
hand.

`provision.ps1` then copies itself to `C:\ProgramData\Win11Provision\` and
registers a `Win11-Provision` scheduled task that runs at every boot as SYSTEM.
Every step is check-then-install, so from that point on the VM repairs itself:
a fresh clone, a reverted snapshot or a wiped Go install all get fixed on the
next boot without you touching it.

Go is installed from the official `.msi` resolved through `https://go.dev/dl/?mode=json`,
not winget — winget is a per-user app and does not exist in the SYSTEM context
the scheduled task runs under. The same applies to WinFsp and virtio-win.

Logs land in `C:\ProgramData\Win11Provision\provision.log`.

## Connecting

RDP:

```bash
xfreerdp3 /v:127.0.0.1:3389 /u:<user> /dynamic-resolution +clipboard
```

WinRM over HTTPS, ignoring the self-signed certificate:

```python
import winrm

session = winrm.Session(
    "https://127.0.0.1:5986/wsman",
    auth=("<user>", "<password>"),
    transport="basic",
    server_cert_validation="ignore",
)
print(session.run_ps("go version").std_out.decode())
```

Port 5985 rejects unencrypted traffic by default. Re-run the bootstrap with
`-AllowUnencryptedHttp` if you want plain HTTP — credentials then cross in the
clear, which is only defensible because the port is bound to loopback.

## Caveats

- **Boxes may rewrite the domain.** GNOME Boxes regenerates parts of the XML
  when you change VM properties through its UI. If port forwarding or the share
  disappears, re-run `apply.sh`. `virsh` and `virt-manager` leave it alone.
- The `<os-state>` metadata was `installation` and is now `installed`. Left as
  it was, Boxes would keep trying to resume the express-install flow and could
  re-attach the Windows ISO over the provisioning CD.
- The install ISO is no longer attached; the CD-ROM now carries the
  provisioning media with `startupPolicy="optional"`, so a missing ISO will not
  block boot.
- Secure Boot is on. The virtio-win stable build is WHQL-signed, so its driver
  loads fine, but an unsigned test build would not.
- The virtiofs driver only starts working after one reboot following
  provisioning — that is when `Z:\` shows up.
- passt binds 3389/5985/5986 on the host as soon as the VM starts, whether or
  not anything is listening inside the guest. Before provisioning runs, clients
  connect and are then reset rather than getting "connection refused", so a
  bound port is not evidence that the guest service is up.

## Files

| File | Runs on | Purpose |
|---|---|---|
| `Win11.xml` | host | Domain definition |
| `apply.sh` | host | Prerequisites, ISO build, `virsh define` |
| `make-provision-iso.sh` | host | Builds `win11-provision.iso` from `provision/` |
| `provision/Bootstrap.cmd` | guest | Elevates, then runs `provision.ps1` |
| `provision/provision.ps1` | guest | RDP, WinRM, virtiofs, Go, startup task |
