# pyright: reportMissingImports=false, reportGeneralTypeIssues=false, reportCallIssue=false, reportAttributeAccessIssue=false
import subprocess

from kitty.boss import get_boss
from kitty.tab_bar import TabAccessor

from .base import RightComponent

def _get_git_changes(cwd: str, default_bg: int) -> list[tuple[str, int, int]]:
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

        lines = [
            line.rstrip("\n")
            for line in status_result.stdout.splitlines()
            if line
        ]
        if not lines:
            return []

        staged = sum(1 for line in lines if line[0] not in " ?")
        modified = sum(
            (line[0] == "M") + (line[1] == "M")
            for line in lines
            if not line.startswith("??")
        )
        deleted = sum(
            (line[0] == "D") + (line[1] == "D")
            for line in lines
            if not line.startswith("??")
        )
        untracked = sum(1 for line in lines if line.startswith("??"))

        result_list = []
        if staged > 0:
            result_list.append((f" {staged}", 0x96E364, default_bg))
        if modified > 0:
            result_list.append((f" {modified}", 0xE3B419, default_bg))
        if deleted > 0:
            result_list.append((f" {deleted}", 0xE33C19, default_bg))
        if untracked > 0:
            result_list.append((f" {untracked}", 0xD795F4, default_bg))

        return result_list

    except Exception:
        return []


class GitComponent(RightComponent):
    def render(self, draw_data) -> list[tuple[str, int, int]]:
        active_id = get_boss().active_tab.id
        active_tab = TabAccessor(active_id)
        cwd = active_tab.active_oldest_wd or ""
        return _get_git_changes(cwd, int(draw_data.default_bg))
