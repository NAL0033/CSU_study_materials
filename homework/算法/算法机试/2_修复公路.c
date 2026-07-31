#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAXN 100005

typedef struct{
    int x,y,t;
}Edge;
Edge edge[MAXN];
int fa[MAXN];
int cmp(const void *a,const void *b){
    Edge *u=(Edge*)a;
    Edge *v=(Edge*)b;
    return u->t-v->t;
}
int find(int x){
    if(x!=fa[x]){
        return find(fa[x]);
    }
    return fa[x];
}
int main(){
    int N,M;
    scanf("%d%d",&N,&M);
    for(int i=1;i<=N;i++){
        fa[i]=i;
    }
    for(int i=0;i<M;i++){
        int u,v;
        scanf("%d%d%d",&edge[i].x,&edge[i].y,&edge[i].t);
    }
    qsort(edge,M,sizeof(edge),cmp);
    for(int i=0;i<M;i++){
        int x=find(edge[i].x);
        int y=find(edge[i].y);
        if(x!=y){
            fa[x]=y;
            N--;
            if(N==1)printf("%d",edge[i].t);
            return 0;
        }
    }
    printf("-1");
}