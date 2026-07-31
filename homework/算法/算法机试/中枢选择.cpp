#include <stdio.h>
#include <stdlib.h>

#define MAXN 1000005
#define MAXM 2000005

int n;

/* 链式前向星 */
int head[MAXN];
int to[MAXM];
int next[MAXM];
int cnt = 0;

/* 树信息 */
int fa[MAXN];
int sz[MAXN];
long long dp[MAXN];

/* 非递归DFS需要 */
int stack[MAXN];
int order[MAXN];
int top = 0;

/* 加边 */
void add_edge(int u,int v)
{
    to[cnt] = v;
    next[cnt] = head[u];
    head[u] = cnt++;
}

int main()
{
    scanf("%d",&n);
    // 初始化
    for(int i=1;i<=n;i++)
        head[i] = -1;

    // 建树
    for(int i=1;i<n;i++)
    {
        int u,v;
        scanf("%d%d",&u,&v);
        add_edge(u,v);
        add_edge(v,u);
    }

    /* 第一次遍历：求父节点和访问顺序 */
    int sp=0;
    stack[sp++]=1;
    fa[1]=0;

    while(sp)
    {
        int u=stack[--sp];
        order[top++]=u;

        for(int i=head[u];i!=-1;i=next[i])
        {
            int v=to[i];
            if(v==fa[u]) continue;
            fa[v]=u;
            stack[sp++]=v;
        }
    }

    /* 倒序求 sz[u] 和 dp[u] */
    for(int i=top-1;i>=0;i--)
    {
        int u=order[i];
        sz[u]=1;

        for(int e=head[u];e!=-1;e=next[e])
        {
            int v=to[e];
            if(v==fa[u]) continue;
            sz[u]+=sz[v];
            dp[u]+=dp[v]+sz[v];
        }
    }

    /* 第二次遍历：换根DP */
    for(int i=0;i<top;i++)
    {
        int u=order[i];

        for(int e=head[u];e!=-1;e=next[e])
        {
            int v=to[e];
            if(v==fa[u]) continue;
            dp[v]=dp[u]-sz[v]+(n-sz[v]);
        }
    }

    /* 找最大收益，相同取编号小 */
    long long ans=-1;
    int id=1;

    for(int i=1;i<=n;i++)
    {
        if(dp[i]>ans)
        {
            ans=dp[i];
            id=i;
        }
    }

    printf("%d\n",id);
    return 0;
}
