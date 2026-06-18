# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false, reportUnusedVariable=false
import os
import sys
from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

sys.path.insert(0, os.path.dirname(__file__))

from tab_bar_components.tabs import TabsComponent
from tab_bar_components.keyboard_mode import KeyboardModeComponent
from tab_bar_components.app_name import AppNameComponent
# from tab_bar_components.git import GitComponent

LEFT_COMPONENTS = [TabsComponent()]
RIGHT_COMPONENTS = [
    KeyboardModeComponent(),
    AppNameComponent(),
    # GitComponent(),
]


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    for comp in LEFT_COMPONENTS:
        comp.draw(
            draw_data, screen, tab, before, max_title_length,
            index, is_last, extra_data,
        )

    if is_last:
        segments = []
        for comp in RIGHT_COMPONENTS:
            segments.extend(comp.render(draw_data))

        if segments:
            total = sum(len(t) for t, _ in segments) + len(segments) - 1
            screen.cursor.x = max(0, screen.columns - total - 1)
            screen.cursor.bg = as_rgb(int(draw_data.default_bg))
            for text, color in segments:
                screen.cursor.fg = as_rgb(color)
                screen.draw(text + " ")

    return screen.cursor.x
