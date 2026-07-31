import sys
import time
import heapq
import pygame

pygame.init()
pygame.font.init()

# =========================================================
# Map
# =========================================================
GRID = [
    ["#", "#", "#", ".", ".", ".", ".", ".", ".", ".", ".", ".", "#"],
    ["#", "#", "#", ".", ".", ".", ".", ".", ".", "#", "#", ".", "#"],
    [".", ".", ".", ".", ".", ".", ".", ".", ".", "#", "#", ".", "G"],
    [".", "#", "#", "#", "#", "#", "#", "#", ".", "#", "#", "#", "."],
    ["S", "#", "#", "#", "#", "#", "#", "#", "#", "#", "#", "#", "."],
    [".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", "."],
    ["#", "#", "#", "#", "#", "#", "#", "#", "#", "#", "#", "#", "#"],
]

ROWS = len(GRID)
COLS = len(GRID[0])

# =========================================================
# Theme
# =========================================================
BG = (243, 247, 252)
CARD_BG = (255, 255, 255)
CARD_BORDER = (222, 228, 236)

TEXT = (33, 38, 45)
SUBTEXT = (105, 114, 128)

GRID_LINE = (212, 218, 226)
EMPTY = (238, 242, 247)
WALL = (63, 67, 73)

START_COLOR = (69, 139, 232)
GOAL_COLOR = (232, 87, 87)
OPEN_COLOR = (255, 219, 112)
CLOSED_COLOR = (163, 212, 255)
CURRENT_COLOR = (189, 138, 255)
PATH_COLOR = (122, 218, 142)

GREEDY_ACCENT = (52, 152, 219)
ASTAR_ACCENT = (155, 89, 182)
TAB_ACTIVE = (235, 242, 250)
TAB_INACTIVE = (248, 250, 253)

# =========================================================
# Screen / base settings
# =========================================================
display_info = pygame.display.Info()
SCREEN_W = display_info.current_w
SCREEN_H = display_info.current_h

INITIAL_W = min(1600, SCREEN_W - 120)
INITIAL_H = min(950, SCREEN_H - 120)

MIN_W = 1100
MIN_H = 700

FPS = 30
AUTO_DELAY_MS = 500

screen = pygame.display.set_mode((INITIAL_W, INITIAL_H), pygame.RESIZABLE)
pygame.display.set_caption("Greedy vs A* Visual Comparison")
clock = pygame.time.Clock()

# =========================================================
# Helpers
# =========================================================
def find_pos(target):
    for r in range(ROWS):
        for c in range(COLS):
            if GRID[r][c] == target:
                return (r, c)
    return None


START = find_pos("S")
GOAL = find_pos("G")


def heuristic(a, b):
    return abs(a[0] - b[0]) + abs(a[1] - b[1])


def get_neighbors(pos):
    r, c = pos
    candidates = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    out = []
    for dr, dc in candidates:
        nr, nc = r + dr, c + dc
        if 0 <= nr < ROWS and 0 <= nc < COLS and GRID[nr][nc] != "#":
            out.append((nr, nc))
    return out


def reconstruct_path(came_from, cur):
    path = []
    while cur in came_from:
        path.append(cur)
        cur = came_from[cur]
    path.append(START)
    path.reverse()
    return path


def create_stats(expanded, max_open, elapsed_ms, path):
    return {
        "expanded": expanded,
        "max_open": max_open,
        "elapsed_ms": elapsed_ms,
        "path_length": len(path) - 1 if path else None
    }


def format_path_length(v):
    return "--" if v is None else str(v)


def format_ms(v):
    return f"{v:.2f} ms"


def draw_round_rect(surface, rect, fill, radius=14, border=None, border_width=1):
    pygame.draw.rect(surface, fill, rect, border_radius=radius)
    if border is not None:
        pygame.draw.rect(surface, border, rect, width=border_width, border_radius=radius)


def draw_text(text, font_obj, color, x, y):
    surf = font_obj.render(text, True, color)
    screen.blit(surf, (x, y))
    return surf.get_rect(topleft=(x, y))


def wrap_text(text, font_obj, max_width):
    words = text.split()
    lines = []
    current = ""
    for word in words:
        test = word if not current else current + " " + word
        if font_obj.size(test)[0] <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


# =========================================================
# Dynamic layout + fonts
# =========================================================
def compute_layout(window_w, window_h, view_mode="both"):
    outer_pad = 16
    gap = 12
    header_h = 56
    footer_h = 72
    right_panel_w = max(280, min(360, window_w // 5))
    card_radius = 14

    content_x = outer_pad
    content_y = outer_pad + header_h
    content_w = window_w - outer_pad * 2
    content_h = window_h - header_h - footer_h - outer_pad * 2

    map_title_h = 42
    map_inner_pad = 14

    if view_mode == "both":
        maps_w = content_w - right_panel_w - gap
        map_card_w = max(260, (maps_w - gap) // 2)
        map_card_h = content_h
        right_x = content_x + map_card_w + gap + map_card_w + gap
    else:
        map_card_w = content_w - right_panel_w - gap
        map_card_h = content_h
        right_x = content_x + map_card_w + gap

    available_map_w = map_card_w - map_inner_pad * 2
    available_map_h = map_card_h - map_title_h - map_inner_pad * 2

    cell_size = max(28, min(available_map_w // COLS, available_map_h // ROWS))
    draw_map_w = cell_size * COLS
    draw_map_h = cell_size * ROWS

    return {
        "WINDOW_W": window_w,
        "WINDOW_H": window_h,
        "OUTER_PAD": outer_pad,
        "GAP": gap,
        "HEADER_H": header_h,
        "FOOTER_H": footer_h,
        "RIGHT_PANEL_W": right_panel_w,
        "CARD_RADIUS": card_radius,
        "CONTENT_X": content_x,
        "CONTENT_Y": content_y,
        "CONTENT_W": content_w,
        "CONTENT_H": content_h,
        "MAP_CARD_W": map_card_w,
        "MAP_CARD_H": map_card_h,
        "RIGHT_X": right_x,
        "MAP_TITLE_H": map_title_h,
        "MAP_INNER_PAD": map_inner_pad,
        "AVAILABLE_MAP_W": available_map_w,
        "AVAILABLE_MAP_H": available_map_h,
        "CELL_SIZE": cell_size,
        "DRAW_MAP_W": draw_map_w,
        "DRAW_MAP_H": draw_map_h,
        "VIEW_MODE": view_mode,
    }


def compute_fonts(cell_size):
    title_size = 26
    h2_size = 21
    normal_size = 18
    small_size = 16

    score_size = max(14, min(24, int(cell_size * 0.32)))
    node_label_size = max(16, min(26, int(cell_size * 0.40)))

    return {
        "title": pygame.font.SysFont("arial", title_size, bold=True),
        "h2": pygame.font.SysFont("arial", h2_size, bold=True),
        "normal": pygame.font.SysFont("arial", normal_size),
        "small": pygame.font.SysFont("arial", small_size),
        "tiny": pygame.font.SysFont("consolas", score_size, bold=False),
        "node": pygame.font.SysFont("arial", node_label_size, bold=True),
    }


# =========================================================
# Frame generation
# =========================================================
def make_frame(current, open_nodes, closed_nodes, path, scores, mode_text, stats):
    return {
        "current": current,
        "open": set(open_nodes),
        "closed": set(closed_nodes),
        "path": list(path),
        "scores": dict(scores),
        "mode_text": mode_text,
        "stats": dict(stats)
    }


def greedy_frames():
    t0 = time.perf_counter()
    heap = [(heuristic(START, GOAL), START)]
    visited = set()
    discovered = {START}
    came_from = {}
    frames = []
    max_open = 0

    while heap:
        _, current = heapq.heappop(heap)
        if current in visited:
            continue

        visited.add(current)

        scores = {}
        for node in discovered:
            scores[node] = {
                "g": None,
                "h": heuristic(node, GOAL),
                "f": None
            }

        open_nodes = discovered - visited
        closed_nodes = set(visited)
        max_open = max(max_open, len(open_nodes))

        stats = create_stats(len(closed_nodes), max_open, (time.perf_counter() - t0) * 1000, [])
        frames.append(make_frame(
            current, open_nodes, closed_nodes, [], scores,
            f"Greedy expands {current} using smallest h(n).", stats
        ))

        if current == GOAL:
            final_path = reconstruct_path(came_from, current)
            final_stats = create_stats(
                len(closed_nodes), max_open, (time.perf_counter() - t0) * 1000, final_path
            )
            for i in range(1, len(final_path) + 1):
                frames.append(make_frame(
                    current, set(), closed_nodes, final_path[:i], scores,
                    "Greedy reconstructs the final path.", final_stats
                ))
            return frames, final_stats

        for nb in get_neighbors(current):
            if nb not in visited and nb not in discovered:
                discovered.add(nb)
                came_from[nb] = current
                heapq.heappush(heap, (heuristic(nb, GOAL), nb))

        scores_after = {}
        for node in discovered:
            scores_after[node] = {
                "g": None,
                "h": heuristic(node, GOAL),
                "f": None
            }

        open_after = discovered - visited
        closed_after = set(visited)
        max_open = max(max_open, len(open_after))
        stats_after = create_stats(len(closed_after), max_open, (time.perf_counter() - t0) * 1000, [])

        frames.append(make_frame(
            current, open_after, closed_after, [], scores_after,
            "Greedy adds neighbors to OPEN.", stats_after
        ))

    return frames, create_stats(len(visited), max_open, (time.perf_counter() - t0) * 1000, [])


def astar_frames():
    t0 = time.perf_counter()
    heap = [(heuristic(START, GOAL), START)]
    came_from = {}
    g_score = {START: 0}
    visited = set()
    discovered = {START}
    frames = []
    max_open = 0

    while heap:
        _, current = heapq.heappop(heap)
        if current in visited:
            continue

        visited.add(current)

        scores = {}
        for node in discovered:
            g = g_score.get(node)
            h = heuristic(node, GOAL)
            f = None if g is None else g + h
            scores[node] = {"g": g, "h": h, "f": f}

        open_nodes = discovered - visited
        closed_nodes = set(visited)
        max_open = max(max_open, len(open_nodes))

        g_cur = g_score[current]
        h_cur = heuristic(current, GOAL)
        f_cur = g_cur + h_cur

        stats = create_stats(len(closed_nodes), max_open, (time.perf_counter() - t0) * 1000, [])
        frames.append(make_frame(
            current, open_nodes, closed_nodes, [], scores,
            f"A* expands {current} using smallest f(n)=g+h ({f_cur}={g_cur}+{h_cur}).", stats
        ))

        if current == GOAL:
            final_path = reconstruct_path(came_from, current)
            final_stats = create_stats(
                len(closed_nodes), max_open, (time.perf_counter() - t0) * 1000, final_path
            )
            for i in range(1, len(final_path) + 1):
                frames.append(make_frame(
                    current, set(), closed_nodes, final_path[:i], scores,
                    "A* reconstructs the final path.", final_stats
                ))
            return frames, final_stats

        for nb in get_neighbors(current):
            tentative_g = g_score[current] + 1
            if nb not in g_score or tentative_g < g_score[nb]:
                g_score[nb] = tentative_g
                came_from[nb] = current
                discovered.add(nb)
                heapq.heappush(heap, (tentative_g + heuristic(nb, GOAL), nb))

        scores_after = {}
        for node in discovered:
            g = g_score.get(node)
            h = heuristic(node, GOAL)
            f = None if g is None else g + h
            scores_after[node] = {"g": g, "h": h, "f": f}

        open_after = discovered - visited
        closed_after = set(visited)
        max_open = max(max_open, len(open_after))
        stats_after = create_stats(len(closed_after), max_open, (time.perf_counter() - t0) * 1000, [])

        frames.append(make_frame(
            current, open_after, closed_after, [], scores_after,
            "A* adds neighbors to OPEN.", stats_after
        ))

    return frames, create_stats(len(visited), max_open, (time.perf_counter() - t0) * 1000, [])


# =========================================================
# Node helpers
# =========================================================
def get_node_state(frame, pos):
    cell = GRID[pos[0]][pos[1]]
    if cell == "#":
        return "wall"
    if pos == START:
        return "start"
    if pos == GOAL:
        return "goal"
    if pos == frame["current"]:
        return "current"
    if pos in frame["path"]:
        return "path"
    if pos in frame["open"]:
        return "open"
    if pos in frame["closed"]:
        return "closed"
    return "unseen"


def get_node_info(frame, algo_name, pos):
    return {
        "algorithm": algo_name,
        "position": pos,
        "cell": GRID[pos[0]][pos[1]],
        "state": get_node_state(frame, pos),
        "scores": frame["scores"].get(pos)
    }


# =========================================================
# Drawing
# =========================================================
def draw_header(layout, fonts, view_mode):
    rect = pygame.Rect(
        layout["OUTER_PAD"],
        layout["OUTER_PAD"],
        layout["WINDOW_W"] - layout["OUTER_PAD"] * 2,
        layout["HEADER_H"]
    )
    draw_round_rect(screen, rect, CARD_BG, layout["CARD_RADIUS"], CARD_BORDER, 1)

    draw_text("Greedy vs A* Visual Comparison", fonts["title"], TEXT, rect.x + 14, rect.y + 10)
    draw_text(
        "Adaptive layout · side-by-side playback · node inspection",
        fonts["small"], SUBTEXT, rect.x + 14, rect.y + 34
    )

    btn_w = 82
    btn_h = 32
    gap = 8
    total_w = btn_w * 3 + gap * 2
    start_x = rect.right - total_w - 14
    y = rect.y + 12

    buttons = {
        "both": pygame.Rect(start_x, y, btn_w, btn_h),
        "Greedy": pygame.Rect(start_x + btn_w + gap, y, btn_w, btn_h),
        "A*": pygame.Rect(start_x + (btn_w + gap) * 2, y, btn_w, btn_h),
    }

    for key, brect in buttons.items():
        active = (view_mode == key)
        fill = TAB_ACTIVE if active else TAB_INACTIVE
        draw_round_rect(screen, brect, fill, 10, CARD_BORDER, 1)
        text_color = TEXT if active else SUBTEXT
        surf = fonts["small"].render(key, True, text_color)
        surf_rect = surf.get_rect(center=brect.center)
        screen.blit(surf, surf_rect)

    return buttons


def draw_map_card(x, y, w, h, title, accent, layout, fonts):
    rect = pygame.Rect(x, y, w, h)
    draw_round_rect(screen, rect, CARD_BG, layout["CARD_RADIUS"], CARD_BORDER, 1)
    pygame.draw.rect(screen, accent, (x, y, w, 7), border_radius=layout["CARD_RADIUS"])
    draw_text(title, fonts["h2"], TEXT, x + 14, y + 14)
    return rect


def draw_cell_centered_text(text, rect, font_obj, color):
    surf = font_obj.render(text, True, color)
    surf_rect = surf.get_rect(center=rect.center)
    screen.blit(surf, surf_rect)


def draw_score_lines_centered(lines, rect, font_obj, color, cell_size):
    if not lines:
        return
    line_gap = max(2, cell_size // 18)
    total_h = len(lines) * font_obj.get_height() + (len(lines) - 1) * line_gap
    start_y = rect.centery - total_h // 2
    for i, line in enumerate(lines):
        surf = font_obj.render(line, True, color)
        cy = start_y + i * (font_obj.get_height() + line_gap) + font_obj.get_height() // 2
        surf_rect = surf.get_rect(center=(rect.centerx, cy))
        screen.blit(surf, surf_rect)


def get_astar_visible_lines(sc, cell_size):
    lines = []
    if cell_size < 36:
        if sc["f"] is not None:
            lines = [f"f={sc['f']}"]
    elif cell_size < 48:
        if sc["f"] is not None:
            lines.append(f"f={sc['f']}")
        if sc["g"] is not None:
            lines.append(f"g={sc['g']}")
    else:
        if sc["f"] is not None:
            lines.append(f"f={sc['f']}")
        if sc["g"] is not None:
            lines.append(f"g={sc['g']}")
        lines.append(f"h={sc['h']}")
    return lines


def draw_map(frame, algo_name, x, y, w, h, accent, selected_algo, selected_pos, layout, fonts):
    draw_map_card(x, y, w, h, algo_name, accent, layout, fonts)

    cell_size = layout["CELL_SIZE"]
    map_inner_pad = layout["MAP_INNER_PAD"]
    map_title_h = layout["MAP_TITLE_H"]
    available_map_w = layout["AVAILABLE_MAP_W"]
    available_map_h = layout["AVAILABLE_MAP_H"]
    draw_map_w = layout["DRAW_MAP_W"]
    draw_map_h = layout["DRAW_MAP_H"]

    map_x = x + map_inner_pad + (available_map_w - draw_map_w) // 2
    map_y = y + map_title_h + map_inner_pad + (available_map_h - draw_map_h) // 2
    map_rect = pygame.Rect(map_x, map_y, draw_map_w, draw_map_h)

    current = frame["current"]
    open_nodes = frame["open"]
    closed_nodes = frame["closed"]
    path_nodes = frame["path"]
    scores = frame["scores"]

    for r in range(ROWS):
        for c in range(COLS):
            pos = (r, c)
            rect = pygame.Rect(map_x + c * cell_size, map_y + r * cell_size, cell_size, cell_size)
            cell = GRID[r][c]

            color = EMPTY
            if cell == "#":
                color = WALL
            if pos in open_nodes and cell not in ["#", "S", "G"]:
                color = OPEN_COLOR
            if pos in closed_nodes and cell not in ["#", "S", "G"]:
                color = CLOSED_COLOR
            if pos in path_nodes and cell not in ["#", "S", "G"]:
                color = PATH_COLOR
            if pos == current and cell not in ["#", "S", "G"]:
                color = CURRENT_COLOR
            if cell == "S":
                color = START_COLOR
            if cell == "G":
                color = GOAL_COLOR

            border_radius = 5 if cell_size >= 30 else 3
            pygame.draw.rect(screen, color, rect, border_radius=border_radius)
            pygame.draw.rect(screen, GRID_LINE, rect, 1, border_radius=border_radius)

            if selected_algo == algo_name and selected_pos == pos:
                pygame.draw.rect(screen, TEXT, rect.inflate(-4, -4), 2, border_radius=border_radius)

            if cell == "S":
                draw_cell_centered_text("S", rect, fonts["node"], TEXT)
            elif cell == "G":
                draw_cell_centered_text("G", rect, fonts["node"], TEXT)
            elif cell == "#":
                draw_cell_centered_text("#", rect, fonts["node"], (255, 255, 255))
            else:
                if pos in scores and cell_size >= 30:
                    sc = scores[pos]
                    if algo_name == "Greedy":
                        draw_score_lines_centered([f"h={sc['h']}"], rect, fonts["tiny"], TEXT, cell_size)
                    else:
                        lines = get_astar_visible_lines(sc, cell_size)
                        draw_score_lines_centered(lines, rect, fonts["tiny"], TEXT, cell_size)

    return map_rect


def draw_tabs(panel_x, panel_y, panel_w, active_tab, fonts):
    tabs = [("Control", "control"), ("Node", "node"), ("Stats", "stats")]
    tab_y = panel_y + 12
    tab_x = panel_x + 12
    tab_w = (panel_w - 24 - 8 * 2) // 3
    tab_h = 34
    tab_rects = {}

    for i, (label, key) in enumerate(tabs):
        x = tab_x + i * (tab_w + 8)
        rect = pygame.Rect(x, tab_y, tab_w, tab_h)
        fill = TAB_ACTIVE if key == active_tab else TAB_INACTIVE
        draw_round_rect(screen, rect, fill, 10, CARD_BORDER, 1)
        text_color = TEXT if key == active_tab else SUBTEXT
        surf = fonts["small"].render(label, True, text_color)
        surf_rect = surf.get_rect(center=rect.center)
        screen.blit(surf, surf_rect)
        tab_rects[key] = rect

    return tab_rects


def draw_right_panel(g_frame, a_frame, active_tab, selected_info, layout, fonts, view_mode):
    panel_x = layout["RIGHT_X"]
    panel_y = layout["CONTENT_Y"]
    panel_w = layout["RIGHT_PANEL_W"]
    panel_h = layout["CONTENT_H"]
    rect = pygame.Rect(panel_x, panel_y, panel_w, panel_h)

    draw_round_rect(screen, rect, CARD_BG, layout["CARD_RADIUS"], CARD_BORDER, 1)
    draw_text("Panel", fonts["h2"], TEXT, panel_x + 16, panel_y + 14)

    tab_rects = draw_tabs(panel_x, panel_y + 28, panel_w, active_tab, fonts)

    content_x = panel_x + 14
    content_y = panel_y + 88
    content_w = panel_w - 28

    if view_mode == "Greedy":
        title_algo = "Greedy"
        main_frame = g_frame
        other_frame = None
        main_accent = GREEDY_ACCENT
    elif view_mode == "A*":
        title_algo = "A*"
        main_frame = a_frame
        other_frame = None
        main_accent = ASTAR_ACCENT
    else:
        title_algo = None
        main_frame = None
        other_frame = None
        main_accent = None

    if active_tab == "control":
        draw_text("Keyboard", fonts["h2"], TEXT, content_x, content_y)
        lines = [
            "1 : Load algorithms",
            "SPACE : Next synchronized step",
            "A : Auto play / pause",
            "R : Reset",
            "ESC : Quit",
            "",
            "Mouse",
            "Click top buttons to switch view.",
            "Click node to inspect details."
        ]
        y = content_y + 34
        for line in lines:
            if line == "":
                y += 10
                continue
            color = TEXT if ":" in line or line == "Mouse" else SUBTEXT
            draw_text(line, fonts["small"], color, content_x, y)
            y += 24

        y += 6
        draw_text("Current step", fonts["h2"], TEXT, content_x, y)
        y += 32

        if view_mode == "both":
            draw_text("Greedy:", fonts["small"], GREEDY_ACCENT, content_x, y)
            y += 22
            for line in wrap_text(g_frame["mode_text"], fonts["small"], content_w):
                draw_text(line, fonts["small"], TEXT, content_x, y)
                y += 21

            y += 10
            draw_text("A*:", fonts["small"], ASTAR_ACCENT, content_x, y)
            y += 22
            for line in wrap_text(a_frame["mode_text"], fonts["small"], content_w):
                draw_text(line, fonts["small"], TEXT, content_x, y)
                y += 21
        else:
            draw_text(f"{title_algo}:", fonts["small"], main_accent, content_x, y)
            y += 22
            for line in wrap_text(main_frame["mode_text"], fonts["small"], content_w):
                draw_text(line, fonts["small"], TEXT, content_x, y)
                y += 21

    elif active_tab == "node":
        draw_text("Clicked Node Details", fonts["h2"], TEXT, content_x, content_y)
        y = content_y + 38
        if selected_info is None:
            tips = [
                "No node selected.",
                "Click any visible node",
                "to inspect its information."
            ]
            for line in tips:
                draw_text(line, fonts["small"], SUBTEXT, content_x, y)
                y += 24
        else:
            draw_text(f"Algorithm: {selected_info['algorithm']}", fonts["small"], TEXT, content_x, y)
            y += 24
            draw_text(f"Position: {selected_info['position']}", fonts["small"], TEXT, content_x, y)
            y += 24
            draw_text(f"State: {selected_info['state']}", fonts["small"], TEXT, content_x, y)
            y += 24
            draw_text(f"Cell: {selected_info['cell']}", fonts["small"], TEXT, content_x, y)
            y += 34

            draw_text("Scores", fonts["h2"], TEXT, content_x, y)
            y += 30
            sc = selected_info["scores"]
            if sc is None:
                draw_text("No score available for this node yet.", fonts["small"], SUBTEXT, content_x, y)
            else:
                if selected_info["algorithm"] == "Greedy":
                    draw_text(f"h = {sc['h']}", fonts["small"], TEXT, content_x, y)
                else:
                    draw_text(f"g = {sc['g']}", fonts["small"], TEXT, content_x, y)
                    y += 24
                    draw_text(f"h = {sc['h']}", fonts["small"], TEXT, content_x, y)
                    y += 24
                    draw_text(f"f = {sc['f']}", fonts["small"], TEXT, content_x, y)

    elif active_tab == "stats":
        draw_text("Live Stats", fonts["h2"], TEXT, content_x, content_y)
        y = content_y + 38

        if view_mode == "both":
            box_h = 110
            g_box = pygame.Rect(content_x, y, content_w, box_h)
            draw_round_rect(screen, g_box, (247, 251, 255), 12, CARD_BORDER, 1)
            draw_text("Greedy", fonts["small"], GREEDY_ACCENT, g_box.x + 12, g_box.y + 10)
            draw_text(f"Expanded: {g_frame['stats']['expanded']}", fonts["small"], TEXT, g_box.x + 12, g_box.y + 36)
            draw_text(f"Path: {format_path_length(g_frame['stats']['path_length'])}", fonts["small"], TEXT, g_box.x + 150, g_box.y + 36)
            draw_text(f"Time: {format_ms(g_frame['stats']['elapsed_ms'])}", fonts["small"], TEXT, g_box.x + 12, g_box.y + 62)
            draw_text(f"Max Open: {g_frame['stats']['max_open']}", fonts["small"], TEXT, g_box.x + 150, g_box.y + 62)

            y += box_h + 14

            a_box = pygame.Rect(content_x, y, content_w, box_h)
            draw_round_rect(screen, a_box, (251, 247, 255), 12, CARD_BORDER, 1)
            draw_text("A*", fonts["small"], ASTAR_ACCENT, a_box.x + 12, a_box.y + 10)
            draw_text(f"Expanded: {a_frame['stats']['expanded']}", fonts["small"], TEXT, a_box.x + 12, a_box.y + 36)
            draw_text(f"Path: {format_path_length(a_frame['stats']['path_length'])}", fonts["small"], TEXT, a_box.x + 150, a_box.y + 36)
            draw_text(f"Time: {format_ms(a_frame['stats']['elapsed_ms'])}", fonts["small"], TEXT, a_box.x + 12, a_box.y + 62)
            draw_text(f"Max Open: {a_frame['stats']['max_open']}", fonts["small"], TEXT, a_box.x + 150, a_box.y + 62)
        else:
            box_h = 110
            box = pygame.Rect(content_x, y, content_w, box_h)
            fill = (247, 251, 255) if view_mode == "Greedy" else (251, 247, 255)
            draw_round_rect(screen, box, fill, 12, CARD_BORDER, 1)
            draw_text(title_algo, fonts["small"], main_accent, box.x + 12, box.y + 10)
            draw_text(f"Expanded: {main_frame['stats']['expanded']}", fonts["small"], TEXT, box.x + 12, box.y + 36)
            draw_text(f"Path: {format_path_length(main_frame['stats']['path_length'])}", fonts["small"], TEXT, box.x + 150, box.y + 36)
            draw_text(f"Time: {format_ms(main_frame['stats']['elapsed_ms'])}", fonts["small"], TEXT, box.x + 12, box.y + 62)
            draw_text(f"Max Open: {main_frame['stats']['max_open']}", fonts["small"], TEXT, box.x + 150, box.y + 62)

    return tab_rects


def draw_footer_bar(g_stats, a_stats, layout, fonts, view_mode):
    x = layout["OUTER_PAD"]
    y = layout["WINDOW_H"] - layout["OUTER_PAD"] - layout["FOOTER_H"]
    w = layout["WINDOW_W"] - layout["OUTER_PAD"] * 2
    h = layout["FOOTER_H"]
    rect = pygame.Rect(x, y, w, h)

    draw_round_rect(screen, rect, CARD_BG, layout["CARD_RADIUS"], CARD_BORDER, 1)

    if view_mode == "both":
        if a_stats["expanded"] < g_stats["expanded"]:
            better_expanded = "A*"
        elif a_stats["expanded"] > g_stats["expanded"]:
            better_expanded = "Greedy"
        else:
            better_expanded = "Tie"

        gp = g_stats["path_length"]
        ap = a_stats["path_length"]
        if gp is None or ap is None:
            better_path = "N/A"
        elif ap < gp:
            better_path = "A*"
        elif ap > gp:
            better_path = "Greedy"
        else:
            better_path = "Tie"

        line1 = (
            f"Greedy  Expanded:{g_stats['expanded']}  "
            f"Path:{format_path_length(g_stats['path_length'])}  "
            f"Time:{format_ms(g_stats['elapsed_ms'])}  "
            f"MaxOpen:{g_stats['max_open']}"
        )
        line2 = (
            f"A*      Expanded:{a_stats['expanded']}  "
            f"Path:{format_path_length(a_stats['path_length'])}  "
            f"Time:{format_ms(a_stats['elapsed_ms'])}  "
            f"MaxOpen:{a_stats['max_open']}"
        )
        line3 = f"Comparison  Better Path: {better_path}   Fewer Expanded Nodes: {better_expanded}"

        draw_text(line1, fonts["small"], TEXT, x + 14, y + 10)
        draw_text(line2, fonts["small"], TEXT, x + 14, y + 31)
        draw_text(line3, fonts["small"], SUBTEXT, x + 14, y + 52)

    elif view_mode == "Greedy":
        line1 = (
            f"Greedy  Expanded:{g_stats['expanded']}  "
            f"Path:{format_path_length(g_stats['path_length'])}  "
            f"Time:{format_ms(g_stats['elapsed_ms'])}  "
            f"MaxOpen:{g_stats['max_open']}"
        )
        line2 = "Greedy uses h(n) only, so it expands the node that appears closest to the goal."
        draw_text(line1, fonts["small"], TEXT, x + 14, y + 16)
        draw_text(line2, fonts["small"], SUBTEXT, x + 14, y + 42)

    elif view_mode == "A*":
        line1 = (
            f"A*  Expanded:{a_stats['expanded']}  "
            f"Path:{format_path_length(a_stats['path_length'])}  "
            f"Time:{format_ms(a_stats['elapsed_ms'])}  "
            f"MaxOpen:{a_stats['max_open']}"
        )
        line2 = "A* uses f(n)=g(n)+h(n), balancing traveled cost and estimated remaining cost."
        draw_text(line1, fonts["small"], TEXT, x + 14, y + 16)
        draw_text(line2, fonts["small"], SUBTEXT, x + 14, y + 42)


# =========================================================
# Main
# =========================================================
def main():
    global screen

    greedy_all_frames, greedy_final = greedy_frames()
    astar_all_frames, astar_final = astar_frames()

    window_w, window_h = INITIAL_W, INITIAL_H
    view_mode = "both"
    layout = compute_layout(window_w, window_h, view_mode)
    fonts = compute_fonts(layout["CELL_SIZE"])

    g_index = 0
    a_index = 0
    auto_play = False
    auto_timer = 0

    active_tab = "control"
    selected_algo = None
    selected_pos = None
    selected_info = None

    empty_stats = create_stats(0, 0, 0.0, [])
    empty_frame = make_frame(None, set(), set(), [], {}, "Press 1 to load both algorithms.", empty_stats)

    use_loaded = False

    while True:
        dt = clock.tick(FPS)

        if use_loaded:
            g_frame = greedy_all_frames[g_index]
            a_frame = astar_all_frames[a_index]
            footer_g = greedy_final
            footer_a = astar_final
        else:
            g_frame = empty_frame
            a_frame = empty_frame
            footer_g = empty_stats
            footer_a = empty_stats

        screen.fill(BG)
        header_buttons = draw_header(layout, fonts, view_mode)

        greedy_map_rect = None
        astar_map_rect = None

        if view_mode == "both":
            greedy_card_x = layout["CONTENT_X"]
            greedy_card_y = layout["CONTENT_Y"]
            astar_card_x = layout["CONTENT_X"] + layout["MAP_CARD_W"] + layout["GAP"]
            astar_card_y = layout["CONTENT_Y"]

            greedy_map_rect = draw_map(
                g_frame, "Greedy",
                greedy_card_x, greedy_card_y,
                layout["MAP_CARD_W"], layout["MAP_CARD_H"],
                GREEDY_ACCENT, selected_algo, selected_pos, layout, fonts
            )

            astar_map_rect = draw_map(
                a_frame, "A*",
                astar_card_x, astar_card_y,
                layout["MAP_CARD_W"], layout["MAP_CARD_H"],
                ASTAR_ACCENT, selected_algo, selected_pos, layout, fonts
            )

        elif view_mode == "Greedy":
            greedy_map_rect = draw_map(
                g_frame, "Greedy",
                layout["CONTENT_X"], layout["CONTENT_Y"],
                layout["MAP_CARD_W"], layout["MAP_CARD_H"],
                GREEDY_ACCENT, selected_algo, selected_pos, layout, fonts
            )

        elif view_mode == "A*":
            astar_map_rect = draw_map(
                a_frame, "A*",
                layout["CONTENT_X"], layout["CONTENT_Y"],
                layout["MAP_CARD_W"], layout["MAP_CARD_H"],
                ASTAR_ACCENT, selected_algo, selected_pos, layout, fonts
            )

        tab_rects = draw_right_panel(g_frame, a_frame, active_tab, selected_info, layout, fonts, view_mode)
        draw_footer_bar(footer_g, footer_a, layout, fonts, view_mode)

        pygame.display.flip()

        if auto_play and use_loaded:
            auto_timer += dt
            if auto_timer >= AUTO_DELAY_MS:
                auto_timer = 0
                if g_index < len(greedy_all_frames) - 1:
                    g_index += 1
                if a_index < len(astar_all_frames) - 1:
                    a_index += 1
                if g_index >= len(greedy_all_frames) - 1 and a_index >= len(astar_all_frames) - 1:
                    auto_play = False

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

            elif event.type == pygame.VIDEORESIZE:
                window_w = max(MIN_W, event.w)
                window_h = max(MIN_H, event.h)
                screen = pygame.display.set_mode((window_w, window_h), pygame.RESIZABLE)
                layout = compute_layout(window_w, window_h, view_mode)
                fonts = compute_fonts(layout["CELL_SIZE"])

            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    pygame.quit()
                    sys.exit()

                elif event.key == pygame.K_1:
                    use_loaded = True
                    g_index = 0
                    a_index = 0
                    auto_play = False
                    auto_timer = 0
                    selected_algo = None
                    selected_pos = None
                    selected_info = None

                elif event.key == pygame.K_SPACE:
                    if use_loaded:
                        if g_index < len(greedy_all_frames) - 1:
                            g_index += 1
                        if a_index < len(astar_all_frames) - 1:
                            a_index += 1
                        auto_play = False
                        auto_timer = 0

                elif event.key == pygame.K_a:
                    if use_loaded:
                        if g_index >= len(greedy_all_frames) - 1 and a_index >= len(astar_all_frames) - 1:
                            g_index = 0
                            a_index = 0
                        auto_play = not auto_play
                        auto_timer = 0

                elif event.key == pygame.K_r:
                    use_loaded = False
                    g_index = 0
                    a_index = 0
                    auto_play = False
                    auto_timer = 0
                    selected_algo = None
                    selected_pos = None
                    selected_info = None
                    active_tab = "control"

            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                mx, my = event.pos

                for key, rect in header_buttons.items():
                    if rect.collidepoint(mx, my):
                        view_mode = key
                        layout = compute_layout(window_w, window_h, view_mode)
                        fonts = compute_fonts(layout["CELL_SIZE"])
                        selected_algo = None
                        selected_pos = None
                        selected_info = None

                for key, rect in tab_rects.items():
                    if rect.collidepoint(mx, my):
                        active_tab = key

                if use_loaded and greedy_map_rect is not None and greedy_map_rect.collidepoint(mx, my):
                    c = (mx - greedy_map_rect.x) // layout["CELL_SIZE"]
                    r = (my - greedy_map_rect.y) // layout["CELL_SIZE"]
                    if 0 <= r < ROWS and 0 <= c < COLS:
                        pos = (r, c)
                        selected_algo = "Greedy"
                        selected_pos = pos
                        selected_info = get_node_info(g_frame, "Greedy", pos)
                        active_tab = "node"

                elif use_loaded and astar_map_rect is not None and astar_map_rect.collidepoint(mx, my):
                    c = (mx - astar_map_rect.x) // layout["CELL_SIZE"]
                    r = (my - astar_map_rect.y) // layout["CELL_SIZE"]
                    if 0 <= r < ROWS and 0 <= c < COLS:
                        pos = (r, c)
                        selected_algo = "A*"
                        selected_pos = pos
                        selected_info = get_node_info(a_frame, "A*", pos)
                        active_tab = "node"


if __name__ == "__main__":
    main()