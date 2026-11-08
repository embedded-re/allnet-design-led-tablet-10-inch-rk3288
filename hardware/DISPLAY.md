# Display — what the stock firmware tells us (2026-11-07)

Source: the `rk-kernel.dtb` inside the Android boot image (`backup_20261106/partitions/07_boot.img`,
`second` RSCE entry). Extracted to `hardware/vendor/android_boot.dtb` / `.dts`.
Stock U-Boot's splash (the "Rockchip UBOOT DRM driver" in the boot log) loads the SAME dtb
("Load FDT from boot image") and its `route-dsi0` logo node, so this DT is the full recipe that both
the splash and the vendor kernel use. No need to reverse-engineer the splash code itself.

## Pipeline
VOP-big `vop@ff930000` → endpoint → MIPI DSI0 `dsi@ff960000` (`rockchip,rk3288-mipi-dsi`,
`snps,dw-mipi-dsi`) → panel. `rockchip,lane-rate = 800` (Mbps/lane; the U-Boot log agrees:
"final DSI-Link bandwidth: 800 Mbps x 4").

## Panel
- Controller: **Jadard JD9365DA** — the init sequence starts `E0 00, E1 93, E2 65, E3 F8` (its
  page-select + password unlock). Mainline driver: `drivers/gpu/drm/panel/panel-jadard-jd9365da-h3.c`.
- 800x1280 portrait, **4 lanes**, `dsi,format = 0` → RGB888, `dsi,flags = 0x3` →
  `MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_BURST`.
- Timing (`timing0`): pixel clock **68 MHz**; H: 800 active, fp 20, sync 20, bp 20 (total 860);
  V: 1280 active, fp 30, sync 4, bp 8 (total 1322). All syncs active-low, DE active-low per DT.
  (U-Boot log: `H: 0800 0820 0840 0860  V: 1280 1310 1314 1322`, clock 68000 kHz.) ≈ 59.8 Hz.
- Delays (ms): reset 20, init 20, prepare 120, enable 120.
- Init sequence: `port/kernel/panel/panel_init_sequence.hex` — Rockchip format `[type delay len data…]`.
  205 commands: type 0x15 = DCS short write + 1 param, 0x05 = DCS short write, no param.
  Writes per page (`E0 xx`): p0 10, p1 73, p2 114, p4 6, p5 2. Ends with
  `E6 02`, `E7 0C`, then `0x11` (sleep out) + 120 ms, `0x29` (display on) + 20 ms.

## GPIOs / power
| Signal | Pin | Polarity | DT |
|---|---|---|---|
| Panel reset | GPIO7_A2 | active LOW | panel `reset-gpios = <&gpio7 2 1>` |
| vcc_lcd enable | GPIO7_A3 | active high | `regulator-fixed` "vcc_lcd", vin = ACT8846 REG2 VCC_IO 3.3 V |
| Backlight enable | GPIO7_B1 | active high | `pwm-backlight` `enable-gpios = <&gpio7 9 0>` |
| Backlight PWM | `pwm@ff680000` (PWM0) | period 10000 ns (100 kHz) | brightness-levels are 255→0, i.e. **inverted** duty |

## Mainline plan
Add a panel entry to `panel-jadard-jd9365da-h3.c` (new compatible + this init sequence + mode +
lanes/format/flags), describe DSI0 + panel + backlight + vcc_lcd in the board `.dts`, enable
`DRM_ROCKCHIP`, `ROCKCHIP_DW_MIPI_DSI`, `DRM_PANEL_JADARD_JD9365DA_H3`, `BACKLIGHT_PWM`.
Check the driver's existing 800x1280 entries first — one may already match this glass.
