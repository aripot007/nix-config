return {
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "mason-org/mason.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      for _, server_opts in pairs(opts.servers) do
        server_opts.mason = false
      end
    end,
  },
}
