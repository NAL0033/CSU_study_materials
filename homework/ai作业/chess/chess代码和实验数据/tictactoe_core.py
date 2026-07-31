import math
import random
import time
from dataclasses import dataclass

BOARD_SIZE = 3
EMPTY = ""
HUMAN = "X"
AI = "O"


def create_empty_board():
    return [[EMPTY for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]


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
    priority = [
        (1, 1),
        (0, 0), (0, 2), (2, 0), (2, 2),
        (0, 1), (1, 0), (1, 2), (2, 1)
    ]
    return [move for move in priority if board[move[0]][move[1]] == EMPTY]


def board_to_tuple(board):
    return tuple(tuple(row) for row in board)


def other_player(player):
    return HUMAN if player == AI else AI


def find_winning_move(board, player):
    for r, c in available_moves(board):
        board[r][c] = player
        if check_winner(board) == player:
            board[r][c] = EMPTY
            return (r, c)
        board[r][c] = EMPTY
    return None


def evaluate_board_heuristic(board):
    """
    返回当前局面对 AI（O）有利程度：正数偏向 AI，负数偏向玩家。
    """
    result = check_winner(board)
    if result == AI:
        return 1.0
    if result == HUMAN:
        return -1.0
    if result == "Draw":
        return 0.0

    lines = []
    lines.extend(board)
    lines.extend([[board[r][c] for r in range(BOARD_SIZE)] for c in range(BOARD_SIZE)])
    lines.append([board[i][i] for i in range(BOARD_SIZE)])
    lines.append([board[i][BOARD_SIZE - 1 - i] for i in range(BOARD_SIZE)])

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
    return max(min(score / 4.0, 1.0), -1.0)


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
        key = (board_to_tuple(board), is_maximizing, depth)
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
    parent: "MCTSNode" = None
    move: tuple = None
    wins: float = 0.0
    visits: int = 0
    children: list = None
    untried_moves: list = None

    def __post_init__(self):
        if self.children is None:
            self.children = []
        if self.untried_moves is None:
            self.untried_moves = ordered_moves(self.board)

    def uct_score(self, total_visits, c=1.414):
        if self.visits == 0:
            return float("inf")
        exploit = self.wins / self.visits
        explore = c * math.sqrt(math.log(max(total_visits, 1)) / self.visits)
        return exploit + explore


class MCTSAI:
    name = "MCTS蒙特卡洛树搜索"

    def __init__(self, iterations=3000, exploration=1.414):
        self.iterations = iterations
        self.exploration = exploration
        self.nodes = 0

    def other_player(self, player):
        return HUMAN if player == AI else AI

    def find_winning_move(self, board, player):
        return find_winning_move(board, player)

    def rollout_policy_move(self, board, player):
        move = self.find_winning_move(board, player)
        if move is not None:
            return move

        opp = self.other_player(player)
        move = self.find_winning_move(board, opp)
        if move is not None:
            return move

        moves = ordered_moves(board)
        if moves:
            return moves[0]

        av = available_moves(board)
        return random.choice(av) if av else None

    def rollout(self, board, player):
        sim_board = clone_board(board)
        current = player

        while True:
            result = check_winner(sim_board)
            if result is not None:
                if result == AI:
                    return 1.0
                if result == HUMAN:
                    return 0.0
                return 0.5

            move = self.rollout_policy_move(sim_board, current)
            if move is None:
                return 0.5

            sim_board[move[0]][move[1]] = current
            current = self.other_player(current)

    def select_child(self, node):
        if node.player_to_move == AI:
            return max(
                node.children,
                key=lambda child: child.uct_score(node.visits, self.exploration)
            )
        return min(
            node.children,
            key=lambda child: child.uct_score(node.visits, self.exploration)
        )

    def expand(self, node):
        if not node.untried_moves:
            return node

        win_move = self.find_winning_move(node.board, node.player_to_move)
        if win_move is not None and win_move in node.untried_moves:
            node.untried_moves.remove(win_move)
            move = win_move
        else:
            opp = self.other_player(node.player_to_move)
            block_move = self.find_winning_move(node.board, opp)
            if block_move is not None and block_move in node.untried_moves:
                node.untried_moves.remove(block_move)
                move = block_move
            else:
                move = node.untried_moves.pop(0)

        new_board = clone_board(node.board)
        new_board[move[0]][move[1]] = node.player_to_move
        next_player = self.other_player(node.player_to_move)

        child = MCTSNode(
            board=new_board,
            player_to_move=next_player,
            parent=node,
            move=move
        )
        node.children.append(child)
        self.nodes += 1
        return child

    def backpropagate(self, node, result):
        while node is not None:
            node.visits += 1
            node.wins += result
            node = node.parent

    def choose_move(self, board):
        self.nodes = 0
        start = time.perf_counter()

        if not available_moves(board):
            elapsed = time.perf_counter() - start
            return None, elapsed, self.nodes

        win_move = self.find_winning_move(board, AI)
        if win_move is not None:
            elapsed = time.perf_counter() - start
            return win_move, elapsed, self.nodes

        block_move = self.find_winning_move(board, HUMAN)
        if block_move is not None:
            elapsed = time.perf_counter() - start
            return block_move, elapsed, self.nodes

        root = MCTSNode(clone_board(board), AI)

        for _ in range(self.iterations):
            node = root

            while not node.untried_moves and node.children:
                node = self.select_child(node)

            if node.untried_moves:
                node = self.expand(node)

            result = self.rollout(node.board, node.player_to_move)
            self.backpropagate(node, result)

        if not root.children:
            moves = ordered_moves(board)
            move = moves[0] if moves else None
            elapsed = time.perf_counter() - start
            return move, elapsed, self.nodes

        for child in root.children:
            if check_winner(child.board) == AI:
                elapsed = time.perf_counter() - start
                return child.move, elapsed, self.nodes

        best_child = max(
            root.children,
            key=lambda child: (child.wins / child.visits, child.visits)
        )

        elapsed = time.perf_counter() - start
        return best_child.move, elapsed, self.nodes


def evaluate_position(player, board):
    move, elapsed, nodes = player.choose_move(clone_board(board))
    return {
        "move": move,
        "elapsed": elapsed,
        "nodes": nodes
    }


def play_game(player_x, player_o, start_board=None, first_player=HUMAN):
    """
    非 GUI 对局引擎。
    player_x / player_o 都需要提供 choose_move(board) -> (move, elapsed, nodes)
    """
    board = clone_board(start_board) if start_board is not None else create_empty_board()
    current = first_player

    x_total_time = 0.0
    o_total_time = 0.0
    x_total_nodes = 0
    o_total_nodes = 0
    move_count = 0
    history = []

    while True:
        result = check_winner(board)
        if result is not None:
            return {
                "winner": result,
                "move_count": move_count,
                "x_total_time": x_total_time,
                "o_total_time": o_total_time,
                "x_total_nodes": x_total_nodes,
                "o_total_nodes": o_total_nodes,
                "history": history,
                "final_board": clone_board(board),
            }

        if current == HUMAN:
            move, elapsed, nodes = player_x.choose_move(clone_board(board))
            if move is None:
                return {
                    "winner": "Draw",
                    "move_count": move_count,
                    "x_total_time": x_total_time,
                    "o_total_time": o_total_time,
                    "x_total_nodes": x_total_nodes,
                    "o_total_nodes": o_total_nodes,
                    "history": history,
                    "final_board": clone_board(board),
                }
            board[move[0]][move[1]] = HUMAN
            x_total_time += elapsed
            x_total_nodes += nodes
            history.append(("X", move, elapsed, nodes))
            current = AI
        else:
            move, elapsed, nodes = player_o.choose_move(clone_board(board))
            if move is None:
                return {
                    "winner": "Draw",
                    "move_count": move_count,
                    "x_total_time": x_total_time,
                    "o_total_time": o_total_time,
                    "x_total_nodes": x_total_nodes,
                    "o_total_nodes": o_total_nodes,
                    "history": history,
                    "final_board": clone_board(board),
                }
            board[move[0]][move[1]] = AI
            o_total_time += elapsed
            o_total_nodes += nodes
            history.append(("O", move, elapsed, nodes))
            current = HUMAN

        move_count += 1