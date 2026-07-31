#include <stdio.h>

typedef unsigned long long ull;

int main()
{
    int n, m, c, k;
    scanf("%d%d%d%d", &n, &m, &c, &k);
    ull a[100005];

    ull now = 0;

    for(int i = 0; i < n; i++)
    {
        scanf("%llu", &a[i]);
        now |= a[i];
    }
    /*
        have[i]表示第i类耗材现在有没有
    */
    int have[100005] = {0};
    int p[100005], q[100005];


    for(int i = 0; i < m; i++)
    {
        scanf("%d%d", &p[i], &q[i]);

        /*
          如果当前已有芯片的第p位是1，
          那么q号耗材已经存在
        */
        if(now & (1ULL << p[i]))
        {
            have[q[i]] = 1;
        }
    }


    /*
        bad[i]=1表示第i位不能出现1
    */
    int bad[65] = {0};


    for(int i = 0; i < m; i++)
    {
        /*
          第p位如果为1会需要q耗材，
          但是q耗材目前没有，
          所以这个位不能再出现1
        */
        if(!have[q[i]])
        {
            bad[p[i]] = 1;
        }
    }
    int cnt = 0;

    for(int i = 0; i < k; i++)
    {
        if(!bad[i])
            cnt++;
    }


    ull ans = 1ULL << cnt;


    ans -= n;


    printf("%llu\n", ans);


    return 0;
}