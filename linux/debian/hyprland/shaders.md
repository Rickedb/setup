# Hyprland Shaders

The shaders directory contains symbolic links to shader files from the `aether` package.

## About Aether

Aether is a collection of GLSL shaders for Hyprland that provide various visual effects. The shaders are typically installed at `/usr/share/aether/shaders/` when you install the `aether` package.

## Installation on Debian

Since `aether` is an AUR package, it's not directly available on Debian. You have a few options:

### Option 1: Build from Source (Recommended)

```bash
git clone https://github.com/aether-app/aether
cd aether
# Follow build instructions in the repository
```

### Option 2: Manual Shader Installation

You can manually download and place shader files in your shaders directory:

```bash
mkdir -p ~/.config/hypr/shaders
# Download specific shaders you want to use
```

### Option 3: Create Your Own Shaders

Create custom GLSL shaders and place them in `~/.config/hypr/shaders/`

## Available Shader Effects (from Aether)

The original Arch setup includes these shader categories:

- **Retro Effects**: CRT, VHS, Gameboy, Matrix Rain, etc.
- **Color Filters**: Monochrome variations, sepia, grayscale, etc.
- **Cyberpunk**: Neon effects, glitch, hologram, etc.
- **Accessibility**: Color blind modes, high contrast, etc.
- **Creative**: Film grain, oil paint, comic book, etc.
- **Atmospheric**: Underwater, thermal, night vision, etc.

## Usage

To apply a shader in Hyprland:

```bash
hyprctl keyword decoration:screen_shader ~/.config/hypr/shaders/shader-name.glsl
```

Or add to your `hyprland.conf`:

```
decoration {
    screen_shader = ~/.config/hypr/shaders/shader-name.glsl
}
```

To disable:

```bash
hyprctl keyword decoration:screen_shader "[[EMPTY]]"
```

## Shader File Structure

GLSL shaders for Hyprland typically follow this structure:

```glsl
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);
    
    // Your shader effect here
    
    gl_FragColor = pixColor;
}
```

## Creating Symbolic Links

If you install Aether or download shaders elsewhere, create links:

```bash
cd ~/.config/hypr/shaders
ln -s /path/to/aether/shaders/*.glsl .
```

## Popular Shaders

Some commonly used shaders from the collection:

- `blue-light-reduce.glsl` - Reduces blue light for night use
- `grayscale.glsl` - Black and white display
- `reading-mode.glsl` - Optimized for reading text
- `crt-green-scanlines.glsl` - Classic terminal look
- `cyberpunk-neon.glsl` - Neon glow effect
- `matrix-rain.glsl` - Matrix-style falling characters

## Notes

- Shaders can impact performance, especially on lower-end GPUs
- Some effects are subtle, others are dramatic
- You can chain multiple effects by modifying shader code
- Test shaders before adding them to your permanent config

## Resources

- Hyprland Shader Documentation: https://wiki.hyprland.org/Configuring/Shaders/
- GLSL Reference: https://www.khronos.org/opengl/wiki/OpenGL_Shading_Language
