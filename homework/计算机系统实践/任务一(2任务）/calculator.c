#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>                           //cd D:\作业\计算机系统实践\任务一(2任务）
            
#define MAX_HISTORY 100
#define MAX_EXPR 256
#define PAGE_SIZE 10

typedef struct {
    char expr[MAX_EXPR];
    double result;
} History;

History history[MAX_HISTORY];
int history_count = 0;
const char *p;

void skip_spaces() {
    while (*p == ' ' || *p == '\t') {
        p++;
    }
}

double parse_expression();

double parse_number() {
    char *endptr;
    double value;

    skip_spaces();
    value = strtod(p, &endptr);
    p = endptr;

    return value;
}

double parse_factor() {
    double value;

    skip_spaces();

    if (*p == '+') {
        p++;
        value = parse_factor();
        return value;
    }

    if (*p == '-') {
        p++;
        value = -parse_factor();
        return value;
    }

    if (*p == '(') {
        p++;
        value = parse_expression();
        skip_spaces();

        if (*p == ')') {
            p++;
        } else {
            printf("Error: missing closing parenthesis\n");
        }

        return value;
    }

    if (isdigit((unsigned char)*p) || *p == '.') {
        return parse_number();
    }

    printf("Error: unrecognized character %c\n", *p);
    return 0.0;
}

double parse_term() {
    double left;
    double right;
    char op;
    double result;

    left = parse_factor();

    while (1) {
        skip_spaces();

        if (*p != '*' && *p != '/') {
            break;
        }

        op = *p;
        p++;
        right = parse_factor();

        if (op == '*') {
            result = left * right;
            printf("Step: %.6g * %.6g = %.6g\n", left, right, result);
            left = result;
        } else {
            if (right == 0.0) {
                printf("Error: division by zero\n");
                return 0.0;
            }

            result = left / right;
            printf("Step: %.6g / %.6g = %.6g\n", left, right, result);
            left = result;
        }
    }

    return left;
}

double parse_expression() {
    double left;
    double right;
    char op;
    double result;

    left = parse_term();

    while (1) {
        skip_spaces();

        if (*p != '+' && *p != '-') {
            break;
        }

        op = *p;
        p++;
        right = parse_term();

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

double calculate_expression(const char *expr) {
    double result;

    p = expr;
    result = parse_expression();
    skip_spaces();

    if (*p != '\0' && *p != '\n') {
        printf("Warning: unparsed content after expression: %s\n", p);
    }

    return result;
}

void load_history() {
    FILE *fp;
    char line[512];
    char *sep;

    history_count = 0;
    fp = fopen("history.txt", "r");

    if (fp == NULL) {
        return;
    }

    while (fgets(line, sizeof(line), fp) != NULL && history_count < MAX_HISTORY) {
        sep = strstr(line, " = ");

        if (sep != NULL) {
            *sep = '\0';
            strcpy(history[history_count].expr, line);
            history[history_count].result = atof(sep + 3);
            history_count++;
        }
    }

    fclose(fp);
}

void save_one_history(const char *expr, double result) {
    FILE *fp;

    fp = fopen("history.txt", "a");

    if (fp == NULL) {
        printf("Error: cannot open history file\n");
        return;
    }

    fprintf(fp, "%s = %.10g\n", expr, result);
    fclose(fp);
}

void add_history(const char *expr, double result) {
    if (history_count >= MAX_HISTORY) {
        printf("History full, saving to file only\n");
        save_one_history(expr, result);
        return;
    }

    strcpy(history[history_count].expr, expr);
    history[history_count].result = result;
    history_count++;

    save_one_history(expr, result);
}

void show_history_page() {
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
    scanf("%d", &page);
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

void clear_history() {
    history_count = 0;
    remove("history.txt");
    printf("History cleared\n");
}

void input_and_calculate() {
    char expr[MAX_EXPR];
    double result;

    printf("Enter expression: ");
    fgets(expr, sizeof(expr), stdin);

    expr[strcspn(expr, "\n")] = '\0';

    if (strlen(expr) == 0) {
        printf("Expression cannot be empty\n");
        return;
    }

    printf("Calculation steps:\n");
    result = calculate_expression(expr);
    printf("Final result: %.10g\n", result);

    add_history(expr, result);
}

void combine_history_and_calculate() {
    int id1;
    int id2;
    char new_expr[MAX_EXPR * 2 + 16];
    double result;

    if (history_count < 2) {
        printf("Need at least 2 history records for combined calculation\n");
        return;
    }

    show_history_page();

    printf("Select first history record number: ");
    scanf("%d", &id1);

    printf("Select second history record number: ");
    scanf("%d", &id2);
    getchar();

    if (id1 < 1 || id1 > history_count || id2 < 1 || id2 > history_count) {
        printf("Invalid record number\n");
        return;
    }

    snprintf(new_expr, sizeof(new_expr), "(%s)*(%s)", history[id1 - 1].expr, history[id2 - 1].expr);

    printf("Combined expression: %s\n", new_expr);
    printf("Calculation steps:\n");

    result = calculate_expression(new_expr);
    printf("Final result: %.10g\n", result);

    add_history(new_expr, result);
}

void print_menu() {
    printf("\n===== Arithmetic Expression Calculator =====\n");
    printf("1. Calculate expression\n");
    printf("2. View history\n");
    printf("3. Clear history\n");
    printf("4. Multiply two history records\n");
    printf("5. Exit\n");
    printf("Select: ");
}

int main() {
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
                input_and_calculate();
                break;
            case 2:
                show_history_page();
                break;
            case 3:
                clear_history();
                break;
            case 4:
                combine_history_and_calculate();
                break;
            case 5:
                printf("Program exit\n");
                return 0;
            default:
                printf("Invalid menu option\n");
                break;
        }
    }

    return 0;
}