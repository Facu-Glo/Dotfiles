# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false
from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData


class LeftComponent:
    def draw(
        self,
        draw_data: DrawData,
        screen: Screen,
        tab: TabBarData,
        before: int,
        max_title_length: int,
        index: int,
        is_last: bool,
        extra_data: ExtraData,
    ) -> int:
        return 0


class RightComponent:
    def render(self, draw_data: DrawData) -> list[tuple[str, int, int, bool]]:
        return []
