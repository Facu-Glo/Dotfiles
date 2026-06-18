# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false
from kitty.boss import get_boss
from kitty.tab_bar import TabAccessor

from .base import RightComponent

INDICATOR_COLOR = 0x81C8BE


class AppNameComponent(RightComponent):
    def render(self, draw_data) -> list[tuple[str, int]]:
        active_id = get_boss().active_tab.id
        active_tab = TabAccessor(active_id)
        title = active_tab.active_oldest_exe
        if title:
            return [(f" {title}", INDICATOR_COLOR)]
        return []
