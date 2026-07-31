/*
 * 算术表达式计算器 —— 支持加减乘除和括号的四则运算，带历史记录与分页查看功能
 * gcc -S -O0 calculator_full.c -o calculator_full.s
 * 编译：gcc calculator_full.c -o calculator_full.exe
 * 运行：calculator_full.exe
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#ifdef _WIN32
#include <conio.h>
#else
#include <termios.h>
#include <unistd.h>
#endif

#define MAX_HISTORY 100
#define MAX_EXPR 512
#define PAGE_SIZE 10

#define CALC_OK 1
#define CALC_ERR 0

/* 历史记录：表达式字符串及其计算结果 */
typedef struct {
    char expr[MAX_EXPR];
    double result;
} History;

static History history[MAX_HISTORY];
static int history_count = 0;
static const char *p = NULL;       /* 表达式解析指针 */
static int parse_error = 0;
static char last_expr[MAX_EXPR] = "";  /* 上一条表达式，供上箭头键回填 */

static void copy_string(char *dst, size_t dst_size, const char *src) {
    if (dst_size == 0) {
        return;
    }
    strncpy(dst, src, dst_size - 1);
    dst[dst_size - 1] = '\0';
}

static void skip_spaces(void) {
    while (*p == ' ' || *p == '\t') {
        p++;
    }
}

static double parse_expression(void);

/* 解析数字字面量 */
static double parse_number(void) {
    char *endptr;
    double value;

    skip_spaces();
    value = strtod(p, &endptr);

    if (endptr == p) {
        printf("Error: invalid number\n");
        parse_error = 1;
        return 0.0;
    }

    p = endptr;
    return value;
}

/*
 * 解析因子（最高优先级）
 * 因子 -> ['+'|'-'] ( '(' 表达式 ')' | 数字 )
 */
static double parse_factor(void) {
    double value;

    skip_spaces();

    if (*p == '+') {
        p++;
        return parse_factor();
    }

    if (*p == '-') {
        p++;
        return -parse_factor();
    }

    if (*p == '(') {
        p++;
        value = parse_expression();
        skip_spaces();

        if (*p == ')') {
            p++;
        } else {
            printf("Error: missing closing parenthesis\n");
            parse_error = 1;
        }

        return value;
    }

    if (isdigit((unsigned char)*p) || *p == '.') {
        return parse_number();
    }

    if (*p == '\0' || *p == '\n') {
        printf("Error: expression is incomplete\n");
    } else {
        printf("Error: unrecognized character %c\n", *p);
    }

    parse_error = 1;
    return 0.0;
}

/*
 * 解析项（乘除法，优先级高于加减）
 * 项 -> 因子 { ('*'|'/') 因子 }
 */
static double parse_term(void) {
    double left;
    double right;
    double result;
    char op;

    left = parse_factor();

    while (!parse_error) {
        skip_spaces();

        if (*p != '*' && *p != '/') {
            break;
        }

        op = *p;
        p++;
        right = parse_factor();

        if (parse_error) {
            return 0.0;
        }

        if (op == '*') {
            result = left * right;
            printf("Step: %.6g * %.6g = %.6g\n", left, right, result);
            left = result;
        } else {
            if (right == 0.0) {
                printf("Error: division by zero\n");
                parse_error = 1;
                return 0.0;
            }

            result = left / right;
            printf("Step: %.6g / %.6g = %.6g\n", left, right, result);
            left = result;
        }
    }

    return left;
}

/*
 * 解析表达式（加减法，最低优先级）
 * 表达式 -> 项 { ('+'|'-') 项 }
 */
static double parse_expression(void) {
    double left;
    double right;
    double result;
    char op;

    left = parse_term();

    while (!parse_error) {
        skip_spaces();

        if (*p != '+' && *p != '-') {
            break;
        }

        op = *p;
        p++;
        right = parse_term();

        if (parse_error) {
            return 0.0;
        }

        if (op == '+') {
            result = left + right;
            printf("Step: %.6g + %.6g = %.6g\n", left, right, result);
            left = result;
        } else {
            result = left - right;
            printf("Step: %.6g - %.6g = %.6g\n", left, right, result);
            left = result;
        }
    }

    return left;
}

/* 计算表达式入口：解析并检查是否有未消耗的字符，返回结果 */
static int calculate_expression(const char *expr, double *out_result) {
    double result;

    p = expr;
    parse_error = 0;
    result = parse_expression();
    skip_spaces();

    if (!parse_error && *p != '\0' && *p != '\n') {
        printf("Error: unparsed content after expression: %s\n", p);
        parse_error = 1;
    }

    if (parse_error) {
        return CALC_ERR;
    }

    *out_result = result;
    return CALC_OK;
}

/* 从 history.txt 加载历史记录到内存 */
static void load_history(void) {
    FILE *fp;
    char line[1024];
    char *sep;
    size_t len;

    history_count = 0;
    fp = fopen("history.txt", "r");

    if (fp == NULL) {
        return;
    }

    while (fgets(line, sizeof(line), fp) != NULL && history_count < MAX_HISTORY) {
        sep = strstr(line, " = ");

        if (sep != NULL) {
            *sep = '\0';
            len = strlen(line);
            while (len > 0 && (line[len - 1] == '\r' || line[len - 1] == '\n')) {
                line[len - 1] = '\0';
                len--;
            }
            copy_string(history[history_count].expr, sizeof(history[history_count].expr), line);
            history[history_count].result = atof(sep + 3);
            copy_string(last_expr, sizeof(last_expr), line);
            history_count++;
        }
    }

    fclose(fp);
}

/* 追加一条结果到历史文件 */
static void save_one_history(const char *expr, double result) {
    FILE *fp;

    fp = fopen("history.txt", "a");

    if (fp == NULL) {
        printf("Error: cannot open history file\n");
        return;
    }

    fprintf(fp, "%s = %.10g\n", expr, result);
    fclose(fp);
}

/* 添加历史记录（内存 + 文件持久化） */
static void add_history(const char *expr, double result) {
    if (history_count < MAX_HISTORY) {
        copy_string(history[history_count].expr, sizeof(history[history_count].expr), expr);
        history[history_count].result = result;
        history_count++;
    } else {
        printf("History memory is full, saving to file only\n");
    }

    copy_string(last_expr, sizeof(last_expr), expr);
    save_one_history(expr, result);
}

/* 分页显示历史记录 */
static void show_history_page(void) {
    int page;
    int total_pages;
    int start;
    int end;
    int i;

    if (history_count == 0) {
        printf("No history records\n");
        return;
    }

    total_pages = (history_count + PAGE_SIZE - 1) / PAGE_SIZE;

    printf("Enter page number (1 to %d): ", total_pages);
    if (scanf("%d", &page) != 1) {
        printf("Invalid page number\n");
        while (getchar() != '\n') {
        }
        return;
    }
    getchar();

    if (page < 1 || page > total_pages) {
        printf("Invalid page number\n");
        return;
    }

    start = (page - 1) * PAGE_SIZE;
    end = start + PAGE_SIZE;

    if (end > history_count) {
        end = history_count;
    }

    printf("Page %d history:\n", page);

    for (i = start; i < end; i++) {
        printf("%d. %s = %.10g\n", i + 1, history[i].expr, history[i].result);
    }
}

/* 清除全部历史记录 */
static void clear_history(void) {
    history_count = 0;
    last_expr[0] = '\0';
    remove("history.txt");
    printf("History cleared\n");
}

#ifndef _WIN32
/* 设置终端为原始模式（关闭行缓冲和回显），用于逐字符读取输入 */
static void set_terminal_raw_mode(struct termios *old_termios) {
    struct termios new_termios;

    tcgetattr(STDIN_FILENO, old_termios);
    new_termios = *old_termios;
    new_termios.c_lflag &= (tcflag_t) ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &new_termios);
}

static void restore_terminal_mode(const struct termios *old_termios) {
    tcsetattr(STDIN_FILENO, TCSANOW, old_termios);
}
#endif

static void redraw_input_line(const char *prompt, const char *buffer) {
    printf("\r%s%s", prompt, buffer);
    fflush(stdout);
}

/*
 * 逐字符读取表达式输入，支持退格删除和上箭头键回填上一条表达式
 * Windows 使用 _getch，Linux 使用 termios 原始模式
 */
static int read_expression_line(char *buffer, size_t buffer_size) {
    const char *prompt = "Enter expression (press Up Arrow for last expression): ";
    size_t len = 0;
    int ch;

    if (buffer_size == 0) {
        return 0;
    }

    buffer[0] = '\0';
    printf("%s", prompt);
    fflush(stdout);

#ifdef _WIN32
    while (1) {
        ch = _getch();

        if (ch == '\r' || ch == '\n') {
            putchar('\n');
            buffer[len] = '\0';
            return 1;
        }

        if (ch == 8 || ch == 127) {
            if (len > 0) {
                len--;
                buffer[len] = '\0';
                printf("\b \b");
                fflush(stdout);
            }
            continue;
        }

        if (ch == 0 || ch == 224) {
            ch = _getch();
            if (ch == 72) {
                if (last_expr[0] != '\0') {
                    printf("\r");
                    for (int i = 0; i < 120; i++) {
                        putchar(' ');
                    }
                    len = strlen(last_expr);
                    if (len >= buffer_size) {
                        len = buffer_size - 1;
                    }
                    memcpy(buffer, last_expr, len);
                    buffer[len] = '\0';
                    redraw_input_line(prompt, buffer);
                } else {
                    printf("\nNo previous expression\n%s%s", prompt, buffer);
                    fflush(stdout);
                }
            }
            continue;
        }

        if (isprint((unsigned char) ch) && len + 1 < buffer_size) {
            buffer[len++] = (char) ch;
            buffer[len] = '\0';
            putchar(ch);
            fflush(stdout);
        }
    }
#else
    struct termios old_termios;

    set_terminal_raw_mode(&old_termios);

    while (1) {
        ch = getchar();

        if (ch == '\r' || ch == '\n') {
            putchar('\n');
            buffer[len] = '\0';
            restore_terminal_mode(&old_termios);
            return 1;
        }

        if (ch == 127 || ch == 8) {
            if (len > 0) {
                len--;
                buffer[len] = '\0';
                printf("\b \b");
                fflush(stdout);
            }
            continue;
        }

        if (ch == 27) {
            int c1 = getchar();
            int c2 = getchar();

            if (c1 == '[' && c2 == 'A') {
                if (last_expr[0] != '\0') {
                    printf("\r");
                    for (int i = 0; i < 120; i++) {
                        putchar(' ');
                    }
                    len = strlen(last_expr);
                    if (len >= buffer_size) {
                        len = buffer_size - 1;
                    }
                    memcpy(buffer, last_expr, len);
                    buffer[len] = '\0';
                    redraw_input_line(prompt, buffer);
                } else {
                    printf("\nNo previous expression\n%s%s", prompt, buffer);
                    fflush(stdout);
                }
            }
            continue;
        }

        if (isprint((unsigned char) ch) && len + 1 < buffer_size) {
            buffer[len++] = (char) ch;
            buffer[len] = '\0';
            putchar(ch);
            fflush(stdout);
        }
    }
#endif
}

/* 输入表达式并求值 */
static void input_and_calculate(void) {
    char expr[MAX_EXPR];
    double result;

    read_expression_line(expr, sizeof(expr));

    if (strlen(expr) == 0) {
        printf("Expression cannot be empty\n");
        return;
    }

    printf("Calculation steps:\n");

    if (calculate_expression(expr, &result) == CALC_OK) {
        printf("Final result: %.10g\n", result);
        add_history(expr, result);
    } else {
        printf("Calculation failed, invalid expression was not saved to history\n");
    }
}

/* 选择两条历史记录组合成 (记录1)*(记录2) 并求值 */
static void combine_history_and_calculate(void) {
    int id1;
    int id2;
    char new_expr[MAX_EXPR * 2 + 8];
    double result;

    if (history_count < 2) {
        printf("Need at least 2 history records for combined calculation\n");
        return;
    }

    show_history_page();

    printf("Select first history record number: ");
    if (scanf("%d", &id1) != 1) {
        printf("Invalid record number\n");
        while (getchar() != '\n') {
        }
        return;
    }

    printf("Select second history record number: ");
    if (scanf("%d", &id2) != 1) {
        printf("Invalid record number\n");
        while (getchar() != '\n') {
        }
        return;
    }
    getchar();

    if (id1 < 1 || id1 > history_count || id2 < 1 || id2 > history_count) {
        printf("Invalid record number\n");
        return;
    }

    snprintf(new_expr, sizeof(new_expr), "(%s)*(%s)", history[id1 - 1].expr, history[id2 - 1].expr);

    printf("Combined expression: %s\n", new_expr);
    printf("Calculation steps:\n");

    if (calculate_expression(new_expr, &result) == CALC_OK) {
        printf("Final result: %.10g\n", result);
        add_history(new_expr, result);
    } else {
        printf("Calculation failed, combined expression was not saved to history\n");
    }
}

static void calculate_menu(void) {
    int choice;

    printf("\n--- Calculate Menu ---\n");
    printf("1. Enter expression\n");
    printf("2. Multiply two history records\n");
    printf("Select: ");

    if (scanf("%d", &choice) != 1) {
        printf("Input error\n");
        while (getchar() != '\n') {
        }
        return;
    }
    getchar();

    if (choice == 1) {
        input_and_calculate();
    } else if (choice == 2) {
        combine_history_and_calculate();
    } else {
        printf("Invalid calculate menu option\n");
    }
}

static void print_menu(void) {
    printf("\n===== Arithmetic Expression Calculator =====\n");
    printf("1. Calculate expression\n");
    printf("2. View history\n");
    printf("3. Clear history\n");
    printf("4. Exit\n");
    printf("Select: ");
}

int main(void) {
    int choice;

    load_history();

    while (1) {
        print_menu();

        if (scanf("%d", &choice) != 1) {
            printf("Input error\n");
            while (getchar() != '\n') {
            }
            continue;
        }
        getchar();

        switch (choice) {
            case 1:
                calculate_menu();
                break;
            case 2:
                show_history_page();
                break;
            case 3:
                clear_history();
                break;
            case 4:
                printf("Program exit\n");
                return 0;
            default:
                printf("Invalid menu option\n");
                break;
        }
    }

    return 0;
}
