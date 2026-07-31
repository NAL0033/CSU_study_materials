#include <stdio.h>
#include <string.h>

#define MAXN 105
#define INF 0x3f3f3f3f

int n;
int w[MAXN][MAXN];

int lx[MAXN], ly[MAXN];
int match[MAXN];
int slack[MAXN];
int visx[MAXN], visy[MAXN];

int dfs(int x)
{
    visx[x] = 1;
    for (int y = 1; y <= n; y++)
    {
        if (visy[y]) continue;

        int t = lx[x] + ly[y] - w[x][y];

        if (t == 0)
        {
            visy[y] = 1;
            if (match[y] == 0 || dfs(match[y]))
            {
                match[y] = x;
                return 1;
            }
        }
        else if (t < slack[y])
        {
            slack[y] = t;
        }
    }
    return 0;
}

int KM()
{
    memset(ly, 0, sizeof(ly));
    memset(match, 0, sizeof(match));

    for (int i = 1; i <= n; i++)
    {
        lx[i] = w[i][1];
        for (int j = 2; j <= n; j++)
            if (w[i][j] > lx[i])
                lx[i] = w[i][j];
    }

    for (int x = 1; x <= n; x++)
    {
        for (int i = 1; i <= n; i++)
            slack[i] = INF;

        while (1)
        {
            memset(visx, 0, sizeof(visx));
            memset(visy, 0, sizeof(visy));

            if (dfs(x))
                break;

            int d = INF;
            for (int i = 1; i <= n; i++)
                if (!visy[i] && slack[i] < d)
                    d = slack[i];

            for (int i = 1; i <= n; i++)
            {
                if (visx[i]) lx[i] -= d;
                if (visy[i]) ly[i] += d;
                else slack[i] -= d;
            }
        }
    }

    int ans = 0;
    for (int i = 1; i <= n; i++)
        ans += w[match[i]][i];

    return ans;
}

int main()
{
    scanf("%d", &n);

    int a[MAXN][MAXN];
    int mx = 0;

    for (int i = 1; i <= n; i++)
    {
        for (int j = 1; j <= n; j++)
        {
            scanf("%d", &a[i][j]);
            if (a[i][j] > mx)
                mx = a[i][j];
        }
    }

    // 求最大值
    for (int i = 1; i <= n; i++)
        for (int j = 1; j <= n; j++)
            w[i][j] = a[i][j];

    int MaxAns = KM();

    // 求最小值
    for (int i = 1; i <= n; i++)
        for (int j = 1; j <= n; j++)
            w[i][j] = mx - a[i][j];

    int MinAns = n * mx - KM();

    printf("%d\n", MinAns);
    printf("%d\n", MaxAns);

    return 0;
}