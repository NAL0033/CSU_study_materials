#include <stdio.h>
#include <string.h>

#define MAXN 1000005

typedef struct
{
    int next[26];
    int cnt;
}Trie;

Trie trie[MAXN];

char s[100005];
char t[15];

int tot = 0;

int main()
{
    scanf("%s", s);

    int n = strlen(s);

    // 建Trie
    for(int i = 0; i < n; i++)
    {
        int p = 0;   // 根节点

        for(int j = i; j < n && j < i + 10; j++)
        {
            int c = s[j] - 'a';

            if(trie[p].next[c] == 0)
                trie[p].next[c] = ++tot;

            p = trie[p].next[c];

            trie[p].cnt++;
        }
    }

    int q;
    scanf("%d", &q);

    while(q--)
    {
        scanf("%s", t);

        int p = 0;
        int ok = 1;

        for(int i = 0; t[i]; i++)
        {
            int c = t[i] - 'a';

            if(trie[p].next[c] == 0)
            {
                ok = 0;
                break;
            }

            p = trie[p].next[c];
        }

        if(ok)
            printf("%d\n", trie[p].cnt);
        else
            printf("0\n");
    }

    return 0;
}