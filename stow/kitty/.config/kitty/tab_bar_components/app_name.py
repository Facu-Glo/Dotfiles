# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false
from kitty.boss import get_boss
from kitty.tab_bar import TabAccessor

from .base import RightComponent

FG_COLOR = 0x81C8BE


class AppNameComponent(RightComponent):
    def render(self, draw_data) -> list[tuple[str, int, int]]:
        active_id = get_boss().active_tab.id
        active_tab = TabAccessor(active_id)
        title = active_tab.active_oldest_exe
        if title:
            bg = int(draw_data.default_bg)
            return [(f"  {title}", FG_COLOR, bg)]
        return []
