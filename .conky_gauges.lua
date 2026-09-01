require 'cairo'
require 'cairo_xlib'

local cpu_val = 0
local ram_val = 0

function conky_update_values()
    cpu_val = tonumber(conky_parse('${cpu}')) or 0
    ram_val = tonumber(conky_parse('${memperc}')) or 0
end

function draw_gauge(cr, x, y, radius, value, label, color_r, color_g, color_b)
    cairo_new_path(cr)
    local start_angle = 0.75 * math.pi
    local end_angle = 2.25 * math.pi
    local range = end_angle - start_angle
    local value_angle = start_angle + (value / 100) * range

    -- Background arc
    cairo_set_source_rgba(cr, 1, 1, 1, 0.15)
    cairo_set_line_width(cr, radius * 0.12)
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
    cairo_arc(cr, x, y, radius, start_angle, end_angle)
    cairo_stroke(cr)

    -- Value arc
    local alpha = 0.6 + 0.4 * (value / 100)
    cairo_set_source_rgba(cr, color_r, color_g, color_b, alpha)
    cairo_set_line_width(cr, radius * 0.14)
    cairo_arc(cr, x, y, radius, start_angle, value_angle)
    cairo_stroke(cr)

    -- Glow effect on the tip
    local tip_x = x + radius * math.cos(value_angle)
    local tip_y = y + radius * math.sin(value_angle)
    local grad = cairo_pattern_create_radial(tip_x, tip_y, 0, tip_x, tip_y, radius * 0.25)
    cairo_pattern_add_color_stop_rgba(grad, 0, color_r, color_g, color_b, 0.7)
    cairo_pattern_add_color_stop_rgba(grad, 1, color_r, color_g, color_b, 0)
    cairo_set_source(cr, grad)
    cairo_arc(cr, tip_x, tip_y, radius * 0.25, 0, 2 * math.pi)
    cairo_fill(cr)
    cairo_pattern_destroy(grad)

    -- Percentage text
    cairo_select_font_face(cr, "Inter", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    cairo_set_font_size(cr, radius * 0.42)
    cairo_set_source_rgba(cr, 1, 1, 1, 0.95)
    local pct_text = string.format("%.0f%%", value)
    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, pct_text, extents)
    cairo_move_to(cr, x - extents.width / 2, y + extents.height / 3)
    cairo_show_text(cr, pct_text)
    extents:destroy()

    -- Label text
    cairo_set_font_size(cr, radius * 0.2)
    cairo_set_source_rgba(cr, 1, 1, 1, 0.6)
    local lbl_extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, label, lbl_extents)
    cairo_move_to(cr, x - lbl_extents.width / 2, y + radius * 0.6)
    cairo_show_text(cr, label)
    lbl_extents:destroy()
end

function draw_time(cr, w, gauge_bottom)
    local t = conky_parse('${time %H:%M}')
    local ext = cairo_text_extents_t:create()

    cairo_select_font_face(cr, "Inter", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 280)
    cairo_set_source_rgba(cr, 1, 1, 1, 0.75)

    cairo_text_extents(cr, t, ext)
    local text_top = gauge_bottom + 40
    local baseline = text_top - ext.y_bearing
    local x = w / 2 - ext.width / 2 - ext.x_bearing
    cairo_move_to(cr, x, baseline)
    cairo_show_text(cr, t)

    ext:destroy()
end

function conky_draw_gauges()
    if conky_window == nil then return end
    if conky_window.width < 10 or conky_window.height < 10 then return end

    conky_update_values()

    local cs = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )
    local cr = cairo_create(cs)

    local w = conky_window.width
    local gauge_radius = math.min(w, 240) * 0.32
    local gauge_y = 20 + gauge_radius

    draw_gauge(cr, w * 0.28, gauge_y, gauge_radius, cpu_val, "CPU", 0.2, 0.85, 1.0)
    draw_gauge(cr, w * 0.72, gauge_y, gauge_radius, ram_val, "RAM", 1.0, 0.45, 0.35)

    draw_time(cr, w, gauge_y + gauge_radius)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
