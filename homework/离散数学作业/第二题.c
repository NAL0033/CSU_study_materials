#include <stdio.h>
#include <stdbool.h>
int main() {
	int choice;
    printf("请选择要测试的复合命题（输入 1~5）:\n");
    printf("1. P ∧ Q\n");
    printf("2. P ∨ Q\n");
    printf("3. P ⊕ Q\n");
    printf("4. P → Q\n");
    printf("5. 双条件\n");
    printf("你的选择: \n");
    scanf("%d", &choice);
    bool result;
    for (int p = 0; p <= 1; p++) {
        for (int q = 0; q <= 1; q++) {
            switch (choice) {
            case 1:
                result = p && q;
                break;
            case 2:
                result = p || q;
                break;
            case 3:
                result = p ^ q;
                break;
            case 4:
                result = !p || q;
                break;
            case 5:
                result = (p == q);
                break;
            default:
                printf("输入错误！\n");
                return 1;
            }
            printf("P=%d,Q=%d\n", p, q);
            printf("结果：%d\n", result);
        }
    }
    return 0;
}