-- Aether colorscheme for Neovim
-- Maintainer: Bjarne Øverli
-- License: MIT

local config = require("aether.config")

local M = {}

---@param opts? aether.Config
function M.load(opts)
  opts = require("aether.config").extend(opts)
  return require("aether.theme").setup(opts)
end

M.setup = config.setup

return M
