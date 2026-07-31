#include <stdio.h>
#include <stdlib.h>
int parent[1005];
typedef struct{
	int x;
	int y;
	int t;
}edge;
int cmp(const void*a,const void*b){
	edge *e1=(edge*)a;
	edge *e2=(edge*)b;
	return e1-e2;
}
int find(int x){
	if(parent[x]!=x){
		return find(parent[x]);
	}
	return parent[x];
}
int main(){
	int N,M;//Nµã£¬M±ß
	scanf("%d%d",&N,&M);
	edge arr[M];
	int parent[N];
	for(int i=0;i<M;i++){
		scanf("%d %d %d",&arr[i].x,&arr[i].y,arr[i].t);
	}
	for (int i = 1; i <= N; i++) {
        parent[i] = i;
    }
    int n=N;
	qsort(arr,M,sizeof(edge),cmp);
	for(int i=0;i<M;i++){
		int fx=find(arr[i].x);
		int fy=find(arr[i].y);
		if(fx!=fy){
			parent[fx]=fy;
			n--;
			if(n==1){
				printf("%d",arr[i].t);
				return 0;
			}
		}
	}
	printf("-1\n");
	return 0;
}
