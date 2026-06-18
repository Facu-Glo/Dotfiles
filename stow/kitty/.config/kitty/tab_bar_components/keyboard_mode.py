# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false
from kitty.boss import get_boss

from .base import RightComponent

FG_COLOR = 0x77A0F2
BOLD = True


class KeyboardModeComponent(RightComponent):
    def render(self, draw_data) -> list[tuple[str, int, int, bool]]:
        mode = get_boss().mappings.current_keyboard_mode_name
        bg = int(draw_data.default_bg)
        if mode:
            return [(f" {mode.upper()}", FG_COLOR, bg, BOLD)]
        return []
