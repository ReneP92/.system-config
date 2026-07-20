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

    -- The archived master branch registers its custom query directives
    -- with { all = false }, which Neovim 0.12 removed: handlers now
    -- always receive a list of nodes per capture, so injection queries
    -- using these directives (markdown, bash, hcl/terraform, html) crash
    -- with "attempt to call method 'range'". Re-register list-aware
    -- versions until this config migrates to the rewritten main branch.
    require("nvim-treesitter")

    local function single_node(match, capture_id)
      local nodes = match[capture_id]
      if type(nodes) == "table" then
        return nodes[#nodes]
      end
      return nodes
    end

    local info_string_aliases = {
      ex = "elixir",
      pl = "perl",
      sh = "bash",
      uxn = "uxntal",
      ts = "typescript",
    }
    vim.treesitter.query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
      local node = single_node(match, pred[2])
      if not node then
        return
      end
      local alias = vim.treesitter.get_node_text(node, bufnr):lower()
      metadata["injection.language"] = vim.filetype.match({ filename = "a." .. alias })
        or info_string_aliases[alias]
        or alias
    end, { force = true, all = true })

    local mimetype_languages = {
      importmap = "json",
      module = "javascript",
      ["application/ecmascript"] = "javascript",
      ["text/ecmascript"] = "javascript",
    }
    vim.treesitter.query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
      local node = single_node(match, pred[2])
      if not node then
        return
      end
      local mimetype = vim.treesitter.get_node_text(node, bufnr)
      local parts = vim.split(mimetype, "/", {})
      metadata["injection.language"] = mimetype_languages[mimetype] or parts[#parts]
    end, { force = true, all = true })

    vim.treesitter.query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
      local id = pred[2]
      local node = single_node(match, id)
      if not node then
        return
      end
      local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
      metadata[id] = metadata[id] or {}
      metadata[id].text = text:lower()
    end, { force = true, all = true })
  end,
}
