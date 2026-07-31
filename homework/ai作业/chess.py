import math
import random
import time
import tkinter as tk
import tkinter.font as tkfont
from tkinter import ttk, messagebox
from dataclasses import dataclass

BOARD_SIZE = 3
EMPTY = ""
HUMAN = "X"
AI = "O"
BG_COLOR = "#f6f8fb"
PANEL_BG = "#ffffff"
BOARD_BG = "#ffffff"
GRID_COLOR = "#415a77"
X_COLOR = "#d64045"
O_COLOR = "#2563eb"
TEXT_COLOR = "#1f2937"
SUBTEXT_COLOR = "#475569"
ACCENT_COLOR = "#3b82f6"


def check_winner(board):
    lines = []
    lines.extend(board)
    lines.extend([[board[r][c] for r in range(BOARD_SIZE)] for c in range(BOARD_SIZE)])
    lines.append([board[i][i] for i in range(BOARD_SIZE)])
    lines.append([board[i][BOARD_SIZE - 1 - i] for i in range(BOARD_SIZE)])
    for line in lines:
        if line[0] != EMPTY and all(cell == line[0] for cell in line):
            return line[0]
    if all(board[r][c] != EMPTY for r in range(BOARD_SIZE) for c in range(BOARD_SIZE)):
        return "Draw"
    return None


def available_moves(board):
    return [(r, c) for r in range(BOARD_SIZE) for c in range(BOARD_SIZE) if board[r][c] == EMPTY]


def clone_board(board):
    return [row[:] for row in board]


def ordered_moves(board):
    priority = [(1, 1), (0, 0), (0, 2), (2, 0), (2, 2), (0, 1), (1, 0), (1, 2), (2, 1)]
    return [move for move in priority if board[move[0]][move[1]] == EMPTY]


def board_to_tuple(board):
    return tuple(tuple(row) for row in board)


class MinimaxAI:
    name = "最小最大搜索"

    def __init__(self):
        self.nodes = 0
        self.cache = {}

    def evaluate_terminal(self, result, depth):
        if result == AI:
            return 10 - depth
        if result == HUMAN:
            return depth - 10
        return 0

    def minimax(self, board, is_maximizing, depth):
        self.nodes += 1
        key = (board_to_tuple(board), is_maximizing)
        if key in self.cache:
            return self.cache[key]

        result = check_winner(board)
        if result is not None:
            score = self.evaluate_terminal(result, depth)
            self.cache[key] = score
            return score

        if is_maximizing:
            best_score = -math.inf
            for r, c in ordered_moves(board):
                board[r][c] = AI
                score = self.minimax(board, False, depth + 1)
                board[r][c] = EMPTY
                best_score = max(best_score, score)
        else:
            best_score = math.inf
            for r, c in ordered_moves(board):
                board[r][c] = HUMAN
                score = self.minimax(board, True, depth + 1)
                board[r][c] = EMPTY
                best_score = min(best_score, score)

        self.cache[key] = best_score
        return best_score

    def choose_move(self, board):
        self.nodes = 0
        self.cache.clear()
        start = time.perf_counter()
        best_score = -math.inf
        best_move = None
        for r, c in ordered_moves(board):
            board[r][c] = AI
            score = self.minimax(board, False, 0)
            board[r][c] = EMPTY
            if score > best_score:
                best_score = score
                best_move = (r, c)
        elapsed = time.perf_counter() - start
        return best_move, elapsed, self.nodes


class AlphaBetaAI:
    name = "Alpha-Beta剪枝"

    def __init__(self):
        self.nodes = 0

    def evaluate_terminal(self, result, depth):
        if result == AI:
            return 10 - depth
        if result == HUMAN:
            return depth - 10
        return 0

    def search(self, board, depth, alpha, beta, is_maximizing):
        self.nodes += 1
        result = check_winner(board)
        if result is not None:
            return self.evaluate_terminal(result, depth)

        if is_maximizing:
            value = -math.inf
            for r, c in ordered_moves(board):
                board[r][c] = AI
                value = max(value, self.search(board, depth + 1, alpha, beta, False))
                board[r][c] = EMPTY
                alpha = max(alpha, value)
                if alpha >= beta:
                    break
            return value
        else:
            value = math.inf
            for r, c in ordered_moves(board):
                board[r][c] = HUMAN
                value = min(value, self.search(board, depth + 1, alpha, beta, True))
                board[r][c] = EMPTY
                beta = min(beta, value)
                if alpha >= beta:
                    break
            return value

    def choose_move(self, board):
        self.nodes = 0
        start = time.perf_counter()
        best_score = -math.inf
        best_move = None
        for r, c in ordered_moves(board):
            board[r][c] = AI
            score = self.search(board, 0, -math.inf, math.inf, False)
            board[r][c] = EMPTY
            if score > best_score:
                best_score = score
                best_move = (r, c)
        elapsed = time.perf_counter() - start
        return best_move, elapsed, self.nodes


@dataclass
class MCTSNode:
    board: list
    player_to_move: str
    parent: 'MCTSNode' = None
    move: tuple = None
    wins: float = 0.0
    visits: int = 0
    children: list = None
    untried_moves: list = None

    def __post_init__(self):
        if self.children is None:
            self.children = []
        if self.untried_moves is None:
            self.untried_moves = available_moves(self.board)

    def uct_score(self, total_visits, c=1.414):
        if self.visits == 0:
            return float('inf')
        return self.wins / self.visits + c * math.sqrt(math.log(max(total_visits, 1)) / self.visits)


class MCTSAI:
    name = "MCTS蒙特卡洛树搜索"

    def __init__(self, iterations=1500):
        self.iterations = iterations
        self.nodes = 0

    def rollout(self, board, player):
        current = player
        sim_board = clone_board(board)
        while True:
            result = check_winner(sim_board)
            if result is not None:
                if result == AI:
                    return 1.0
                if result == HUMAN:
                    return 0.0
                return 0.5
            move = random.choice(available_moves(sim_board))
            sim_board[move[0]][move[1]] = current
            current = HUMAN if current == AI else AI

    def choose_move(self, board):
        self.nodes = 0
        start = time.perf_counter()
        root = MCTSNode(clone_board(board), AI)
        for _ in range(self.iterations):
            node = root
            while not node.untried_moves and node.children:
                node = max(node.children, key=lambda child: child.uct_score(node.visits))
            if node.untried_moves:
                move = random.choice(node.untried_moves)
                node.untried_moves.remove(move)
                new_board = clone_board(node.board)
                new_board[move[0]][move[1]] = node.player_to_move
                next_player = HUMAN if node.player_to_move == AI else AI
                child = MCTSNode(new_board, next_player, parent=node, move=move)
                node.children.append(child)
                node = child
                self.nodes += 1
            result = self.rollout(node.board, node.player_to_move)
            while node is not None:
                node.visits += 1
                node.wins += result
                node = node.parent
        if not root.children:
            move = random.choice(available_moves(board))
            elapsed = time.perf_counter() - start
            return move, elapsed, self.nodes
        best_child = max(root.children, key=lambda child: child.visits)
        elapsed = time.perf_counter() - start
        return best_child.move, elapsed, self.nodes


class TicTacToeGUI:
    def __init__(self, master):
        self.master = master
        self.master.title("井字棋实验 - 人机博弈")
        # Windows 下更协调的默认比例（接近 16:10，同时给右侧信息栏留足空间）
        self.master.geometry("980x680")
        self.master.minsize(860, 600)
        self.master.configure(bg=BG_COLOR)

        # 视觉等比例缩放：字体、间距、控件padding会随窗口变化同步放大/缩小
        self._init_responsive_scaling()

        self.board = [[EMPTY for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]
        self.game_over = False
        self.human_total_time = 0.0
        self.ai_total_time = 0.0
        self.human_step_start = None
        self.current_algorithm = tk.StringVar(value="Alpha-Beta剪枝")
        self.first_player = tk.StringVar(value="HUMAN")  # HUMAN or AI
        self.ai_players = {
            "最小最大搜索": MinimaxAI,
            "Alpha-Beta剪枝": AlphaBetaAI,
            "MCTS蒙特卡洛树搜索": MCTSAI,
        }
        self.ai_thinking = False
        self.cell_bounds = []
        self.board_pixel_size = 0
        self.board_origin_x = 0
        self.board_origin_y = 0
        self.board_pad = 24

        self.configure_style()
        self.build_ui()
        self.center_window()
        self.reset_game()
        # 首次应用缩放（保证一打开就按当前窗口尺寸设置字体/间距）
        self._apply_responsive_scale()

    # ----------------------------
    # Responsive scaling (fonts + spacing)
    # ----------------------------
    def _init_responsive_scaling(self):
        self._base_w = 980
        self._base_h = 680
        self._scale = 1.0

        self._fz_title = 33
        self._fz_section = 21
        self._fz_body = 20
        self._fz_small = 19
        self._fz_mono = 19

        self._pad_outer = 14
        self._pad_gap_lr = 14
        self._pad_header_x = 16
        self._pad_header_top = 14
        self._pad_header_bottom = 10
        self._pad_panel_x = 14
        self._pad_panel_top = 14
        self._pad_panel_mid = 12
        self._text_pad = 10

        self.font_title = tkfont.Font(family="Microsoft YaHei", size=self._fz_title, weight="bold")
        self.font_section = tkfont.Font(family="Microsoft YaHei", size=self._fz_section, weight="bold")
        self.font_body = tkfont.Font(family="Microsoft YaHei", size=self._fz_body)
        self.font_small = tkfont.Font(family="Microsoft YaHei", size=self._fz_small)
        self.font_mono = tkfont.Font(family="Consolas", size=self._fz_mono)

        # debounce，避免拖拽窗口时疯狂刷新
        self._resize_after_id = None
        self.master.bind("<Configure>", self._on_master_configure)

    def _p(self, value: int) -> int:
        """基准像素 -> 缩放后像素，保证至少为 1。"""
        return max(int(round(value * self._scale)), 1)

    def _on_master_configure(self, _event):
        if self._resize_after_id is not None:
            try:
                self.master.after_cancel(self._resize_after_id)
            except Exception:
                pass
        self._resize_after_id = self.master.after(80, self._apply_responsive_scale)

    def _apply_responsive_scale(self):
        """根据窗口尺寸更新 scale，并应用到字体/间距/按钮 padding。"""
        w = max(self.master.winfo_width(), 1)
        h = max(self.master.winfo_height(), 1)

        raw = min(w / self._base_w, h / self._base_h)
        # 限制范围：别太离谱
        new_scale = max(0.9, min(raw, 1.30))
        if abs(new_scale - self._scale) < 0.03:
            return
        self._scale = new_scale

        # 更新字体
        self.font_title.configure(size=self._p(self._fz_title))
        self.font_section.configure(size=self._p(self._fz_section))
        self.font_body.configure(size=self._p(self._fz_body))
        self.font_small.configure(size=self._p(self._fz_small))
        self.font_mono.configure(size=self._p(self._fz_mono))

        # 更新 ttk 样式（可能在 configure_style 之后才有 self.style）
        if hasattr(self, "style"):
            try:
                self.style.configure("TCombobox", font=self.font_body)
                self.style.configure("Accent.TButton", font=self.font_body, padding=self._p(8))
                self.style.configure("Plain.TButton", font=self.font_body, padding=self._p(8))
                self.style.configure("PanelHeader.TLabel", font=self.font_section)
                self.style.configure("Body.TLabel", font=self.font_body)
                self.style.configure("Muted.TLabel", font=self.font_small)
            except Exception:
                pass

        # 更新外层 padding / 日志内边距（仅在 build_ui 后存在）
        try:
            if hasattr(self, "outer"):
                self.outer.configure(padding=self._p(self._pad_outer))
            if hasattr(self, "log"):
                self.log.configure(font=self.font_mono, padx=self._p(self._text_pad), pady=self._p(self._text_pad))
        except Exception:
            pass

    def configure_style(self):
        self.style = ttk.Style()
        style = self.style
        try:
            style.theme_use("clam")
        except Exception:
            pass
        style.configure("Root.TFrame", background=BG_COLOR)
        style.configure("Panel.TFrame", background=PANEL_BG)
        style.configure("PanelHeader.TLabel", background=PANEL_BG, foreground=TEXT_COLOR,
                        font=self.font_section)
        style.configure("Body.TLabel", background=PANEL_BG, foreground=TEXT_COLOR,
                        font=self.font_body)
        style.configure("Muted.TLabel", background=PANEL_BG, foreground=SUBTEXT_COLOR,
                        font=self.font_small)
        style.configure("TCombobox", font=self.font_body)
        style.configure("Accent.TButton", font=self.font_body, padding=self._p(8))
        style.configure("Plain.TButton", font=self.font_body, padding=self._p(8))

    def center_window(self):
        self.master.update_idletasks()
        width = self.master.winfo_width()
        height = self.master.winfo_height()
        screen_width = self.master.winfo_screenwidth()
        screen_height = self.master.winfo_screenheight()
        x = max((screen_width - width) // 2, 0)
        y = max((screen_height - height) // 2, 0)
        self.master.geometry(f"{width}x{height}+{x}+{y}")

    def build_ui(self):
        self.master.grid_rowconfigure(0, weight=1)
        self.master.grid_columnconfigure(0, weight=1)

        self.outer = ttk.Frame(self.master, style="Root.TFrame", padding=self._p(self._pad_outer))
        outer = self.outer
        outer.grid(row=0, column=0, sticky="nsew")
        outer.grid_rowconfigure(0, weight=1)
        outer.grid_columnconfigure(0, weight=1)

        self.main = ttk.Frame(outer, style="Root.TFrame")
        self.main.grid(row=0, column=0, sticky="nsew")
        self.main.grid_rowconfigure(0, weight=1)
        self.main.grid_columnconfigure(0, weight=3, uniform="main")
        self.main.grid_columnconfigure(1, weight=2, uniform="main")

        self.left_panel = tk.Frame(self.main, bg=PANEL_BG, bd=0, highlightthickness=0)
        self.left_panel.grid(row=0, column=0, sticky="nsew", padx=(0, self._p(self._pad_gap_lr)))
        self.left_panel.grid_rowconfigure(1, weight=1)
        self.left_panel.grid_columnconfigure(0, weight=1)

        self.header_frame = tk.Frame(self.left_panel, bg=PANEL_BG)
        header = self.header_frame
        header.grid(row=0, column=0, sticky="ew", padx=self._p(self._pad_header_x), pady=(self._p(self._pad_header_top), self._p(self._pad_header_bottom)))
        header.grid_columnconfigure(0, weight=1)

        title = tk.Label(header, text="井字棋人机博弈", bg=PANEL_BG, fg=TEXT_COLOR,
                         font=self.font_title)
        title.grid(row=0, column=0, sticky="w")
        subtitle = tk.Label(header, text="自适应棋盘 · 支持三种搜索算法",
                            bg=PANEL_BG, fg=SUBTEXT_COLOR, font=self.font_small)
        subtitle.grid(row=1, column=0, sticky="w", pady=(4, 0))

        board_wrapper = tk.Frame(self.left_panel, bg=PANEL_BG)
        board_wrapper.grid(row=1, column=0, sticky="nsew", padx=18, pady=10)
        board_wrapper.grid_rowconfigure(0, weight=1)
        board_wrapper.grid_columnconfigure(0, weight=1)

        self.board_canvas = tk.Canvas(
            board_wrapper,
            bg=BOARD_BG,
            highlightthickness=0,
            bd=0,
            cursor="hand2"
        )
        self.board_canvas.grid(row=0, column=0, sticky="nsew")
        self.board_canvas.bind("<Configure>", self.on_board_resize)
        self.board_canvas.bind("<Button-1>", self.on_canvas_click)

        board_tip = tk.Label(self.left_panel, text="玩家执 X，AI 执 O，点击棋盘空位即可落子。",
                             bg=PANEL_BG, fg=SUBTEXT_COLOR, font=self.font_small)
        board_tip.grid(row=2, column=0, sticky="w", padx=20, pady=(0, 18))

        # 右侧控制面板：允许随窗口伸缩（不固定 width、不禁止 propagate）
        self.right_panel = tk.Frame(self.main, bg=PANEL_BG, bd=0, highlightthickness=0)
        self.right_panel.grid(row=0, column=1, sticky="nsew")
        self.right_panel.grid_columnconfigure(0, weight=1)
        self.right_panel.grid_rowconfigure(2, weight=1)

        self.build_controls()
        self.build_info_panel()
        self.build_log_panel()

    def build_controls(self):
        self.controls_panel = tk.Frame(self.right_panel, bg=PANEL_BG)
        panel = self.controls_panel
        panel.grid(row=0, column=0, sticky="ew", padx=self._p(self._pad_panel_x), pady=(self._p(self._pad_panel_top), self._p(self._pad_panel_mid)))
        panel.grid_columnconfigure(1, weight=1)

        tk.Label(panel, text="控制面板", bg=PANEL_BG, fg=TEXT_COLOR,
                 font=self.font_section).grid(row=0, column=0, columnspan=2, sticky="w")
        tk.Label(panel, text="选择算法", bg=PANEL_BG, fg=SUBTEXT_COLOR,
                 font=self.font_small).grid(row=1, column=0, sticky="w", pady=(12, 6))

        algo_box = ttk.Combobox(
            panel,
            textvariable=self.current_algorithm,
            values=list(self.ai_players.keys()),
            state="readonly",
            width=20,
            font=self.font_body
        )
        algo_box.grid(row=2, column=0, columnspan=2, sticky="ew")
        algo_box.bind("<<ComboboxSelected>>", lambda e: self.reset_game())

        tk.Label(panel, text="先手设置", bg=PANEL_BG, fg=SUBTEXT_COLOR,
                 font=self.font_small).grid(row=3, column=0, sticky="w", pady=(12, 6))
        first_row = tk.Frame(panel, bg=PANEL_BG)
        first_row.grid(row=4, column=0, columnspan=2, sticky="ew")
        tk.Radiobutton(
            first_row, text="玩家先手（X）", variable=self.first_player, value="HUMAN",
            bg=PANEL_BG, fg=TEXT_COLOR, selectcolor=PANEL_BG,
            activebackground=PANEL_BG, font=self.font_small,
            command=self.reset_game
        ).pack(side="left", padx=(0, 10))
        tk.Radiobutton(
            first_row, text="AI先手（O）", variable=self.first_player, value="AI",
            bg=PANEL_BG, fg=TEXT_COLOR, selectcolor=PANEL_BG,
            activebackground=PANEL_BG, font=self.font_small,
            command=self.reset_game
        ).pack(side="left")

        btn_row = tk.Frame(panel, bg=PANEL_BG)
        btn_row.grid(row=5, column=0, columnspan=2, sticky="ew", pady=(14, 0))
        btn_row.grid_columnconfigure(0, weight=1)
        btn_row.grid_columnconfigure(1, weight=1)

        ttk.Button(btn_row, text="重新开始", style="Accent.TButton", command=self.reset_game).grid(
            row=0, column=0, sticky="ew", padx=(0, 6)
        )
        ttk.Button(btn_row, text="规则说明", style="Plain.TButton", command=self.show_rules).grid(
            row=0, column=1, sticky="ew", padx=(6, 0)
        )

    def build_info_panel(self):
        self.info_panel = tk.Frame(self.right_panel, bg=PANEL_BG)
        panel = self.info_panel
        panel.grid(row=1, column=0, sticky="ew", padx=self._p(self._pad_panel_x), pady=(0, self._p(self._pad_panel_mid)))
        panel.grid_columnconfigure(0, weight=1)

        tk.Label(panel, text="运行信息", bg=PANEL_BG, fg=TEXT_COLOR,
                 font=self.font_section).grid(row=0, column=0, sticky="w")

        self.status_var = tk.StringVar()
        self.human_time_var = tk.StringVar()
        self.ai_time_var = tk.StringVar()
        self.step_time_var = tk.StringVar()
        self.node_var = tk.StringVar()
        self.eval_var = tk.StringVar()

        for idx, var in enumerate([
            self.status_var,
            self.human_time_var,
            self.ai_time_var,
            self.step_time_var,
            self.node_var,
            self.eval_var,
        ], start=1):
            tk.Label(panel, textvariable=var, bg=PANEL_BG, fg=TEXT_COLOR,
                     anchor="w", justify="left", font=self.font_small).grid(
                row=idx, column=0, sticky="ew", pady=(8 if idx == 1 else 6, 0)
            )

    def build_log_panel(self):
        self.log_panel = tk.Frame(self.right_panel, bg=PANEL_BG)
        panel = self.log_panel
        panel.grid(row=2, column=0, sticky="nsew", padx=self._p(self._pad_panel_x), pady=(0, self._p(self._pad_panel_top)))
        panel.grid_rowconfigure(1, weight=1)
        panel.grid_columnconfigure(0, weight=1)

        tk.Label(panel, text="对局日志", bg=PANEL_BG, fg=TEXT_COLOR,
                 font=self.font_section).grid(row=0, column=0, sticky="w")

        self.log = tk.Text(
            panel,
            wrap="word",
            bd=0,
            relief="flat",
            font=self.font_mono,
            bg="#f8fafc",
            fg=TEXT_COLOR,
            insertbackground=TEXT_COLOR,
            padx=self._p(self._text_pad),
            pady=self._p(self._text_pad)
        )
        self.log.grid(row=1, column=0, sticky="nsew", pady=(10, 0))

        scrollbar = ttk.Scrollbar(panel, orient="vertical", command=self.log.yview)
        scrollbar.grid(row=1, column=1, sticky="ns", pady=(10, 0))
        self.log.configure(yscrollcommand=scrollbar.set, state="disabled")

    def log_message(self, text):
        self.log.config(state="normal")
        self.log.insert("end", text + "\n")
        self.log.see("end")
        self.log.config(state="disabled")

    def show_rules(self):
        messagebox.showinfo(
            "规则说明",
            "玩家执 X，AI 执 O。\n"
            "先形成任意一条三连线（横、竖、斜）的一方获胜。\n"
            "界面会显示每一步耗时、总耗时和搜索节点数。\n"
            "可选择 AI 先手（O）或玩家先手（X）。\n"
            "棋盘会随窗口尺寸自适应缩放，并保持正方形比例。"
        )

    def evaluate_board_heuristic(self):
        """返回当前局面对 AI（O）有利程度：正数偏向 AI，负数偏向玩家。

        说明：
        - 终局：AI胜=+1，玩家胜=-1，平局=0
        - 非终局：统计每条潜在连线的“只含一方棋子”的数量，作为启发式评价。
        """
        result = check_winner(self.board)
        if result == AI:
            return 1.0
        if result == HUMAN:
            return -1.0
        if result == "Draw":
            return 0.0

        lines = []
        lines.extend(self.board)
        lines.extend([[self.board[r][c] for r in range(BOARD_SIZE)] for c in range(BOARD_SIZE)])
        lines.append([self.board[i][i] for i in range(BOARD_SIZE)])
        lines.append([self.board[i][BOARD_SIZE - 1 - i] for i in range(BOARD_SIZE)])

        score = 0.0
        for line in lines:
            if AI in line and HUMAN in line:
                continue
            ai_cnt = sum(1 for x in line if x == AI)
            hu_cnt = sum(1 for x in line if x == HUMAN)
            if ai_cnt > 0:
                score += ai_cnt / 3.0
            elif hu_cnt > 0:
                score -= hu_cnt / 3.0
        # 归一化到大致 [-1, 1]
        return max(min(score / 4.0, 1.0), -1.0)

    def refresh_eval_display(self):
        v = self.evaluate_board_heuristic()
        self.eval_var.set(f"当前棋盘评估值（启发式，AI/O视角）：{v:+.3f}")

    def reset_game(self):
        self.board = [[EMPTY for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]
        self.game_over = False
        self.ai_thinking = False
        self.human_total_time = 0.0
        self.ai_total_time = 0.0
        self.human_step_start = None
        self.log.config(state="normal")
        self.log.delete("1.0", "end")
        self.log.config(state="disabled")
        if self.first_player.get() == "AI":
            self.status_var.set(f"当前算法：{self.current_algorithm.get()} | AI先手（O）")
        else:
            self.status_var.set(f"当前算法：{self.current_algorithm.get()} | 轮到玩家 X")
        self.human_time_var.set("玩家累计时间：0.000000 秒")
        self.ai_time_var.set("AI累计时间：0.000000 秒")
        self.step_time_var.set("最近一步耗时：0.000000 秒")
        self.node_var.set("最近一次搜索节点数：0")
        self.refresh_eval_display()
        self.log_message("新对局开始。")
        self.draw_board()

        # 处理 AI 先手
        if self.first_player.get() == "AI":
            self.status_var.set("AI 思考中...")
            self.ai_thinking = True
            self.master.update_idletasks()
            self.master.after(80, self.ai_move)
        else:
            self.human_step_start = time.perf_counter()

    def on_board_resize(self, event=None):
        self.draw_board()

    def compute_layout(self):
        width = max(self.board_canvas.winfo_width(), 1)
        height = max(self.board_canvas.winfo_height(), 1)
        usable = max(min(width, height) - self.board_pad * 2, 60)
        self.board_pixel_size = usable
        self.board_origin_x = (width - usable) / 2
        self.board_origin_y = (height - usable) / 2
        cell = usable / BOARD_SIZE
        self.cell_bounds = []
        for r in range(BOARD_SIZE):
            row = []
            for c in range(BOARD_SIZE):
                x1 = self.board_origin_x + c * cell
                y1 = self.board_origin_y + r * cell
                x2 = x1 + cell
                y2 = y1 + cell
                row.append((x1, y1, x2, y2))
            self.cell_bounds.append(row)
        return cell

    def draw_board(self):
        self.board_canvas.delete("all")
        cell = self.compute_layout()
        x0 = self.board_origin_x
        y0 = self.board_origin_y
        size = self.board_pixel_size
        x1 = x0 + size
        y1 = y0 + size

        shadow_offset = 4
        self.board_canvas.create_rectangle(
            x0 + shadow_offset, y0 + shadow_offset, x1 + shadow_offset, y1 + shadow_offset,
            fill="#dbe4f0", outline=""
        )
        self.board_canvas.create_rectangle(
            x0, y0, x1, y1,
            fill=BOARD_BG, outline="#d7dee9", width=1
        )

        line_width = max(3, int(cell * 0.04))
        for i in range(1, BOARD_SIZE):
            pos = x0 + i * cell
            self.board_canvas.create_line(pos, y0, pos, y1, fill=GRID_COLOR, width=line_width)
            pos = y0 + i * cell
            self.board_canvas.create_line(x0, pos, x1, pos, fill=GRID_COLOR, width=line_width)

        font_size = max(28, int(cell * 0.42))
        for r in range(BOARD_SIZE):
            for c in range(BOARD_SIZE):
                mark = self.board[r][c]
                if mark == EMPTY:
                    continue
                cx = (self.cell_bounds[r][c][0] + self.cell_bounds[r][c][2]) / 2
                cy = (self.cell_bounds[r][c][1] + self.cell_bounds[r][c][3]) / 2
                color = X_COLOR if mark == HUMAN else O_COLOR
                self.board_canvas.create_text(
                    cx,
                    cy,
                    text=mark,
                    fill=color,
                    font=("Arial", font_size, "bold")
                )

    def on_canvas_click(self, event):
        if self.game_over or self.ai_thinking:
            return
        row, col = self.locate_cell(event.x, event.y)
        if row is None or col is None:
            return
        self.human_move(row, col)

    def locate_cell(self, x, y):
        for r in range(BOARD_SIZE):
            for c in range(BOARD_SIZE):
                x1, y1, x2, y2 = self.cell_bounds[r][c]
                if x1 <= x <= x2 and y1 <= y <= y2:
                    return r, c
        return None, None

    def end_game(self, result):
        self.game_over = True
        self.refresh_eval_display()
        if result == "Draw":
            self.status_var.set("对局结束：平局")
            self.log_message("对局结果：平局。")
        else:
            self.status_var.set(f"对局结束：{result} 获胜")
            self.log_message(f"对局结果：{result} 获胜。")

    def human_move(self, r, c):
        if self.game_over or self.board[r][c] != EMPTY:
            return
        now = time.perf_counter()
        step_time = now - self.human_step_start if self.human_step_start else 0.0
        self.human_total_time += step_time
        self.board[r][c] = HUMAN
        self.draw_board()
        self.refresh_eval_display()
        self.human_time_var.set(f"玩家累计时间：{self.human_total_time:.6f} 秒")
        self.step_time_var.set(f"最近一步耗时：{step_time:.6f} 秒（玩家）")
        self.log_message(f"玩家落子：({r + 1}, {c + 1})，耗时 {step_time:.6f} 秒")

        result = check_winner(self.board)
        if result is not None:
            self.end_game(result)
            return

        self.status_var.set("AI 思考中...")
        self.master.update_idletasks()
        self.master.after(50, self.ai_move)

    def ai_move(self):
        if self.game_over:
            return
        self.ai_thinking = True
        ai_class = self.ai_players[self.current_algorithm.get()]
        ai = ai_class()
        move, elapsed, nodes = ai.choose_move(self.board)
        if move is None:
            self.end_game("Draw")
            self.ai_thinking = False
            return
        self.board[move[0]][move[1]] = AI
        self.ai_total_time += elapsed
        self.draw_board()
        self.refresh_eval_display()
        self.ai_time_var.set(f"AI累计时间：{self.ai_total_time:.6f} 秒")
        self.step_time_var.set(f"最近一步耗时：{elapsed:.6f} 秒（AI）")
        self.node_var.set(f"最近一次搜索节点数：{nodes}")
        self.log_message(
            f"AI落子：({move[0] + 1}, {move[1] + 1})，耗时 {elapsed:.6f} 秒，搜索节点 {nodes}"
        )

        result = check_winner(self.board)
        if result is not None:
            self.end_game(result)
            self.ai_thinking = False
            return
        self.status_var.set(f"当前算法：{self.current_algorithm.get()} | 轮到玩家 X")
        self.human_step_start = time.perf_counter()
        self.ai_thinking = False


if __name__ == "__main__":
    random.seed()
    root = tk.Tk()
    try:
        from ctypes import windll
        windll.shcore.SetProcessDpiAwareness(1)
    except Exception:
        pass
    app = TicTacToeGUI(root)
    root.mainloop()
