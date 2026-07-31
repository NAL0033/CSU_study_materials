import csv
import os
import random
import time
import statistics

from tictactoe_core import (
    EMPTY,
    HUMAN,
    AI,
    create_empty_board,
    clone_board,
    check_winner,
    available_moves,
    ordered_moves,
    find_winning_move,
    evaluate_position,
    play_game,
    MinimaxAI,
    AlphaBetaAI,
    MCTSAI,
)


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RESULT_DIR = os.path.join(BASE_DIR, "results")

class RandomPlayer:
    name = "随机玩家"

    def choose_move(self, board):
        start = time.perf_counter()
        moves = available_moves(board)
        move = random.choice(moves) if moves else None
        elapsed = time.perf_counter() - start
        return move, elapsed, 0


class HeuristicPlayer:
    name = "启发式玩家"

    def choose_move(self, board):
        start = time.perf_counter()

        # 自己一步能赢就先赢
        move = find_winning_move(board, HUMAN)

        # 对手一步能赢就堵
        if move is None:
            move = find_winning_move(board, AI)

        # 否则按中心-角-边顺序
        if move is None:
            moves = ordered_moves(board)
            move = moves[0] if moves else None

        elapsed = time.perf_counter() - start
        return move, elapsed, 0


def ensure_result_dir():
    os.makedirs(RESULT_DIR, exist_ok=True)


def board_to_str(board):
    return "/".join("".join(cell if cell else "-" for cell in row) for row in board)


def save_csv(filename, rows):
    ensure_result_dir()
    path = os.path.join(RESULT_DIR, filename)

    if not rows:
        with open(path, "w", newline="", encoding="utf-8-sig") as f:
            f.write("")
        return path

    fieldnames = list(rows[0].keys())
    with open(path, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    return path


def summarize_matchup(rows):
    total = len(rows)
    x_win = sum(1 for r in rows if r["winner"] == "X")
    o_win = sum(1 for r in rows if r["winner"] == "O")
    draw = sum(1 for r in rows if r["winner"] == "Draw")

    avg_moves = sum(r["move_count"] for r in rows) / total if total else 0.0
    avg_ai_time = sum(r["ai_total_time_sec"] for r in rows) / total if total else 0.0
    avg_ai_nodes = sum(r["ai_total_nodes"] for r in rows) / total if total else 0.0

    return {
        "games": total,
        "x_win": x_win,
        "o_win": o_win,
        "draw": draw,
        "x_win_rate": x_win / total if total else 0.0,
        "o_win_rate": o_win / total if total else 0.0,
        "draw_rate": draw / total if total else 0.0,
        "avg_moves": avg_moves,
        "avg_ai_time_sec": avg_ai_time,
        "avg_ai_time_ms": avg_ai_time * 1000,
        "avg_ai_nodes": avg_ai_nodes,
    }


def get_ai_factory(name, mcts_iterations=3000):
    if name == "最小最大搜索":
        return MinimaxAI
    if name == "Alpha-Beta剪枝":
        return AlphaBetaAI
    if name == "MCTS蒙特卡洛树搜索":
        return lambda: MCTSAI(iterations=mcts_iterations)
    raise ValueError(f"未知算法: {name}")


def run_fixed_position_tests(repeats=10):
    """
    实验1：固定局面测试
    对每个固定局面，重复运行三种AI，记录推荐落子、耗时、节点数。
    """
    positions = [
        {
            "position_name": "空棋盘",
            "board": create_empty_board(),
        },
        {
            "position_name": "中局普通局面",
            "board": [
                [HUMAN, AI, EMPTY],
                [EMPTY, HUMAN, EMPTY],
                [AI, EMPTY, EMPTY],
            ],
        },
        {
            "position_name": "AI一步可胜",
            "board": [
                [AI, AI, EMPTY],
                [HUMAN, HUMAN, EMPTY],
                [EMPTY, EMPTY, EMPTY],
            ],
        },
        {
            "position_name": "玩家一步可胜_必须防守",
            "board": [
                [HUMAN, HUMAN, EMPTY],
                [AI, EMPTY, EMPTY],
                [EMPTY, AI, EMPTY],
            ],
        },
        {
            "position_name": "接近终局",
            "board": [
                [HUMAN, AI, HUMAN],
                [AI, HUMAN, EMPTY],
                [EMPTY, EMPTY, AI],
            ],
        },
    ]

    algorithms = [
        ("最小最大搜索", lambda: MinimaxAI()),
        ("Alpha-Beta剪枝", lambda: AlphaBetaAI()),
        ("MCTS蒙特卡洛树搜索", lambda: MCTSAI(iterations=3000)),
    ]

    detail_rows = []
    summary_rows = []

    for pos in positions:
        for algo_name, factory in algorithms:
            elapsed_list = []
            nodes_list = []
            move_list = []

            for i in range(repeats):
                player = factory()
                result = evaluate_position(player, clone_board(pos["board"]))
                move = result["move"]
                elapsed = result["elapsed"]
                nodes = result["nodes"]

                elapsed_list.append(elapsed)
                nodes_list.append(nodes)
                move_list.append(str(move))

                detail_rows.append({
                    "position_name": pos["position_name"],
                    "algorithm": algo_name,
                    "run_index": i + 1,
                    "board": board_to_str(pos["board"]),
                    "recommended_move": str(move),
                    "elapsed_sec": elapsed,
                    "elapsed_ms": elapsed * 1000,
                    "nodes": nodes,
                })

            most_common_move = max(set(move_list), key=move_list.count) if move_list else "None"

            summary_rows.append({
                "position_name": pos["position_name"],
                "algorithm": algo_name,
                "board": board_to_str(pos["board"]),
                "recommended_move_sample": most_common_move,
                "avg_elapsed_sec": sum(elapsed_list) / len(elapsed_list) if elapsed_list else 0.0,
                "avg_elapsed_ms": (sum(elapsed_list) / len(elapsed_list) * 1000) if elapsed_list else 0.0,
                "avg_nodes": sum(nodes_list) / len(nodes_list) if nodes_list else 0.0,
            })

    save_csv("fixed_positions_detail.csv", detail_rows)
    save_csv("fixed_positions_summary.csv", summary_rows)
    return summary_rows


def run_matchup(player_x_factory, player_o_factory, n_games=50, first_player=HUMAN):
    """
    运行一组对局：
    X = 模拟玩家
    O = AI
    只把 AI 的时间和节点作为核心分析对象
    """
    rows = []

    for game_idx in range(n_games):
        x_player = player_x_factory()
        o_player = player_o_factory()
        result = play_game(x_player, o_player, first_player=first_player)

        rows.append({
            "game_index": game_idx + 1,
            "winner": result["winner"],
            "move_count": result["move_count"],
            "x_total_time_sec": result["x_total_time"],
            "ai_total_time_sec": result["o_total_time"],
            "x_total_nodes": result["x_total_nodes"],
            "ai_total_nodes": result["o_total_nodes"],
            "final_board": board_to_str(result["final_board"]),
        })

    return rows


def run_random_player_vs_ai_experiments(n_games=100):
    """
    实验2：随机玩家 vs 三种AI
    """
    human_name = "随机玩家"
    human_factory = RandomPlayer

    ai_algorithms = [
        "最小最大搜索",
        "Alpha-Beta剪枝",
        "MCTS蒙特卡洛树搜索",
    ]

    summary_rows = []

    for ai_name in ai_algorithms:
        ai_factory = get_ai_factory(ai_name, mcts_iterations=3000)
        detail_rows = run_matchup(human_factory, ai_factory, n_games=n_games, first_player=HUMAN)
        summary = summarize_matchup(detail_rows)

        summary_row = {
            "human_player": human_name,
            "ai_algorithm": ai_name,
            "games": summary["games"],
            "x_win": summary["x_win"],
            "o_win": summary["o_win"],
            "draw": summary["draw"],
            "x_win_rate": summary["x_win_rate"],
            "o_win_rate": summary["o_win_rate"],
            "draw_rate": summary["draw_rate"],
            "avg_moves": summary["avg_moves"],
            "avg_ai_time_sec": summary["avg_ai_time_sec"],
            "avg_ai_time_ms": summary["avg_ai_time_ms"],
            "avg_ai_nodes": summary["avg_ai_nodes"],
        }
        summary_rows.append(summary_row)

        filename = f"random_vs_{ai_name}.csv".replace("/", "_")
        save_csv(filename, detail_rows)

    save_csv("random_player_vs_ai_summary.csv", summary_rows)
    return summary_rows


def run_heuristic_player_vs_ai_experiments(n_games=100):
    """
    实验3：启发式玩家 vs 三种AI
    """
    human_name = "启发式玩家"
    human_factory = HeuristicPlayer

    ai_algorithms = [
        "最小最大搜索",
        "Alpha-Beta剪枝",
        "MCTS蒙特卡洛树搜索",
    ]

    summary_rows = []

    for ai_name in ai_algorithms:
        ai_factory = get_ai_factory(ai_name, mcts_iterations=3000)
        detail_rows = run_matchup(human_factory, ai_factory, n_games=n_games, first_player=HUMAN)
        summary = summarize_matchup(detail_rows)

        summary_row = {
            "human_player": human_name,
            "ai_algorithm": ai_name,
            "games": summary["games"],
            "x_win": summary["x_win"],
            "o_win": summary["o_win"],
            "draw": summary["draw"],
            "x_win_rate": summary["x_win_rate"],
            "o_win_rate": summary["o_win_rate"],
            "draw_rate": summary["draw_rate"],
            "avg_moves": summary["avg_moves"],
            "avg_ai_time_sec": summary["avg_ai_time_sec"],
            "avg_ai_time_ms": summary["avg_ai_time_ms"],
            "avg_ai_nodes": summary["avg_ai_nodes"],
        }
        summary_rows.append(summary_row)

        filename = f"heuristic_vs_{ai_name}.csv".replace("/", "_")
        save_csv(filename, detail_rows)

    save_csv("heuristic_player_vs_ai_summary.csv", summary_rows)
    return summary_rows


def run_mcts_parameter_experiments(n_games=50, iterations_list=None):
    """
    实验4：MCTS 参数实验
    固定对手为启发式玩家，考察不同 iterations 的影响。
    """
    if iterations_list is None:
        iterations_list = [500, 1000, 2000, 3000, 5000]

    summary_rows = []

    for iters in iterations_list:
        ai_factory = lambda: MCTSAI(iterations=iters)
        detail_rows = run_matchup(HeuristicPlayer, ai_factory, n_games=n_games, first_player=HUMAN)
        summary = summarize_matchup(detail_rows)

        summary_rows.append({
            "iterations": iters,
            "games": summary["games"],
            "x_win": summary["x_win"],
            "o_win": summary["o_win"],
            "draw": summary["draw"],
            "x_win_rate": summary["x_win_rate"],
            "o_win_rate": summary["o_win_rate"],
            "draw_rate": summary["draw_rate"],
            "avg_moves": summary["avg_moves"],
            "avg_ai_time_sec": summary["avg_ai_time_sec"],
            "avg_ai_time_ms": summary["avg_ai_time_ms"],
            "avg_ai_nodes": summary["avg_ai_nodes"],
        })

        save_csv(f"mcts_iterations_{iters}.csv", detail_rows)

    save_csv("mcts_parameter_summary.csv", summary_rows)
    return summary_rows


def print_rows(title, rows):
    print(f"\n===== {title} =====")
    for row in rows:
        print(row)

# def run_mcts_parameter_experiments_vs_random(n_games=100, iterations_list=None):
#     """
#     补充实验：随机玩家对手下的 MCTS 参数实验
#     固定对手为随机玩家，考察不同 iterations 对胜率、时间、节点数的影响。
#     """
#     if iterations_list is None:
#         iterations_list = [500, 1000, 2000, 3000, 5000]

#     summary_rows = []

#     for iters in iterations_list:
#         ai_factory = lambda: MCTSAI(iterations=iters)
#         detail_rows = run_matchup(RandomPlayer, ai_factory, n_games=n_games, first_player=HUMAN)
#         summary = summarize_matchup(detail_rows)

#         summary_rows.append({
#             "opponent": "随机玩家",
#             "iterations": iters,
#             "games": summary["games"],
#             "x_win": summary["x_win"],
#             "o_win": summary["o_win"],
#             "draw": summary["draw"],
#             "x_win_rate": summary["x_win_rate"],
#             "o_win_rate": summary["o_win_rate"],
#             "draw_rate": summary["draw_rate"],
#             "avg_moves": summary["avg_moves"],
#             "avg_ai_time_sec": summary["avg_ai_time_sec"],
#             "avg_ai_time_ms": summary["avg_ai_time_ms"],
#             "avg_ai_nodes": summary["avg_ai_nodes"],
#         })

#         save_csv(f"mcts_iterations_random_{iters}.csv", detail_rows)

#     save_csv("mcts_parameter_random_summary.csv", summary_rows)
#     return summary_rows

def run_mcts_parameter_experiments_vs_random_repeated(
    games_per_repeat=100,
    repeats=10,
    iterations_list=None,
    base_seed=2025
):
    """
    补充实验：随机玩家对手下的 MCTS 参数实验（多轮重复版）
    固定对手为随机玩家，考察不同 iterations 对胜率、时间、节点数的影响。
    每个参数做多轮独立重复实验，并输出均值和标准差。
    """
    if iterations_list is None:
        iterations_list = [500, 1000, 2000, 3000, 5000]

    summary_rows = []

    for iters in iterations_list:
        repeat_rows = []

        for repeat_idx in range(repeats):
            seed = base_seed + iters * 100 + repeat_idx
            random.seed(seed)

            ai_factory = lambda: MCTSAI(iterations=iters)
            detail_rows = run_matchup(
                RandomPlayer,
                ai_factory,
                n_games=games_per_repeat,
                first_player=HUMAN
            )
            summary = summarize_matchup(detail_rows)

            repeat_row = {
                "opponent": "随机玩家",
                "iterations": iters,
                "repeat_index": repeat_idx + 1,
                "seed": seed,
                "games": summary["games"],
                "x_win": summary["x_win"],
                "o_win": summary["o_win"],
                "draw": summary["draw"],
                "x_win_rate": summary["x_win_rate"],
                "o_win_rate": summary["o_win_rate"],
                "draw_rate": summary["draw_rate"],
                "avg_moves": summary["avg_moves"],
                "avg_ai_time_sec": summary["avg_ai_time_sec"],
                "avg_ai_time_ms": summary["avg_ai_time_ms"],
                "avg_ai_nodes": summary["avg_ai_nodes"],
            }
            repeat_rows.append(repeat_row)

            save_csv(
                f"mcts_random_iters_{iters}_repeat_{repeat_idx + 1}.csv",
                detail_rows
            )

        win_rates = [r["o_win_rate"] for r in repeat_rows]
        draw_rates = [r["draw_rate"] for r in repeat_rows]
        lose_rates = [r["x_win_rate"] for r in repeat_rows]
        avg_moves_list = [r["avg_moves"] for r in repeat_rows]
        avg_time_ms_list = [r["avg_ai_time_ms"] for r in repeat_rows]
        avg_nodes_list = [r["avg_ai_nodes"] for r in repeat_rows]

        summary_rows.append({
            "opponent": "随机玩家",
            "iterations": iters,
            "repeats": repeats,
            "games_per_repeat": games_per_repeat,
            "total_games": repeats * games_per_repeat,

            "mean_o_win_rate": statistics.mean(win_rates),
            "std_o_win_rate": statistics.stdev(win_rates) if len(win_rates) > 1 else 0.0,

            "mean_draw_rate": statistics.mean(draw_rates),
            "std_draw_rate": statistics.stdev(draw_rates) if len(draw_rates) > 1 else 0.0,

            "mean_x_win_rate": statistics.mean(lose_rates),
            "std_x_win_rate": statistics.stdev(lose_rates) if len(lose_rates) > 1 else 0.0,

            "mean_avg_moves": statistics.mean(avg_moves_list),
            "std_avg_moves": statistics.stdev(avg_moves_list) if len(avg_moves_list) > 1 else 0.0,

            "mean_ai_time_ms": statistics.mean(avg_time_ms_list),
            "std_ai_time_ms": statistics.stdev(avg_time_ms_list) if len(avg_time_ms_list) > 1 else 0.0,

            "mean_ai_nodes": statistics.mean(avg_nodes_list),
            "std_ai_nodes": statistics.stdev(avg_nodes_list) if len(avg_nodes_list) > 1 else 0.0,
        })

        save_csv(f"mcts_random_iters_{iters}_repeat_summary.csv", repeat_rows)

    save_csv("mcts_parameter_random_repeated_summary.csv", summary_rows)
    return summary_rows


def main():
    random.seed(42)

    # fixed_summary = run_fixed_position_tests(repeats=10)
    # print_rows("实验1：固定局面测试汇总", fixed_summary)

    # random_summary = run_random_player_vs_ai_experiments(n_games=100)
    # print_rows("实验2：随机玩家 vs AI 汇总", random_summary)

    # heuristic_summary = run_heuristic_player_vs_ai_experiments(n_games=100)
    # print_rows("实验3：启发式玩家 vs AI 汇总", heuristic_summary)

    # mcts_param_summary = run_mcts_parameter_experiments(
    #     n_games=50,
    #     iterations_list=[500, 1000, 2000, 3000, 5000]
    # )
    # print_rows("实验4：MCTS参数实验汇总", mcts_param_summary)


    # mcts_param_random_summary = run_mcts_parameter_experiments_vs_random(
    #     n_games=100,
    #     iterations_list=[500, 1000, 2000, 3000, 5000]
    # )
    # print_rows("补充实验：随机玩家下MCTS参数实验汇总", mcts_param_random_summary)

    mcts_param_random_summary = run_mcts_parameter_experiments_vs_random_repeated(
        games_per_repeat=100,
        repeats=10,
        iterations_list=[500, 1000, 2000, 3000, 5000],
        base_seed=2025
    )
    print_rows("补充实验：随机玩家下MCTS参数实验汇总（多轮重复）", mcts_param_random_summary)

    print("\n实验完成，CSV 文件已输出到 results/ 目录。")


if __name__ == "__main__":
    main()