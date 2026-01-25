-- Indent blankline plugin support for Aether colorscheme
local Util = require("aether.utils")

local M = {}

---@type aether.HighlightsFn
function M.get(c, opts)
  -- stylua: ignore
  return {
    IblIndent = { fg = c.fg_gutter, nocombine = true },
    IblScope  = { fg = c.blue1, nocombine = true },
  }
end

return M
