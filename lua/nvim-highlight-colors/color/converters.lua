local patterns = require("nvim-highlight-colors.color.patterns")

local M = {}

---Converts a rgb color to hex
---@param r number
---@param g number
---@param b number
---@usage rgb_to_hex(255, 255, 255) => Returns '#FFFFFF'
---@return string
function M.rgb_to_hex(r, g, b)
	return string.format("#%02X%02X%02X", r, g, b)
end

---Converts a hex color to rgb
---@param hex string
---@usage hex_to_rgb("#FFFFFF") => Returns {255, 255, 255}
---@return {r: number, g: number, b: number}|nil
function M.hex_to_rgb(hex)
	if patterns.is_short_hex_color(hex) then
		hex = M.short_hex_to_hex(hex)
	end

	hex = hex:gsub("#", "")

	local r = tonumber("0x" .. hex:sub(1, 2))
	local g = tonumber("0x" .. hex:sub(3, 4))
	local b = tonumber("0x" .. hex:sub(5, 6))

	return r ~= nil and g ~= nil and b ~= nil and { r, g, b } or nil
end

---Converts a short hex color to hex
---@param color string
---@usage short_hex_to_hex("#FFF") => Returns "#FFFFFF"
---@return string
function M.short_hex_to_hex(color)
	local new_color = "#"
	for char in color:gmatch(".") do
		if char ~= "#" then
			new_color = new_color .. char:rep(2)
		end
	end

	return new_color
end

local a

---Converts a hsl color to rgb
---@param h number
---@param s number
---@param l number
---@usage hsl_to_rgb(240, 100, 68) => Returns {91, 91, 255, 255}
---@return {r: number, g: number, b: number, a: number}
-- Function retrieved from this stackoverflow post:
-- https://stackoverflow.com/questions/68317097/how-to-properly-convert-hsl-colors-to-rgb-colors-in-lua
function M.hsl_to_rgb(h, s, l)
	h = h / 360
	s = s / 100
	l = l / 100

	local r, g, b

	if s == 0 then
		r, g, b = l, l, l -- achromatic
	else
		local function hue2rgb(p, q, t)
			if t < 0 then
				t = t + 1
			end
			if t > 1 then
				t = t - 1
			end
			if t < 1 / 6 then
				return p + (q - p) * 6 * t
			end
			if t < 1 / 2 then
				return q
			end
			if t < 2 / 3 then
				return p + (q - p) * (2 / 3 - t) * 6
			end
			return p
		end

		local q = l < 0.5 and l * (1 + s) or l + s - l * s
		local p = 2 * l - q
		r = hue2rgb(p, q, h + 1 / 3)
		g = hue2rgb(p, q, h)
		b = hue2rgb(p, q, h - 1 / 3)
	end

	if not a then
		a = 1
	end
	return {
		math.floor(r * 255),
		math.floor(g * 255),
		math.floor(b * 255),
		math.floor(a * 255),
	}
end

---Converts an oklch color to rgb
---@param l number Lightness (0-1)
---@param c number Chroma (0+)
---@param h number Hue in degrees (0-360)
---@return {r: number, g: number, b: number}
function M.oklch_to_rgb(l, c, h)
	local h_rad = h * math.pi / 180
	local a_lab = c * math.cos(h_rad)
	local b_lab = c * math.sin(h_rad)

	-- oklab -> LMS (approximate cube roots)
	local l_ = l + 0.3963377774 * a_lab + 0.2158037573 * b_lab
	local m_ = l - 0.1055613458 * a_lab - 0.0638541728 * b_lab
	local s_ = l - 0.0894841775 * a_lab - 1.2914855480 * b_lab

	local lc = l_ * l_ * l_
	local mc = m_ * m_ * m_
	local sc = s_ * s_ * s_

	-- LMS -> linear sRGB
	local r_lin = 4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc
	local g_lin = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc
	local b_lin = -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc

	-- gamma correction
	local function gamma(x)
		if x <= 0.0031308 then
			return 12.92 * x
		end
		return 1.055 * (x ^ (1 / 2.4)) - 0.055
	end

	local function clamp(x)
		return math.max(0, math.min(255, math.floor(x * 255 + 0.5)))
	end

	return { clamp(gamma(r_lin)), clamp(gamma(g_lin)), clamp(gamma(b_lin)) }
end

return M
