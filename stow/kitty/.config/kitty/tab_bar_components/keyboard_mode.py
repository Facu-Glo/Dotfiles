# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false
from kitty.boss import get_boss

from .base import RightComponent

MODE_COLORS = {
    "wm": (0x77A0F2, True),
    "vim-mode": (0xBB9AF7, True),
}


class KeyboardModeComponent(RightComponent):
    def render(self, draw_data) -> list[tuple[str, int, int, bool]]:
        mode = get_boss().mappings.current_keyboard_mode_name
        bg = int(draw_data.default_bg)
        if mode:
            fg, bold = MODE_COLORS.get(mode, (0xFFFFFF, True))
            bg = int(draw_data.default_bg)
            return [(f" {mode.upper()}", bg, fg, bold)]
        return []
