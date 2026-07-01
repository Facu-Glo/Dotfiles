from kittens.tui.handler import result_handler  # type: ignore


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    boss.call_remote_control(None, ("action", "show_scrollback"))
    boss.pop_keyboard_mode()
