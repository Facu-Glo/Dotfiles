# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false, reportIncompatibleMethodOverride=false
from kitty.tab_bar import DrawData, ExtraData, TabBarData, draw_tab_with_separator

from .base import LeftComponent


class TabsComponent(LeftComponent):
    def draw(
        self,
        draw_data: DrawData,
        screen,
        tab: TabBarData,
        before: int,
        max_title_length: int,
        index: int,
        is_last: bool,
        extra_data: ExtraData,
    ) -> int:
        return draw_tab_with_separator(
            draw_data, screen, tab, before, max_title_length,
            index, is_last, extra_data,
        )
