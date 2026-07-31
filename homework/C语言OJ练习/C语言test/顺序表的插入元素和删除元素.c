#include <stdio.h>
#include <stdlib.h>

#define MAX_SIZE 100

typedef struct {
    int data[MAX_SIZE];
    int length;
} Linearlist;

// 初始化顺序表
void initlist(Linearlist* list) {
    list->length = 0;
}

// 在指定位置插入元素
int insertelement(Linearlist* list, int index, int value) {
    if (index < 0 || index > list->length) {
        return -1; // 插入位置不合法
    }
    if (list->length >= MAX_SIZE) {
        return -1; // 顺序表已满
    }

    // 将index之后的元素后移
    for (int i = list->length; i > index; i--) {
        list->data[i] = list->data[i - 1];
    }

    list->data[index] = value;
    list->length++;
    return 0; // 插入成功
}

// 在表头插入元素
int inserthead(Linearlist* list, int value) {
    return insertelement(list, 0, value);
}

// 在表尾插入元素
int inserttail(Linearlist* list, int value) {
    return insertelement(list, list->length, value);
}

// 删除指定位置的元素
int deleteelement(Linearlist* list, int index) {
    if (index < 0 || index >= list->length) {
        return -1; // 删除位置不合法
    }

    // 将index之后的元素前移
    for (int i = index; i < list->length - 1; i++) {
        list->data[i] = list->data[i + 1];
    }

    list->length--;
    return 0; // 删除成功
}

// 按值删除元素(删除第一个匹配的元素)
int deletebyvalue(Linearlist* list, int value) {
    for (int i = 0; i < list->length; i++) {
        if (list->data[i] == value) {
            return deleteelement(list, i);
        }
    }
    return -1; // 未找到该值
}

// 查找元素是否存在
int search(Linearlist* list, int value) {
    for (int i = 0; i < list->length; i++) {
        if (list->data[i] == value) {
            return i; // 返回元素位置
        }
    }
    return -1; // 未找到
}

// 打印顺序表
void printlist(Linearlist* list) {
    printf("List: [");
    for (int i = 0; i < list->length; i++) {
        printf("%d", list->data[i]);
        if (i < list->length - 1) {
            printf(", ");
        }
    }
    printf("], Length: %d\n", list->length);
}

int main() {
    Linearlist mylist;
    initlist(&mylist);

    // 测试插入操作
    inserthead(&mylist, 1);
    inserthead(&mylist, 2);
    inserttail(&mylist, 3);
    inserttail(&mylist, 4);
    insertelement(&mylist, 2, 5);

    printlist(&mylist); // List: [2, 1, 5, 3, 4], Length: 5

    // 测试查找操作
    int value = 5;
    int pos = search(&mylist, value);
    if (pos != -1) {
        printf("%d found at position %d\n", value, pos);
    }
    else {
        printf("%d not found\n", value);
    }

    // 测试删除操作
    deleteelement(&mylist, 2);
    printlist(&mylist); // List: [2, 1, 3, 4], Length: 4

    deletebyvalue(&mylist, 1);
    printlist(&mylist); // List: [2, 3, 4], Length: 3

    return 0;
}
