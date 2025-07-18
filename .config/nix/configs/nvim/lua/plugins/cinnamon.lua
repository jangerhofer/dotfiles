return {
  "declancm/cinnamon.nvim",
  version = "*",
  config = function()
    require("cinnamon").setup({
      keymaps = {
        basic = true,
        extra = true,
      },
      options = {
        mode = "cursor",
        delay = 5,
      },
    })
  end,
}