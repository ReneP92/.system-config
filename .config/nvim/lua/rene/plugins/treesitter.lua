return {
  "nvim-treesitter/nvim-treesitter",
  -- The upstream repo is now an incompatible rewrite on the default branch.
  -- Pin to the backward-compatible branch so `require("nvim-treesitter.configs")` works.
  branch = "master",
  -- Load Treesitter early so its FileType autocmds are registered
  -- before you create or open new buffers (fixes missing highlight
  -- on newly created files like Terraform).
  lazy = false,
  cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
  build = ":TSUpdate",
  opts = {
    highlight = {
      enable = true,
    },
    indent = { enable = true },
    ensure_installed = {
      "json",
      "javascript",
      "typescript",
      "tsx",
      "python",
      "terraform",
      "yaml",
      "html",
      "css",
      "prisma",
      "markdown",
      "markdown_inline",
      "svelte",
      "graphql",
      "bash",
      "lua",
      "vim",
      "dockerfile",
      "gitignore",
      "query",
      "vimdoc",
      "c",
      "go",
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
    vim.treesitter.language.register("bash", "zsh")
    -- Some setups (or plugins) set *.tf buffers to the custom
    -- filetype \"tf\" instead of \"terraform\". Treesitter's parser
    -- is named \"terraform\", so map the tf filetype to it so that
    -- new Terraform files get proper highlighting immediately.
    vim.treesitter.language.register("terraform", "tf")
  end,
}
