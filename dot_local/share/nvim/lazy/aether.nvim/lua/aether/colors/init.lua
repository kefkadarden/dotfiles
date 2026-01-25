local Util = require("aether.utils")

local M = {}

---@class Palette
local default_palette = {
  bg = "#000000",
  bg_dark = "#000000",
  bg_dark1 = "#000000",
  bg_highlight = "#1a1a1a",
  
  -- Aether accent colors
  blue = "#66d9ef",
  blue0 = "#264f78",
  blue1 = "#66d9ef",
  blue2 = "#66d9ef",
  blue5 = "#89ddff",
  blue6 = "#b4f9f8",
  blue7 = "#1e3a5f",
  
  comment = "#585858",
  cyan = "#66d9ef",
  
  dark3 = "#585858",
  dark5 = "#b8b8b8",
  
  fg = "#d8d8d8",
  fg_dark = "#b8b8b8",
  fg_gutter = "#585858",  -- Same as base03/comment for visibility
  
  green = "#a6e22e",
  green1 = "#a6e22e",
  green2 = "#73aa6a",
  
  magenta = "#ae81ff",
  magenta2 = "#f92672",
  
  orange = "#fd971f",
  purple = "#ae81ff",
  
  red = "#f92672",
  red1 = "#c91f4f",
  
  teal = "#66d9ef",
  terminal_black = "#282828",
  
  yellow = "#f4bf75",
  
  -- Git colors will be calculated from the palette colors above
  git = {},
  
  -- Base16 compatibility (deprecated, kept for backward compatibility)
  base00 = "#000000",
  base01 = "#282828",
  base02 = "#383838",
  base03 = "#585858",
  base04 = "#b8b8b8",
  base05 = "#d8d8d8",
  base06 = "#e8e8e8",
  base07 = "#f8f8f8",
  base08 = "#f92672",
  base09 = "#fd971f",
  base0A = "#f4bf75",
  base0B = "#a6e22e",
  base0C = "#66d9ef",
  base0D = "#66d9ef",
  base0E = "#ae81ff",
  base0F = "#cc6633",
}

---@param opts? aether.Config
function M.setup(opts)
  opts = require("aether.config").extend(opts)

  -- Color Palette
  ---@class ColorScheme: Palette
  local colors = vim.deepcopy(default_palette)

  -- IMPORTANT: Support legacy base16 color injection
  -- Allow users to override colors via opts.colors table (base16 style)
  if opts.colors and next(opts.colors) then
    colors = vim.tbl_deep_extend("force", colors, opts.colors)
    
    -- Map base16 colors to semantic names AND all variants if base16 colors were provided
    if opts.colors.base00 then 
      colors.bg = opts.colors.base00
      colors.bg_dark = opts.colors.base00
      colors.bg_dark1 = opts.colors.base00
    end
    if opts.colors.base01 then 
      colors.terminal_black = opts.colors.base01
    end
    if opts.colors.base02 then
      colors.bg_highlight = opts.colors.base02
    end
    if opts.colors.base03 then 
      colors.comment = opts.colors.base03
      colors.dark3 = opts.colors.base03
      colors.fg_gutter = opts.colors.base03  -- Line numbers should be visible like comments
    end
    if opts.colors.base04 then
      colors.dark5 = opts.colors.base04
      colors.fg_dark = opts.colors.base04
    end
    if opts.colors.base05 then 
      colors.fg = opts.colors.base05
    end
    if opts.colors.base08 then 
      colors.red = opts.colors.base08
      colors.red1 = opts.colors.base08
      colors.magenta2 = opts.colors.base08
    end
    if opts.colors.base09 then 
      colors.orange = opts.colors.base09
    end
    if opts.colors.base0A then 
      colors.yellow = opts.colors.base0A
    end
    if opts.colors.base0B then 
      colors.green = opts.colors.base0B
      colors.green1 = opts.colors.base0B
      colors.green2 = opts.colors.base0B
    end
    if opts.colors.base0C then 
      colors.cyan = opts.colors.base0C
      colors.teal = opts.colors.base0C
      colors.blue5 = opts.colors.base0C
      colors.blue6 = opts.colors.base0C
    end
    if opts.colors.base0D then 
      colors.blue = opts.colors.base0D
      colors.blue1 = opts.colors.base0D
      colors.blue2 = opts.colors.base0D
    end
    if opts.colors.base0E then 
      colors.purple = opts.colors.base0E
      colors.magenta = opts.colors.base0E
    end
    if opts.colors.base0F then
      -- Brown/deprecated color - no direct mapping needed
    end
  end

  Util.bg = colors.bg or colors.base00
  Util.fg = colors.fg or colors.base05

  colors.none = "NONE"

  -- Always update git colors to use the palette colors (either default or injected)
  -- This ensures git colors are derived from the theme colors
  colors.git.add = colors.green2 or colors.green
  colors.git.delete = colors.red1 or colors.red
  colors.git.change = colors.orange or colors.yellow

  -- Diff colors using tokyonight approach
  colors.diff = {
    add = Util.blend_bg(colors.green2 or colors.green, 0.25),
    delete = Util.blend_bg(colors.red1 or colors.red, 0.25),
    change = Util.blend_bg(colors.blue7 or colors.blue, 0.15),
    text = colors.blue7 or colors.blue,
  }

  colors.git.ignore = colors.dark3
  colors.black = Util.blend_bg(colors.bg, 0.8, colors.bg)
  colors.border_highlight = Util.blend_bg(colors.blue1, 0.8)
  colors.border = colors.black

  -- Popups and statusline always get a dark background
  colors.bg_popup = colors.bg_dark
  colors.bg_statusline = colors.bg_dark

  -- Sidebar and Floats are configurable
  colors.bg_sidebar = opts.styles.sidebars == "transparent" and colors.none
    or opts.styles.sidebars == "dark" and colors.bg_dark
    or colors.bg

  colors.bg_float = opts.styles.floats == "transparent" and colors.none
    or opts.styles.floats == "dark" and colors.bg_dark
    or colors.bg

  colors.bg_visual = Util.blend_bg(colors.blue0, 0.4)
  colors.bg_search = colors.blue0
  colors.fg_sidebar = colors.fg_dark
  colors.fg_float = colors.fg

  colors.error = colors.red1
  colors.todo = colors.blue
  colors.warning = colors.yellow
  colors.info = colors.blue2
  colors.hint = colors.teal

  -- Create blended colors for subtle highlights
  colors.subtle_bg = Util.blend_bg(colors.fg, 0.10)
  colors.cursorline_bg = Util.blend_bg(colors.fg, 0.20)
  colors.selection_bg = Util.blend_bg(colors.fg, 0.25)
  colors.float_bg = Util.blend_bg(colors.fg, 0.12)

  colors.rainbow = {
    colors.blue,
    colors.yellow,
    colors.green,
    colors.teal,
    colors.magenta,
    colors.purple,
    colors.orange,
    colors.red,
  }

  -- Terminal colors
  colors.terminal = {
    black = colors.black,
    black_bright = colors.terminal_black,
    red = colors.red,
    red_bright = colors.red,
    green = colors.green,
    green_bright = colors.green,
    yellow = colors.yellow,
    yellow_bright = colors.yellow,
    blue = colors.blue,
    blue_bright = colors.blue,
    magenta = colors.magenta,
    magenta_bright = colors.magenta,
    cyan = colors.cyan,
    cyan_bright = colors.cyan,
    white = colors.fg_dark,
    white_bright = colors.fg,
  }

  -- Call user's on_colors callback for further customization
  opts.on_colors(colors)

  return colors, opts
end

return M
