#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#ifndef success
#define success 1
#endif

#define MAX_AMOUNT 20

//定义非终结符
typedef struct NOterminal
{
    char character;
    int  first_number;  //FIRST集的判定，初始为0
    int  follow_number; //FOLLOW集的判定，初始为0
    char* FIRST;       //FIRST 集合
    char* FOLLOW;      //FOLLOW集合
    struct NOterminal* next;
} noterminal;

//定义终结符
typedef struct Terminal
{
    char  character;        //当前的字符
    struct Terminal* next;
} terminal;

//定义产生式
typedef struct PRODUCTION
{
    char source;                //产生的开始
    char* result;              //产生的结果
    struct PRODUCTION* next;    //指向下一条
} production;

int amount = 0;
char TEST_STACK[20];
char* TEST_LIST[10];
char terminal_all[10] = { 0 };
terminal   TERMINAL_HEAD, * current_terminal = &TERMINAL_HEAD;
noterminal NOTERMINAL_HEAD, * current_noterminal = &NOTERMINAL_HEAD;
production PRODUCTION_HEAD, * current_production = &PRODUCTION_HEAD;

//函数申明
size_t read(void);
size_t test(void);
size_t write(void);
void Test_read(void);
size_t STACK_FULL();
void STACK_POP(void);
size_t STACK_EMPTY();
void init_stack(void);
void prediction(void);
void test_follow(void);
void emergency(int model);
void prediction_table(void);
void STACK_PUSH(char source);
void insert_to_terminal(char get);
void insert_to_noterminal(char get);
void eliminate_left_recursion(void);
void combine(char* destinction, char* source);
size_t is_appeared(char tobejudged, char* source);
void insert_to_production(char source, char* result);
size_t find_first(noterminal* this_noterminal, production* this_production);
size_t find_follow(noterminal* this_noterminal, production* this_production);


int main(void)
{
    TERMINAL_HEAD.next = NULL;
    NOTERMINAL_HEAD.next = NULL;
    PRODUCTION_HEAD.next = NULL;

    read();
    Test_read();

    printf("消除左递归\\n\\n");
    eliminate_left_recursion();
    Test_read();

    printf("求FIRST集\\n\\n");
    prediction();

    printf("求FOLLOW集\\n\\n");
    test_follow();

    prediction_table();
    emergency(0);
    return 0;
}

//读文件
size_t read(void)
{
    int line = 0, model = 0, old_line = 0;
    int number = 0;
    char current_get = 0, read_temp[10] = { 0 };
    FILE* read_stream = fopen("/data/workspace/myshixun/test.txt", "r");
    if (!read_stream)
    {
        printf("error in open file ,can`t open file\\n");
        exit(EXIT_FAILURE);
    }
    insert_to_terminal('#');    //插入栈底元素，以#表示栈底
    insert_to_terminal('^');    //插入空串元素，以^表示栈底
    while (!feof(read_stream))
    {
        current_get = fgetc(read_stream);
        while (current_get == ' ')
            current_get = fgetc(read_stream); //忽略空格
        while (current_get == '\\n')
        {
            current_get = fgetc(read_stream);
            line++;     //跳过换行
        }

        switch (line)
        {
        case 0:
            insert_to_noterminal(current_get);
            break;
        case 1:
            insert_to_terminal(current_get);
            break;
        case 3:
            ungetc(current_get, read_stream);
            old_line = 1;
            break;
        default:
            perror("error in format of program \\n");
            emergency(0);
            break;
        }
        if (old_line)
            break;
    }
    while (!feof(read_stream))
    {
        memset(read_temp, 0, sizeof(read_temp));
        old_line = line;
        current_get = fgetc(read_stream);
        while (current_get == ' ')
            current_get = fgetc(read_stream);     //忽略空格
        while (current_get == '\\n')
        {
            current_get = fgetc(read_stream);
            line++;     //跳过换行
        }
        model = ((line - old_line) > model) ? (line - old_line) : model;
        switch (model)
        {
        case 0:
        case 1:
            fscanf(read_stream, "%s", read_temp);
            insert_to_production(current_get, read_temp);
            break;
        case 2:
            ungetc(current_get, read_stream);
            TEST_LIST[number] = (char*)malloc(20);
            memset(TEST_LIST[number], 0, 20);
            fscanf(read_stream, "%s", TEST_LIST[number++]);
            break;
        default:
            perror("error in format of program \\n");
            emergency(1);
            break;
        }
    }

    fclose(read_stream);
    return success;
}
//测试
size_t test(void)
{
    noterminal* TEMP_NOTERMINAL = NOTERMINAL_HEAD.next;

    for (; TEMP_NOTERMINAL != NULL; TEMP_NOTERMINAL = TEMP_NOTERMINAL->next)
    {
        printf("%c\\tfirst number=%d\\tfirst=%s\\n",
            TEMP_NOTERMINAL->character,
            TEMP_NOTERMINAL->first_number,
            TEMP_NOTERMINAL->FIRST);
    }
    printf("\\n");
    return success;
}

/******Begin******/
//求FIRST集合
size_t find_first(noterminal* this_noterminal, production* this_production)
{
    noterminal* this_noterminal_temp;
    char temp[2] = { 0 };
    char* TEMP2, * help;

    while (this_production &&
           this_production->source != this_noterminal->character)
        this_production = this_production->next;

    if (this_noterminal->first_number == 0)
    {
        this_noterminal->FIRST = (char*)malloc(MAX_AMOUNT + 1);
        memset(this_noterminal->FIRST, 0, MAX_AMOUNT + 1);
    }

    while (this_production &&
           this_production->source == this_noterminal->character)
    {
        TEMP2 = this_production->result;

        while (*TEMP2)
        {
            if (is_appeared(*TEMP2, terminal_all))
            {
                temp[0] = *TEMP2;
                combine(this_noterminal->FIRST, temp);
                break;
            }
            else
            {
                this_noterminal_temp = NOTERMINAL_HEAD.next;
                while (this_noterminal_temp &&
                       this_noterminal_temp->character != *TEMP2)
                    this_noterminal_temp = this_noterminal_temp->next;

                if (!this_noterminal_temp)
                    break;

                if (this_noterminal_temp->first_number == 0)
                    find_first(this_noterminal_temp,
                               PRODUCTION_HEAD.next);

                combine(this_noterminal->FIRST,
                        this_noterminal_temp->FIRST);

                help = this_noterminal->FIRST;
                while (*help && *help != '^')
                    help++;

                if (*help && *(TEMP2 + 1))
                {
                    while (*help)
                    {
                        *help = *(help + 1);
                        help++;
                    }
                }
                else
                {
                    break;
                }

                TEMP2++;
            }
        }

        this_production = this_production->next;
    }

    this_noterminal->first_number =
        (int)strlen(this_noterminal->FIRST);
    return success;
}
/******End******/
/******Begin******/
//求FOLLOW集合
size_t find_follow(noterminal* this_noterminal, production* this_production)
{
    char* help = NULL;
    char* temp_result;
    int symbol = 0;
    char terminal_array[2] = { 0 };
    noterminal* FOLLOW_TEMP, * FOLLOW_HELP;

    if (this_noterminal->follow_number == 0)
    {
        this_noterminal->FOLLOW = (char*)malloc(MAX_AMOUNT + 1);
        memset(this_noterminal->FOLLOW, 0, MAX_AMOUNT + 1);
    }

    if (this_noterminal == NOTERMINAL_HEAD.next)
        this_noterminal->FOLLOW[0] = '#';

    while (this_production)
    {
        temp_result = this_production->result;

        while (*temp_result)
        {
            if (*temp_result != this_noterminal->character)
            {
                temp_result++;
                continue;
            }

            temp_result++;
            if (!*temp_result)
                symbol = 1;

            while (*temp_result)
            {
                if (is_appeared(*temp_result, terminal_all))
                {
                    terminal_array[0] = *temp_result;
                    combine(this_noterminal->FOLLOW,
                            terminal_array);
                    symbol = 0;
                    break;
                }
                else
                {
                    FOLLOW_TEMP = NOTERMINAL_HEAD.next;
                    while (FOLLOW_TEMP &&
                           FOLLOW_TEMP->character != *temp_result)
                        FOLLOW_TEMP = FOLLOW_TEMP->next;

                    if (!FOLLOW_TEMP)
                        break;

                    combine(this_noterminal->FOLLOW,
                            FOLLOW_TEMP->FIRST);

                    help = this_noterminal->FOLLOW;
                    while (*help && *help != '^')
                        help++;

                    if (*help)
                    {
                        while (*help)
                        {
                            *help = *(help + 1);
                            help++;
                        }
                        symbol = 1;
                    }
                    else
                    {
                        symbol = 0;
                        break;
                    }
                }

                temp_result++;
            }

            if (symbol &&
                this_production->source !=
                this_noterminal->character)
            {
                FOLLOW_HELP = NOTERMINAL_HEAD.next;
                while (FOLLOW_HELP &&
                       FOLLOW_HELP->character !=
                       this_production->source)
                    FOLLOW_HELP = FOLLOW_HELP->next;

                if (FOLLOW_HELP)
                {
                    if (FOLLOW_HELP->follow_number == 0)
                        find_follow(FOLLOW_HELP,
                                    PRODUCTION_HEAD.next);
                    combine(this_noterminal->FOLLOW,
                            FOLLOW_HELP->FOLLOW);
                }
                symbol = 0;
            }
        }

        this_production = this_production->next;
    }

    this_noterminal->follow_number =
        (int)strlen(this_noterminal->FOLLOW);
    return success;
}
/******End******/


//紧急退出
void emergency(int model)
{
    current_noterminal = NOTERMINAL_HEAD.next;
    current_terminal = TERMINAL_HEAD.next;
    current_production = PRODUCTION_HEAD.next;
    while (current_noterminal)
    {
        NOTERMINAL_HEAD.next = current_noterminal->next;
        free(current_noterminal->FIRST);
        free(current_noterminal->FOLLOW);
        free(current_noterminal);
        current_noterminal = NOTERMINAL_HEAD.next;
    }
    while (current_terminal)
    {
        TERMINAL_HEAD.next = current_terminal->next;
        free(current_terminal);
        current_terminal = TERMINAL_HEAD.next;
    }
    while (current_production)
    {
        PRODUCTION_HEAD.next = current_production->next;
        free(current_production->result);
        free(current_production);
        current_production = PRODUCTION_HEAD.next;
    }
    printf("退出成功\\n\\n");
    fflush(stdout);
    exit(0);
}

//插入到终结符
void insert_to_terminal(char get)
{
    terminal* Temp_terminal = (terminal*)malloc(sizeof(terminal));
    if (!Temp_terminal)
    {
        perror("can`t malloc for this program\\n");
        emergency(0);
    }
    Temp_terminal->character = get;
    Temp_terminal->next = NULL;
    current_terminal->next = Temp_terminal;
    current_terminal = Temp_terminal; //移向下一个节点
    return;
}

//插入到非终结符
void insert_to_noterminal(char get)
{
    noterminal* Temp_noterminal = (noterminal*)malloc(sizeof(noterminal));
    if (!Temp_noterminal)
    {
        perror("can`t malloc for this program\\n");
        emergency(0);
    }
    Temp_noterminal->character = get;
    Temp_noterminal->next = NULL;
    Temp_noterminal->FIRST = NULL;
    Temp_noterminal->FOLLOW = NULL;
    Temp_noterminal->first_number = 0;
    Temp_noterminal->follow_number = 0;
    current_noterminal->next = Temp_noterminal;
    current_noterminal = Temp_noterminal;     //移向下一个节点
    return;
}

//插入到产生式
void insert_to_production(char source, char* result)
{

    char TEMP[20] = { 0 };
    int COUNT = 0, number = 0, length = 0, exit_condition = strlen(result);
    production* Temp_production;
    for (COUNT = 0; COUNT != exit_condition + 1; COUNT++)
    {
        if (*result == '-' && *(result + 1) == '>')
        {
            result += 2;
            COUNT += 2;
        }
        if ((*result != '|') && (*result))
            TEMP[number++] = *result;
        else
        {
            Temp_production = (production*)malloc(sizeof(production));
            length = strlen(TEMP) + 1;
            Temp_production->result = (char*)malloc(length);
            memset(Temp_production->result, 0, length);
            strncpy(Temp_production->result, TEMP, length - 1);
            memset(TEMP, 0, sizeof(TEMP));
            Temp_production->source = source;
            Temp_production->next = NULL;
            current_production->next = Temp_production;
            current_production = Temp_production;
            number = 0;
        }
        result++;
    }
    return;
}


//消除左递归
void eliminate_left_recursion(void)
{
    int number = 0;
    char new_char[3] = { 0 }, TEMP_RESULT[20], temp_empty[3] = { '^',0,0 };
    production* Temp_production = PRODUCTION_HEAD.next;
    production* Temp_FREE;
    terminal* temp = TERMINAL_HEAD.next;
    while (Temp_production)
    {
        if (Temp_production->source == Temp_production->result[0])
        {
            memset(TEMP_RESULT, 0, sizeof(TEMP_RESULT));
            new_char[0] = Temp_production->source - 'A' + 'a';
            //复制到新的产生式
            strcat(TEMP_RESULT, Temp_production->result + 1);
            strcat(TEMP_RESULT, new_char);
            insert_to_noterminal(new_char[0]);
            insert_to_production(new_char[0], TEMP_RESULT);
            insert_to_production(new_char[0], temp_empty);

            //修改当前的产生式
            memset(TEMP_RESULT, 0, sizeof(TEMP_RESULT));
            strcat(TEMP_RESULT, Temp_production->next->result);
            strcat(TEMP_RESULT, new_char);
            memset(Temp_production->result, 0, strlen(Temp_production->result));
            strncpy(Temp_production->result, TEMP_RESULT, strlen(TEMP_RESULT));

            Temp_FREE = Temp_production->next;
            Temp_production->next = Temp_production->next->next;
            free(Temp_FREE);
            continue;
        }
        Temp_production = Temp_production->next;
    }
    while (temp)
    {
        terminal_all[number++] = temp->character;
        temp = temp->next;
    }
    return;
}


void Test_read(void)
{
    int number = 1;
    production* TEMP_PRODUCTION = PRODUCTION_HEAD.next;
    terminal* TEMP_TERMINAL = TERMINAL_HEAD.next;
    noterminal* TEMP_NOTERMINAL = NOTERMINAL_HEAD.next;

    printf("产生式\\n");
    for (number = 1;
         TEMP_PRODUCTION != NULL;
         TEMP_PRODUCTION = TEMP_PRODUCTION->next, number++)
    {
        printf("%d\\t%c\\t%s\\n",
               number,
               TEMP_PRODUCTION->source,
               TEMP_PRODUCTION->result);
    }

    printf("\\n终结符\\n");
    for (; TEMP_TERMINAL != NULL; TEMP_TERMINAL = TEMP_TERMINAL->next)
    {
        printf("%c\\t", TEMP_TERMINAL->character);
    }

    printf("\\n\\n非终结符\\n");
    for (; TEMP_NOTERMINAL != NULL;
         TEMP_NOTERMINAL = TEMP_NOTERMINAL->next)
    {
        printf("%c\\t", TEMP_NOTERMINAL->character);
    }

    printf("\\n\\n读取测试\\n%s\\n%s\\n\\n",
           TEST_LIST[0],
           TEST_LIST[1]);
    return;
}

size_t is_appeared(char tobejudged, char* source)
{
    size_t length = strlen(source), counts = 0;
    while ((counts != length) && (*source != tobejudged))
    {
        counts++;
        source++;
    }
    return counts == length ? !success : success;
}

void combine(char* destinction, char* source)
{
    char temp[2] = { 0 };
    while (*source)
    {
        if (!is_appeared(*source, destinction))
        {
            temp[0] = *source;
            strcat(destinction, temp);
        }
        source++;
    }
    return;
}


void prediction(void)
{
    noterminal* TEMP_NOTERMINAL = NOTERMINAL_HEAD.next;
    while (TEMP_NOTERMINAL != NULL)
    {
        find_first(TEMP_NOTERMINAL, PRODUCTION_HEAD.next);
        TEMP_NOTERMINAL = TEMP_NOTERMINAL->next;
    }
    test();

    TEMP_NOTERMINAL = NOTERMINAL_HEAD.next;
    while (TEMP_NOTERMINAL != NULL)
    {
        find_follow(TEMP_NOTERMINAL, PRODUCTION_HEAD.next);
        TEMP_NOTERMINAL = TEMP_NOTERMINAL->next;
    }
    return;
}

void test_follow(void)
{
    noterminal* TEMP_NOTERMINAL = NOTERMINAL_HEAD.next;

    for (; TEMP_NOTERMINAL != NULL; TEMP_NOTERMINAL = TEMP_NOTERMINAL->next)
    {
        printf("%c\\tfollow number=%d\\tfollow=%s\\n",
            TEMP_NOTERMINAL->character,
            TEMP_NOTERMINAL->follow_number,
            TEMP_NOTERMINAL->FOLLOW);
    }
    printf("\\n");
    return;
}

/******Begin******/
//生成预测分析表
void prediction_table(void)
{
    int line = 0, row = 0;
    int current_character = 0, number = 0;
    char* FIRST_CLUM, * test_exper;
    noterminal* temp_noterminal = NOTERMINAL_HEAD.next;
    noterminal* temp_noterminal21;
    terminal* temp_terminal = TERMINAL_HEAD.next;
    production* temp_production = PRODUCTION_HEAD.next;
    char hah[5][7];

    memset(hah, 0, sizeof(hah));

    while (temp_production)
    {
        row = 0;

        if (is_appeared(*temp_production->result,
                        terminal_all) &&
            *temp_production->result != '^')
        {
            while (terminal_all[row] !=
                   *temp_production->result)
                row++;
            hah[current_character][row] = line + 1;
        }
        else
        {
            temp_noterminal = NOTERMINAL_HEAD.next;

            if (*temp_production->result == '^')
            {
                while (temp_noterminal->character !=
                       temp_production->source)
                    temp_noterminal =
                        temp_noterminal->next;

                FIRST_CLUM = temp_noterminal->FOLLOW;
                while (*FIRST_CLUM)
                {
                    row = 0;
                    while (terminal_all[row] != *FIRST_CLUM)
                        row++;
                    hah[current_character][row] = line + 1;
                    FIRST_CLUM++;
                }

                if (temp_production->next &&
                    temp_production->source !=
                    temp_production->next->source)
                    current_character++;

                temp_production = temp_production->next;
                line++;
                continue;
            }

            while (temp_noterminal->character !=
                   *temp_production->result)
                temp_noterminal = temp_noterminal->next;

            FIRST_CLUM = temp_noterminal->FIRST;
            while (*FIRST_CLUM)
            {
                if (*FIRST_CLUM != '^')
                {
                    row = 0;
                    while (terminal_all[row] != *FIRST_CLUM)
                        row++;
                    hah[current_character][row] = line + 1;
                }
                FIRST_CLUM++;
            }

            temp_noterminal21 = NOTERMINAL_HEAD.next;
            while (temp_noterminal21->character !=
                   temp_production->source)
                temp_noterminal21 =
                    temp_noterminal21->next;

            if (is_appeared('^', temp_noterminal->FIRST))
            {
                FIRST_CLUM = temp_noterminal21->FOLLOW;
                while (*FIRST_CLUM)
                {
                    row = 0;
                    while (terminal_all[row] != *FIRST_CLUM)
                        row++;
                    hah[current_character][row] = line + 1;
                    FIRST_CLUM++;
                }
            }
        }

        if (temp_production->next &&
            temp_production->source !=
            temp_production->next->source)
            current_character++;

        temp_production = temp_production->next;
        line++;
    }

    printf("预测分析表\\n\\n");
    printf("  \\t");
    for (temp_terminal = TERMINAL_HEAD.next;
         temp_terminal;
         temp_terminal = temp_terminal->next)
        printf("%c\\t", temp_terminal->character);

    temp_noterminal = NOTERMINAL_HEAD.next;
    for (line = 0; line < 5 && temp_noterminal; line++)
    {
        printf("\\n%c\\t", temp_noterminal->character);
        for (row = 0; row < 7; row++)
            printf("%c\\t",
                   hah[line][row] == 0 ?
                   ' ' : (char)(hah[line][row] + '0'));
        temp_noterminal = temp_noterminal->next;
    }

    printf("\\n\\n");
    memset(TEST_STACK, 0, sizeof(TEST_STACK));
    init_stack();

    // Now add the parser for the example string
    test_exper = TEST_LIST[0];
    test_exper[strlen(test_exper)] = '#';
    STACK_PUSH(NOTERMINAL_HEAD.next->character);

    printf("分析栈\\t剩余字符串\\t输入串\\n");

    // Replacement code for the parser display following exactly the specified format
    while (!STACK_EMPTY())
    {
        printf("分析栈\\t");
        for (number = 0; number <= amount; number++)
            printf("%c", TEST_STACK[number]);
        printf("\\t剩余字符串\\t%s\\n", test_exper);

        if (TEST_STACK[amount] == *test_exper)
        {
            STACK_POP();
            test_exper++;
        }
        else
        {
            line = 0;
            row = 0;
            temp_noterminal = NOTERMINAL_HEAD.next;

            while (temp_noterminal &&
                   temp_noterminal->character !=
                   TEST_STACK[amount])
            {
                temp_noterminal = temp_noterminal->next;
                line++;
            }

            if (!temp_noterminal)
                break;

            while (terminal_all[row] &&
                   terminal_all[row] != *test_exper)
                row++;

            if (!terminal_all[row])
                break;

            row = hah[line][row];
            if (!row)
                break;

            temp_production = PRODUCTION_HEAD.next;
            while (--row)
                temp_production = temp_production->next;

            FIRST_CLUM = temp_production->result;
            current_character = (int)strlen(FIRST_CLUM);
            FIRST_CLUM += current_character - 1;
            STACK_POP();

            while (current_character)
            {
                if (*FIRST_CLUM != '^')
                    STACK_PUSH(*FIRST_CLUM);
                FIRST_CLUM--;
                current_character--;
            }
        }
    }

    printf("分析栈\\t");
    for (number = 0; number <= amount; number++)
        printf("%c", TEST_STACK[number]);
    printf("\\t剩余字符串\\t%s\\n", test_exper);

    if (STACK_EMPTY() && *test_exper == '#')
        printf("\\n合法输入\\n\\n");
    else
        printf("\\n不合法输入\\n\\n");
}
/******End******/

void STACK_POP(void)
{
    if (STACK_EMPTY())
    {
        printf("栈空\\n");
        emergency(2);
    }
    amount--;
    return;
}
size_t STACK_EMPTY()
{
    return amount == 0 ? success : !success;
}
size_t STACK_FULL()
{
    return amount == 19 ? success : !success;
}
void STACK_PUSH(char source)
{
    if (STACK_FULL())
    {
        printf("栈满\\n");
        emergency(2);
    }
    TEST_STACK[++amount] = source;
    return;
}

void init_stack(void)
{
    amount = 0;
    TEST_STACK[amount] = '#';
    return;
}