# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false
from kitty.boss import get_boss

from .base import RightComponent

LABEL = " VIM-MODE"
FG_COLOR = 0xBB9AF7
BOLD = True


def _is_scrollback_pager(window) -> bool:
    if window is None:
        return False
    spec = getattr(window, "creation_spec", None)
    if spec is None or spec.overlay_for is None:
        return False
    return any("nvim-pager.lua" in arg for arg in (spec.cmd or ()))


class PagerModeComponent(RightComponent):
    def render(self, draw_data) -> list[tuple[str, int, int, bool]]:
        boss = get_boss()
        if _is_scrollback_pager(getattr(boss, "active_window", None)):
            bg = int(draw_data.default_bg)
            return [(LABEL, bg, FG_COLOR, BOLD)]
        return []
