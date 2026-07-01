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
    boss.pop_keyboard_mode()
