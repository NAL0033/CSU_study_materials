#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAXN 100005
#define MOD 99999997

typedef struct{
    int h;
    int pos;
}Node;

Node A[MAXN], B[MAXN];

int p[MAXN];
int tree[MAXN];
int n;

int cmp(const void*a,const void*b){
    Node *p=(Node*)a;
    Node *q=(Node*)b;
    return p->h-q->h;
}
int lowbit(int x){
    return x&-x;
}
void add(int x){
    for(int i=x;i<=n;i+=lowbit(i)){
        tree[i]++;
    }
}
int sum(int x){
    int s=0;
    for(int i=x;i>0;i-=lowbit(i)){
        s+=tree[i];
    }
    return s;
}
int main(){
    scanf("%d", &n);
    for (int i = 1; i <= n; i++)
    {
        scanf("%d", &A[i].h);
        A[i].pos = i;
    }

    for (int i = 1; i <= n; i++)
    {
        scanf("%d", &B[i].h);
        B[i].pos = i;
    }
    qsort(A+1,n,sizeof(Node),cmp);
    qsort(B+1,n,sizeof(Node),cmp);

    for(int i=1;i<=n;i++){
        p[A[i].pos]=B[i].pos;
    }

    long long ans=0;
    for(int i=n;i>=1;i--){
        ans=(ans+sum(p[i]-1))%MOD;
        add(p[i]);
    }
    printf("%lld",ans);
}