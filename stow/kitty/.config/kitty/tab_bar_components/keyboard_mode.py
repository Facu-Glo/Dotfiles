# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false
from kitty.boss import get_boss

from .base import RightComponent

FG_COLOR = 0x000000
BG_COLOR = 0x77a0f2


class KeyboardModeComponent(RightComponent):
    def render(self, draw_data) -> list[tuple[str, int, int]]:
        mode = get_boss().mappings.current_keyboard_mode_name
        if mode:
            return [(f" {mode.upper()}", FG_COLOR, BG_COLOR)]
        return []
