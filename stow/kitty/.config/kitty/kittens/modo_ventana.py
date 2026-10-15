from kittens.tui.handler import result_handler  # type: ignore


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    action = args[1] if len(args) > 1 else "vsplit"
    if action == "vsplit":
        boss.call_remote_control(None, ("launch", "--location=vsplit", "--cwd=current"))
    elif action == "hsplit":
        boss.call_remote_control(None, ("launch", "--location=hsplit", "--cwd=current"))
    elif action == "close":
        boss.call_remote_control(None, ("close-window",))
    elif action == "close_other":
        window = boss.window_id_map.get(target_window_id)
        tab = window.tabref() if window is not None else boss.active_tab
        if tab is not None:
            keep_id = (
                window.id
                if window is not None
                else getattr(tab.active_window, "id", -1)
            )
            for w in tuple(tab):
                if w.id != keep_id:
                    boss.mark_window_for_close(w)
    boss.pop_keyboard_mode()
