from kittens.tui.handler import result_handler  # type: ignore


def main(args):
    pass


def detect_side(window, neighbors):
    has_left = bool(neighbors.get("left"))
    has_right = bool(neighbors.get("right"))
    if has_right and not has_left:
        return "left"
    if has_left and not has_right:
        return "right"
    return "middle"


@result_handler(no_ui=True)
def handle_result(args, _result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    key = args[1]
    neighbors = boss.active_tab.current_layout.neighbors_for_window(
        window, boss.active_tab.windows
    )
    side = detect_side(window, neighbors)

    if side == "left":
        bias = 80 if key == "period" else 50
    elif side == "right":
        bias = 80 if key == "comma" else 50
    else:
        bias = 50

    boss.active_tab.layout_action("bias", [bias])
