# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false, reportUnusedVariable=false
import subprocess
from kitty.boss import get_boss
from kitty.fast_data_types import Screen
from kitty.tab_bar import (  # type: ignore
    DrawData,  # type: ignore
    ExtraData,  # type: ignore
    TabBarData,  # type: ignore
    TabAccessor,  # type: ignore
    as_rgb,  # type: ignore
    draw_tab_with_separator,  # type: ignore
)

# -------------------------
# Config
# -------------------------
SHOW_GIT = False

# -------------------------
# Git: contar cambios
# -------------------------
def get_git_changes(cwd: str) -> list[tuple[str, int]]:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=1,
        )
        if result.returncode != 0:
            return []

        status_result = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=1,
        )
        if status_result.returncode != 0:
            return []

        lines = [line.rstrip("\n") for line in status_result.stdout.splitlines() if line]
        if not lines:
            return []

        staged     = sum(1 for line in lines if line[0] not in " ?")
        modified   = sum((line[0] == "M") + (line[1] == "M") for line in lines if not line.startswith("??"))
        deleted    = sum((line[0] == "D") + (line[1] == "D") for line in lines if not line.startswith("??"))
        untracked  = sum(1 for line in lines if line.startswith("??"))

        result_list = []
        if staged > 0:
            result_list.append((f" {staged}", 0x96E364))
        if modified > 0:
            result_list.append((f" {modified}", 0xE3B419))
        if deleted > 0:
            result_list.append((f" {deleted}", 0xE33C19))
        if untracked > 0:
            result_list.append((f" {untracked}", 0xD795F4))

        return result_list

    except Exception:
        return []

# -------------------------
# Dibujar parte izquierda (icono + separador + título)
# -------------------------
def _draw_left_status(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    return draw_tab_with_separator(
        draw_data,
        screen,
        tab,
        before,
        max_title_length,
        index,
        is_last,
        extra_data,
    )

# -------------------------
# Dibujar parte derecha (separador + estado git)
# -------------------------
def _draw_right_status(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    is_last: bool,
) -> int:
    active_id = get_boss().active_tab.id
    active_tab = TabAccessor(active_id)

    # Indicadores de la derecha (app name + keyboard mode)
    if is_last:
        right_parts = []

        # Keyboard mode indicator
        mode = get_boss().mappings.current_keyboard_mode_name
        if mode:
            right_parts.append((f" {mode.upper()} ", 0x81C8BE))

        # App name
        title = active_tab.active_oldest_exe
        if title:
            right_parts.append((f"  {title}", 0x81C8BE))

        # Git status
        if SHOW_GIT:
            cwd = active_tab.active_oldest_wd or ""
            for text, color in get_git_changes(cwd):
                right_parts.append((text, color))

        if right_parts:
            total = sum(len(t) for t, _ in right_parts) + len(right_parts) - 1
            screen.cursor.x = max(0, screen.columns - total - 1)
            screen.cursor.bg = as_rgb(int(draw_data.default_bg))
            for text, color in right_parts:
                screen.cursor.fg = as_rgb(color)
                screen.draw(text + " ")

    return screen.cursor.x

# -------------------------
# Función principal
# -------------------------
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
    _draw_left_status(draw_data, screen, tab, before, max_title_length, index, is_last, extra_data)
    return _draw_right_status(draw_data, screen, tab, is_last)
