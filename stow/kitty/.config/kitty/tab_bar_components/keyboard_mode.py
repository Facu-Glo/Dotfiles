# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false
from kitty.boss import get_boss

from .base import RightComponent

INDICATOR_COLOR = 0x81C8BE


class KeyboardModeComponent(RightComponent):
    def render(self, draw_data) -> list[tuple[str, int]]:
        mode = get_boss().mappings.current_keyboard_mode_name
        if mode:
            return [(f" {mode.upper()} ", INDICATOR_COLOR)]
        return []
