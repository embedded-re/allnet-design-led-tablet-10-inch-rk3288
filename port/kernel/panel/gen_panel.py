#!/usr/bin/env python3
"""Generate a panel entry for drivers/gpu/drm/panel/panel-jadard-jd9365da-h3.c from the
vendor (Rockchip) panel-init-sequence of this tablet, and patch it into the driver.

Vendor format: [type delay_ms len data...]; type 0x15 = DCS short write with 1 param,
0x05 = DCS short write without params. Delay applies after the command.

usage: gen_panel.py panel_init_sequence.hex path/to/panel-jadard-jd9365da-h3.c
"""
import sys

NAME = "smarttab_rk3288"
COMPAT = "smarttab,jd9365da-800x1280"

seq = [int(x, 16) for x in open(sys.argv[1]).read().split()]
cmds, i = [], 0
while i < len(seq):
    t, delay, n = seq[i:i + 3]
    cmds.append((t, delay, seq[i + 3:i + 3 + n]))
    i += 3 + n

# The driver's jadard_enable_standard_cmds() emits exactly E1 93, E2 65, E3 F8, 80 03 (4 lanes).
std = [[0xE0, 0x00], [0xE1, 0x93], [0xE2, 0x65], [0xE3, 0xF8], [0x80, 0x03]]
assert [c[2] for c in cmds[:5]] == std, "unexpected preamble"
assert cmds[-2][2] == [0x11] and cmds[-1][2] == [0x29], "unexpected tail"

body = ["\tjd9365da_switch_page(&dsi_ctx, 0x00);", "\tjadard_enable_standard_cmds(&dsi_ctx);"]
for t, delay, p in cmds[5:-2]:
    assert t == 0x15 and len(p) == 2, (t, p)
    if p[0] == 0xE0:
        body += ["", f"\tjd9365da_switch_page(&dsi_ctx, 0x{p[1]:02x});"]
    else:
        body.append(f"\tmipi_dsi_dcs_write_seq_multi(&dsi_ctx, 0x{p[0]:02x}, 0x{p[1]:02x});")
    if delay:
        body.append(f"\tmipi_dsi_msleep(&dsi_ctx, {delay});")
body += [
    "",
    "\tmipi_dsi_dcs_exit_sleep_mode_multi(&dsi_ctx);",
    f"\tmipi_dsi_msleep(&dsi_ctx, {cmds[-2][1]});",
    "",
    "\tmipi_dsi_dcs_set_display_on_multi(&dsi_ctx);",
    f"\tmipi_dsi_msleep(&dsi_ctx, {cmds[-1][1]});",
]

code = f"""
/*
 * RK3288 "SmartTab" tablet, 800x1280 JD9365DA panel. Init sequence and timing taken
 * verbatim from the vendor Android device tree (rockchip panel-init-sequence).
 */
static int {NAME}_init_cmds(struct jadard *jadard)
{{
\tstruct mipi_dsi_multi_context dsi_ctx = {{ .dsi = jadard->dsi }};

{chr(10).join(body)}

\treturn dsi_ctx.accum_err;
}};

static const struct jadard_panel_desc {NAME}_desc = {{
\t.mode_4ln = &(const struct drm_display_mode) {{
\t\t.clock\t\t= 68000,

\t\t.hdisplay\t= 800,
\t\t.hsync_start\t= 800 + 20,
\t\t.hsync_end\t= 800 + 20 + 20,
\t\t.htotal\t\t= 800 + 20 + 20 + 20,

\t\t.vdisplay\t= 1280,
\t\t.vsync_start\t= 1280 + 30,
\t\t.vsync_end\t= 1280 + 30 + 4,
\t\t.vtotal\t\t= 1280 + 30 + 4 + 8,

\t\t.width_mm\t= 135,
\t\t.height_mm\t= 216,
\t\t.type\t\t= DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED,
\t}},
\t.lanes = 4,
\t.format = MIPI_DSI_FMT_RGB888,
\t.init = {NAME}_init_cmds,
\t.mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_BURST |
\t\t      MIPI_DSI_MODE_LPM,
}};
"""

drv_path = sys.argv[2]
drv = open(drv_path).read()
if COMPAT in drv:
    sys.exit("already patched")
anchor = "static const struct of_device_id jadard_of_match[] = {\n"
assert drv.count(anchor) == 1
drv = drv.replace(anchor, code.lstrip("\n") + "\n" + anchor + f"\t{{\n\t\t.compatible = \"{COMPAT}\",\n\t\t.data = &{NAME}_desc\n\t}},\n")
open(drv_path, "w").write(drv)
print(f"patched {drv_path}: {len(cmds) - 7} register writes + std preamble + sleep-out/display-on")
