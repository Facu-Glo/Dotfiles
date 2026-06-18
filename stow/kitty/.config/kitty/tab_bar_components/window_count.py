# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false
from kitty.boss import get_boss

from .base import RightComponent

FG_COLOR = 0x77A0F2
BOLD = False


class WindowCountComponent(RightComponent):
    def render(self, draw_data) -> list[tuple[str, int, int, bool]]:
        active_tab = get_boss().active_tab
        if active_tab is None:
            return []
        num_windows = len(getattr(active_tab, 'windows', []))
        if num_windows > 1:
            bg = int(draw_data.default_bg)
            return [(f" {num_windows}", FG_COLOR, bg, BOLD)]
        return []
