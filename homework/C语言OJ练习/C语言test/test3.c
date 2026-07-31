/*#include <stdio.h>//识整数
#include <math.h>
#include <stdbool.h>
#include <string.h>
int isprime(int n) {
    if (n <= 1) return 0;
    if (n == 2) return 1;
    if (n % 2 == 0) return 0;
    for (int i = 3; i * i <= n; i += 2) {
        if (n % i == 0) return 0;
    }
    return 1;
}
int superprime(int n) {
    int arr[1000];
    int cnt = 0;
    int sum = 0;
    int temp = n;
    while (temp) {
        arr[cnt++] = temp % 10;
        sum += temp % 10;
        temp /= 10;
    }
    int flag = 0;//arr:3332
    for (int i = cnt - 1; i >= 0; i--) {
        int num = 0;
        for (int j = i; j <cnt; j++) {
            num += arr[j] * pow(10, j-i);
        }
        if (isprime(num)) {
            flag = 1;
        }
        else {
            flag = 0;
            break;
        }
    }
    if (isprime(n) && isprime(sum) && flag==1) {
        return 1;
    }
    else
        return 0;
}
int factorize(int n,int *facs) {//n都是奇数
    int count = 0;
    for (int i = 3; i * i <= n; i += 2) { // 处理奇素数
        if (n % i == 0 && isprime(i)) {
            facs[count++] = i;
            while (n % i == 0) n /= i;
        }
    }
    if (n > 1 && isprime(n)) { // 剩余的大素数
        facs[count++] = n;
    }
    return count;
}
bool isDecimalPalindrome(int num) {
    if (num < 0) return false; // 负数不是回文数
    int original = num;
    int reversed = 0;

    // 反转数字
    while (num > 0) {
        reversed = reversed * 10 + num % 10;
        num /= 10;
    }

    return original == reversed;
}

// 将十进制数转为二进制字符串
void toBinary(int num, char* binary) {
    int index = 0;
    if (num == 0) {
        binary[index++] = '0';
        binary[index] = '\0';
        return;
    }

    // 逐位转换为二进制
    while (num > 0) {
        binary[index++] = (num % 2) + '0';
        num /= 2;
    }
    binary[index] = '\0';

    // 反转字符串得到正确的二进制顺序
    int len = strlen(binary);
    for (int i = 0; i < len / 2; i++) {
        char temp = binary[i];
        binary[i] = binary[len - i - 1];
        binary[len - i - 1] = temp;
    }
}

// 判断二进制字符串是否为回文数
bool isBinaryPalindrome(int num) {
    char binary[32]; // 存储二进制字符串（int最多32位）
    toBinary(num, binary);

    int len = strlen(binary);
    for (int i = 0; i < len / 2; i++) {
        if (binary[i] != binary[len - i - 1]) {
            return false;
        }
    }
    return true;
}

// 判断是否为精致回文数
bool isExquisitePalindrome(int num) {
    return isDecimalPalindrome(num) && isBinaryPalindrome(num);
}
int knum(int n) {
    if (n % 2 == 0)return 0;
    int factors[20]; // 存储质因数
    int factorCount = factorize(n, factors);
    if (factorCount < 3) return 0;

    // 条件2：所有质因数都是不重复的奇素数（分解时已保证不重复）
    for (int i = 0; i < factorCount; i++) {
        if (factors[i] == 2) return 0; // 卡迈克尔数不含2
    }
    // 条件3：所有(pi-1)都能整除(y-1)
    int yMinus1 = n - 1;
    for (int i = 0; i < factorCount; i++) {
        if (yMinus1 % (factors[i] - 1) != 0) {
            return 0;
        }
    }
    return 1;
}
int main() {
    int n;
    while (scanf("%d", &n) != EOF) {
        if (superprime(n)) {
            printf("S\n");
        }
        else if (knum(n)) {
            printf("K\n");
        }
        else if (isExquisitePalindrome(n)) {
            printf("P\n");
        }
        else {
            printf("N\n");
        }
    }
    return 0;
}*/
/*#include <stdio.h>
#include <stdlib.h>
int compare(const void* a, const void* b) {
    return (*(int*)a - *(int*)b);
}
//去重排序134536
void remove(int* arr, int n,int *new) {
    int cnt = 0;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < i; j++) {
            if (arr[i] == arr[j]) {
                arr[j] = 0;
            }
        }
    }
    for (int i = 0; i < n; i++) {
        if (arr[i] != 0) {
            new[cnt++] = arr[i];
        }
    }
    qsort(new, cnt, sizeof(int), compare);
}
int main() {
    int n, m;
    while (scanf("%d %d", &n, &m) != EOF) {
        int a0[n], b0[m];
        for (int i = 0; i < n; i++) {
            scanf("%d", a0[i]);
        }
        for (int i = 0; i < m; i++) {
            scanf("%d", b0[i]);
        }
        int* a, * b;
        remove(a0, n, a);
        remove(b0, m, b);
        int nn = sizeof(a) / sizeof(int);
        int mm = sizeof(b) / sizeof(int);
        //算交集
        int jiao[100], jiaon = 0;
        for (int i = 0; i < nn; i++) {
            for (int j = 0; j < mm; j++) {
                if (a[i] == a[j]) {
                    jiao[jiaon++] = a[i];
                }
            }
        }
        //算并集
        int bing[100], bingn = 0;
        for (int i = 0; i < n; i++) {
            bing[bingn++] = a[i];
        }
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < jiaon; j++) {
                if (jiao[j] != b[i]) {
                    bing[bingn++] = b[i];
                }
            }
        }
        int* newbing;
        remove(bing, bingn, newbing);
        //A-B
        for (int i = 0; i < nn; i++) {
            for (int j = 0; j < mm; j++) {
                if(a[i])
            }
        }
        //结果去重
    }
}*/
/*#include <stdio.h>
#include <string.h>
int copy(char* str1, int* str2, int start, int end) {
    int cnt = 0;
    for (int i = start; i < end; i++) {
        str2[cnt++] = str1[i] - '0';
    }
    return cnt;
}
int main(void) {
    char  arra[400];
    char  arrb[400];
    while (scanf("%s %s", arra, arrb) != EOF) {
        int arr1[400] = { 0 }, arrx[400] = { 0 };
        int arr2[400] = { 0 }, arry[400] = { 0 };
        int len1 = strlen(arra), len2 = strlen(arrb);
        int mark1 = len1, mark2 = len2;
        for (int i = 0; i < len1; i++) {
            if (arra[i] == '.') {
                mark1 = i;
                break;
            }
        }
        for (int i = 0; i < len2; i++) {
            if (arrb[i] == '.') {
                mark2 = i;
                break;
            }
        }
        int xxiao = copy(arra, arr1, mark1 + 1, len1);
        int yxiao = copy(arrb, arr2, mark2 + 1, len2);
        int xshi = copy(arra, arrx, 0, mark1);
        int yshi = copy(arrb, arry, 0, mark2);
        int c = 0;
        for (int i = yxiao-1; i >= 0; i--) {
            int sum = arr1[i] + arr2[i] + c;
            arr1[i] = sum % 10;
            c = sum / 10;
        }
        int maxxiao = xxiao > yxiao ? xxiao : yxiao;
        int i = xshi - 1, j = yshi - 1;
        int k = 0;
        int tem[400];
        while (i >= 0 || j >= 0 || c) {
            int sum = c;
            if (i >= 0)sum += arrx[i--];
            if (j >= 0)sum += arry[j--];
            tem[k++] = sum % 10;
            c = sum / 10;
        }
        int start = k - 1;
        while (start > 0 && tem[start] == 0) {
            start--;
        }
        for (int i = start; i >= 0; i--) {
            printf("%d", tem[i]);
        }
        start = maxxiao - 1;
        while (start >= 0 && arr1[start] == 0) {
            start--;
        }
        if (start != -1) {
            printf(".");
        }
        for (int i = 0; i <= start; i++) {
            printf("%d", arr1[i]);
        }
        printf("\n");
    }
    return 0;
}*/