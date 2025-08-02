{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    # Add Nix development tools
    extraPackages = with pkgs; [
      # Nix tooling
      nixd                 # Nix language server
      nixfmt-rfc-style     # Nix formatter
      statix               # Nix linter
      deadnix              # Dead code elimination
      
      # General development tools
      tree-sitter          # Syntax highlighting
      ripgrep              # Search
      fd                   # File finding
      lazygit              # Git UI
    ];
  };
  
  # LazyVim configuration files
  home.file = {
    # Main init.lua
    ".config/nvim/init.lua".text = ''
      -- bootstrap lazy.nvim, LazyVim and your plugins
      require("config.lazy")
    '';
    
    # LazyVim configuration
    ".config/nvim/lua/config/lazy.lua".text = ''
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local lazyrepo = "https://github.com/folke/lazy.nvim.git"
        local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
        if vim.v.shell_error ~= 0 then
          vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
          }, true, {})
          vim.fn.getchar()
          os.exit(1)
        end
      end
      vim.opt.rtp:prepend(lazypath)

      require("lazy").setup({
        spec = {
          -- add LazyVim and import its plugins
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },
          -- import/override with your plugins
          { import = "plugins" },
        },
        defaults = {
          lazy = false,
          version = false,
        },
        install = { colorscheme = { "tokyonight", "habamax" } },
        checker = {
          enabled = true,
          notify = false,
        },
        performance = {
          rtp = {
            disabled_plugins = {
              "gzip",
              "tarPlugin",
              "tohtml",
              "tutor",
              "zipPlugin",
            },
          },
        },
      })
    '';
    
    # LazyVim config files (minimal - use defaults)
    ".config/nvim/lua/config/options.lua".text = ''
      -- Options are automatically loaded before lazy.nvim startup
      -- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
      -- Add any additional options here
    '';
    
    ".config/nvim/lua/config/autocmds.lua".text = ''
      -- Autocmds are automatically loaded on the VeryLazy event
      -- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
      -- Add any additional autocmds here
    '';
    
    ".config/nvim/lua/config/keymaps.lua".text = ''
      -- Keymaps are automatically loaded on the VeryLazy event
      -- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
      -- Add any additional keymaps here
    '';
    
    # Nord colorscheme plugin
    ".config/nvim/lua/plugins/colorscheme.lua".text = ''
      return {
        {
          "shaunsingh/nord.nvim",
          lazy = false,
          priority = 1000,
          config = function()
            -- Optional Nord configuration
            vim.g.nord_contrast = true
            vim.g.nord_borders = false
            vim.g.nord_disable_background = false
            vim.g.nord_italic = false
            vim.g.nord_uniform_diff_background = true
            vim.g.nord_bold = false
            
            require('nord').set()
          end,
        },
        
        -- Set Nord as default colorscheme
        {
          "LazyVim/LazyVim",
          opts = {
            colorscheme = "nord",
          },
        },
      }
    '';
    
    # Neo-tree explorer customization
    ".config/nvim/lua/plugins/neo-tree.lua".text = ''
      return {
        "nvim-neo-tree/neo-tree.nvim",
        config = function()
          -- Force all filename text to be white
          vim.api.nvim_set_hl(0, "NeoTreeFileName", { fg = "#FFFFFF" })
          vim.api.nvim_set_hl(0, "NeoTreeFileNameOpened", { fg = "#FFFFFF", bold = true })
          vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = "#FFFFFF", bold = true })
        end,
      }
    '';
    
    # Snacks.nvim picker customization for better visibility
    ".config/nvim/lua/plugins/snacks.lua".text = ''
      return {
        "folke/snacks.nvim",
        opts = {
          picker = {
            win = {
              -- Force white text in snacks picker windows
              wo = {
                winhl = "Normal:Normal,NormalFloat:Normal,FloatBorder:FloatBorder",
              },
            },
          },
        },
        config = function(_, opts)
          require("snacks").setup(opts)
          -- Force snacks picker text to be white
          vim.api.nvim_set_hl(0, "SnacksPickerNormal", { fg = "#FFFFFF" })
          vim.api.nvim_set_hl(0, "SnacksPickerFile", { fg = "#FFFFFF" })
          vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = "#FFFFFF", bold = true })
          vim.api.nvim_set_hl(0, "SnacksPickerMatch", { fg = "#88C0D0", bold = true })
          
          -- Also try these common picker highlights
          vim.api.nvim_set_hl(0, "PickerNormal", { fg = "#FFFFFF" })
          vim.api.nvim_set_hl(0, "PickerPrompt", { fg = "#FFFFFF" })
          vim.api.nvim_set_hl(0, "PickerSelection", { fg = "#FFFFFF", bg = "#434C5E" })
        end,
      }
    '';
    
    # Nix development plugin
    ".config/nvim/lua/plugins/nix.lua".text = ''
      return {
        -- Nix language support
        {
          "LnL7/vim-nix",
          ft = "nix",
          config = function()
            vim.g.nix_recommended_style = 1
          end,
        },

        -- Enhanced Nix support with LSP
        {
          "neovim/nvim-lspconfig",
          opts = {
            servers = {
              nixd = {
                cmd = { "nixd" },
                settings = {
                  nixd = {
                    nixpkgs = {
                      expr = "import <nixpkgs> { }",
                    },
                    formatting = {
                      command = { "nixfmt" },
                    },
                    options = {
                      nixos = {
                        expr = '(builtins.getFlake "/etc/nixos").nixosConfigurations.HOSTNAME.options',
                      },
                      home_manager = {
                        expr = '(builtins.getFlake "/etc/nixos").homeConfigurations.HOSTNAME.options',
                      },
                    },
                  },
                },
              },
            },
          },
        },

        -- Treesitter support for Nix
        {
          "nvim-treesitter/nvim-treesitter",
          opts = {
            ensure_installed = {
              "nix",
            },
          },
        },

        -- Mason support for Nix tools
        {
          "williamboman/mason.nvim",
          opts = {
            ensure_installed = {
              "nixd",
              "nixfmt",
              "statix",
              "deadnix",
            },
          },
        },

        -- Conform formatter for Nix
        {
          "stevearc/conform.nvim",
          opts = {
            formatters_by_ft = {
              nix = { "nixfmt" },
            },
          },
        },

        -- Lint support for Nix
        {
          "mfussenegger/nvim-lint",
          opts = {
            linters_by_ft = {
              nix = { "statix", "deadnix" },
            },
          },
        },

        -- Which-key mappings for Nix
        {
          "folke/which-key.nvim",
          opts = {
            spec = {
              { "<leader>n", group = "nix" },
              { "<leader>nf", "<cmd>!nixfmt %<cr>", desc = "Format Nix file" },
              { "<leader>nc", "<cmd>!nix flake check<cr>", desc = "Check flake" },
              { "<leader>nb", "<cmd>!nix build<cr>", desc = "Build flake" },
              { "<leader>nd", "<cmd>!nix develop<cr>", desc = "Enter dev shell" },
              { "<leader>nu", "<cmd>!nix flake update<cr>", desc = "Update flake" },
            },
          },
        },
      }
    '';
  };
}