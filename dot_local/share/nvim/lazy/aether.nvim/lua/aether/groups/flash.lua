-- Flash plugin support for Aether colorscheme
local Util = require("aether.utils")

local M = {}

---@type aether.HighlightsFn
function M.get(c, opts)
  -- stylua: ignore
  return {
    FlashBackdrop = { fg = c.comment },
    FlashCurrent  = { fg = c.black, bg = c.orange, bold = true },
    FlashLabel    = { fg = c.black, bg = c.magenta, bold = true },
    FlashMatch    = { fg = c.cyan, bg = c.bg_highlight, bold = true },
    FlashPrompt   = { link = "NormalFloat" },
  }
end

return M
