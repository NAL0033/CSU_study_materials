#include <stdio.h>

#define MAXN 100005
#define MAXBIT 20

int a[MAXN];

typedef struct
{
    int cnt[MAXBIT];
    int lazy;
}Node;

Node tree[MAXN<<2];

void pushup(int rt) 
{
    for(int i=0;i<MAXBIT;i++)
        tree[rt].cnt[i]=tree[rt<<1].cnt[i]+tree[rt<<1|1].cnt[i];
}

void build(int rt,int l,int r)
{
    tree[rt].lazy=0;

    if(l==r)
    {
        for(int i=0;i<MAXBIT;i++)
            tree[rt].cnt[i]=(a[l]>>i)&1;
        return;
    }

    int mid=(l+r)>>1;

    build(rt<<1,l,mid);
    build(rt<<1|1,mid+1,r);

    pushup(rt);
}

void apply(int rt,int l,int r,int x)
{
    int len=r-l+1;

    for(int i=0;i<MAXBIT;i++)
    {
        if((x>>i)&1)
            tree[rt].cnt[i]=len-tree[rt].cnt[i];
    }

    tree[rt].lazy^=x;
}

void pushdown(int rt,int l,int r)
{
    if(tree[rt].lazy==0)
        return;

    int mid=(l+r)>>1;

    apply(rt<<1,l,mid,tree[rt].lazy);
    apply(rt<<1|1,mid+1,r,tree[rt].lazy);

    tree[rt].lazy=0;
}

void update(int rt,int l,int r,int L,int R,int x)
{
    if(L<=l&&r<=R)
    {
        apply(rt,l,r,x);
        return;
    }

    pushdown(rt,l,r);

    int mid=(l+r)>>1;

    if(L<=mid)
        update(rt<<1,l,mid,L,R,x);

    if(R>mid)
        update(rt<<1|1,mid+1,r,L,R,x);

    pushup(rt);
}

long long query(int rt,int l,int r,int L,int R)
{
    if(L<=l&&r<=R)
    {
        long long ans=0;

        for(int i=0;i<MAXBIT;i++)
            ans+=(1LL<<i)*tree[rt].cnt[i];

        return ans;
    }

    pushdown(rt,l,r);

    int mid=(l+r)>>1;

    long long ans=0;

    if(L<=mid)
        ans+=query(rt<<1,l,mid,L,R);

    if(R>mid)
        ans+=query(rt<<1|1,mid+1,r,L,R);

    return ans;
}

int main()
{
    int n;

    scanf("%d",&n);

    for(int i=1;i<=n;i++)
        scanf("%d",&a[i]);

    build(1,1,n);

    int m;

    scanf("%d",&m);

    while(m--)
    {
        int op;

        scanf("%d",&op);

        if(op==1)
        {
            int l,r;

            scanf("%d%d",&l,&r);

            printf("%lld\n",query(1,1,n,l,r));
        }
        else
        {
            int l,r,x;

            scanf("%d%d%d",&l,&r,&x);

            update(1,1,n,l,r,x);
        }
    }

    return 0;
}