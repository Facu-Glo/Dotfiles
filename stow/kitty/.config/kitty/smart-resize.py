from kittens.tui.handler import result_handler # type: ignore

RESIZE_STEP = 1

def main(args):
    pass

@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    direction = args[1]
    neighbors = boss.active_tab.current_layout.neighbors_for_window(window, boss.active_tab.windows)

    rules = {
        "left":   ("wider", "narrower"),
        "right":  ("narrower", "wider"),
        "up":     ("taller", "shorter"),
        "down":   ("shorter", "taller"),
    }

    sides = {
        "left":   ("left", "right"),
        "right":  ("left", "right"),
        "up":     ("top", "bottom"),
        "down":   ("top", "bottom"),
    }

    if direction not in rules:
        return

    primary, secondary = rules[direction]
    first, second = sides[direction]

    has_first = bool(neighbors.get(first))
    has_second = bool(neighbors.get(second))

    if has_first and has_second:
        action = secondary
    elif has_first:
        action = primary
    elif has_second:
        action = secondary
    else:
        return

    boss.active_tab.resize_window(action, RESIZE_STEP)
