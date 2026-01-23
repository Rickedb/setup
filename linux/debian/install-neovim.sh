#!/bin/bash

# Neovim Setup Script for Debian
# Installs Neovim with modern configuration and dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the actual user (when script is run with sudo)
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

echo_info "Setting up Neovim for user: $REAL_USER"

# ========================================
# Install Dependencies
# ========================================
echo_info "Installing Neovim dependencies..."

# Install essential tools
apt update
apt install -y \
    neovim \
    git \
    curl \
    ripgrep \
    fd-find \
    unzip \
    tar \
    gzip \
    wget

# Install build tools for Tree-sitter
apt install -y \
    build-essential \
    cmake \
    pkg-config

# Install language servers and formatters
apt install -y \
    python3-pip \
    npm

# Install common language servers via npm (as user)
echo_info "Installing language servers..."
sudo -u $REAL_USER npm install -g \
    bash-language-server \
    typescript-language-server \
    vscode-langservers-extracted \
    yaml-language-server \
    dockerfile-language-server-nodejs \
    @tailwindcss/language-server

# Install Python tools
echo_info "Installing Python tools..."
pip3 install --break-system-packages \
    pynvim \
    black \
    flake8 \
    pylint \
    autopep8

# Install .NET C# language server (OmniSharp)
echo_info "Installing .NET C# language server..."
if command -v dotnet &> /dev/null; then
    dotnet tool install --global csharp-ls
    echo_info "C# language server installed. Ensure ~/.dotnet/tools is in PATH."
else
    echo_warn ".NET SDK not found. Skipping C# language server. Install .NET SDK first to enable C# support."
fi

# ========================================
# Backup existing Neovim config
# ========================================
if [ -d "$REAL_HOME/.config/nvim" ]; then
    echo_warn "Existing Neovim config found. Creating backup..."
    sudo -u $REAL_USER mv "$REAL_HOME/.config/nvim" "$REAL_HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

if [ -d "$REAL_HOME/.local/share/nvim" ]; then
    sudo -u $REAL_USER mv "$REAL_HOME/.local/share/nvim" "$REAL_HOME/.local/share/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

if [ -d "$REAL_HOME/.local/state/nvim" ]; then
    sudo -u $REAL_USER mv "$REAL_HOME/.local/state/nvim" "$REAL_HOME/.local/state/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

if [ -d "$REAL_HOME/.cache/nvim" ]; then
    sudo -u $REAL_USER mv "$REAL_HOME/.cache/nvim" "$REAL_HOME/.cache/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

# ========================================
# Choose Configuration Framework
# ========================================
echo_info "Choose Neovim configuration:"
echo "1) LazyVim (Recommended - Modern, feature-rich)"
echo "2) NvChad (Fast, beautiful UI)"
echo "3) AstroNvim (Community-driven)"
echo "4) Minimal custom config"
echo "5) Skip configuration (just install Neovim)"

read -p "Enter choice [1-5] (default: 1): " NVIM_CHOICE
NVIM_CHOICE=${NVIM_CHOICE:-1}

case $NVIM_CHOICE in
    1)
        echo_info "Installing LazyVim..."
        sudo -u $REAL_USER git clone https://github.com/LazyVim/starter "$REAL_HOME/.config/nvim"
        sudo -u $REAL_USER rm -rf "$REAL_HOME/.config/nvim/.git"
        ;;
    2)
        echo_info "Installing NvChad..."
        sudo -u $REAL_USER git clone https://github.com/NvChad/starter "$REAL_HOME/.config/nvim"
        sudo -u $REAL_USER rm -rf "$REAL_HOME/.config/nvim/.git"
        ;;
    3)
        echo_info "Installing AstroNvim..."
        sudo -u $REAL_USER git clone --depth 1 https://github.com/AstroNvim/template "$REAL_HOME/.config/nvim"
        sudo -u $REAL_USER rm -rf "$REAL_HOME/.config/nvim/.git"
        ;;
    4)
        echo_info "Creating minimal custom config..."
        sudo -u $REAL_USER mkdir -p "$REAL_HOME/.config/nvim/lua"
        
        # Create init.lua
        sudo -u $REAL_USER cat > "$REAL_HOME/.config/nvim/init.lua" << 'EOF'
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.wrap = false
vim.opt.breakindent = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.completeopt = 'menuone,noselect'

-- Plugins
require("lazy").setup({
  -- Color scheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
  
  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end,
  },
  
  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup()
    end,
  },
  
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "python", "javascript" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  
  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "tsserver" },
      })
      
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({})
      lspconfig.pyright.setup({})
      lspconfig.tsserver.setup({})
    end,
  },
  
  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },
  
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup()
    end,
  },
  
  -- Git integration
  { "lewis6991/gitsigns.nvim", config = true },
  
  -- Comment plugin
  { "numToStr/Comment.nvim", config = true },
  
  -- Auto pairs
  { "windwp/nvim-autopairs", config = true },
})

-- Keymaps
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle file explorer' })
vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>', { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>', { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', ':Telescope buffers<CR>', { desc = 'Find buffers' })
EOF
        ;;
    5)
        echo_info "Skipping Neovim configuration..."
        ;;
    *)
        echo_error "Invalid choice. Skipping configuration."
        ;;
esac

# ========================================
# Create symlinks for common commands
# ========================================
echo_info "Creating command aliases..."
ln -sf /usr/bin/nvim /usr/local/bin/vi || true
ln -sf /usr/bin/nvim /usr/local/bin/vim || true

# ========================================
# Set Neovim as default editor
# ========================================
echo_info "Setting Neovim as default editor..."
update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 100
update-alternatives --set editor /usr/bin/nvim

# Add to user's shell config
for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
    if [ -f "$shell_config" ]; then
        if ! grep -q "export EDITOR=nvim" "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Set Neovim as default editor" >> "$shell_config"
            echo "export EDITOR=nvim" >> "$shell_config"
            echo "export VISUAL=nvim" >> "$shell_config"
        fi
    fi
done

# ========================================
# Initial setup
# ========================================
if [ "$NVIM_CHOICE" != "5" ]; then
    echo_info "Running initial Neovim setup..."
    echo_info "This will install plugins and may take a few minutes..."
    
    # Run Neovim headless to install plugins
    sudo -u $REAL_USER nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
fi

echo_info ""
echo_info "=========================================="
echo_info "Neovim setup complete!"
echo_info "=========================================="
echo_info ""
echo_info "Installed components:"
echo_info "  - Neovim editor"
echo_info "  - Language servers (Bash, TypeScript, YAML, Docker)"
echo_info "  - Python tools (Black, Flake8, Pylint)"
echo_info "  - Tree-sitter support"
echo_info ""

if [ "$NVIM_CHOICE" != "5" ]; then
    echo_info "Configuration: Installed"
    echo_info "Location: $REAL_HOME/.config/nvim"
    echo_info ""
    echo_info "Next steps:"
    echo_info "  1. Open Neovim: nvim"
    echo_info "  2. Wait for plugins to install (first run)"
    echo_info "  3. Check health: :checkhealth"
    echo_info ""
    
    case $NVIM_CHOICE in
        1) echo_info "Documentation: https://www.lazyvim.org/" ;;
        2) echo_info "Documentation: https://nvchad.com/" ;;
        3) echo_info "Documentation: https://astronvim.com/" ;;
        4) echo_info "Keybindings: <Space> is leader key" ;;
    esac
fi

echo_info ""
echo_info "Useful commands:"
echo_info "  - nvim                 Open Neovim"
echo_info "  - nvim file.txt        Edit file"
echo_info "  - nvim +PluginUpdate   Update plugins"
echo_info "  - nvim +checkhealth    Check installation"
