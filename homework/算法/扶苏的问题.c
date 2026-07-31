#include <stdio.h>
#include <stdlib.h>
#include <string.h> 
#include <limits.h>
#define maxn 1000005
typedef struct{
	long long maxval;
	long long lazy_add;
	long long lazy_set; 
}Node;
long long arr[maxn]; // 全局数组改为 long long
Node tree[maxn*4];

long long max1(long long a,long long b){
	if(a>b)return a;
	return b;
}

void push_up(int rt){
	tree[rt].maxval=max1(tree[rt<<1].maxval,tree[rt<<1|1].maxval);
}

void build(int l,int r,int rt){
	tree[rt].lazy_set=-1;
	tree[rt].lazy_add=0;
	if(l==r){
		tree[rt].maxval=arr[l];
		return;
	}
	int mid=(l+r)>>1;
	build(l,mid,rt<<1);
	build(mid+1,r,rt<<1|1);
	push_up(rt);
}

void push_down(int rt) {
    if (tree[rt].lazy_set != -1) {
        tree[rt << 1].maxval = tree[rt].lazy_set;
        tree[rt << 1].lazy_set = tree[rt].lazy_set;
        tree[rt << 1].lazy_add = 0;
        
        tree[rt << 1 | 1].maxval = tree[rt].lazy_set;
        tree[rt << 1 | 1].lazy_set = tree[rt].lazy_set;
        tree[rt << 1 | 1].lazy_add = 0;
        
        tree[rt].lazy_set = -1;
    }
    if (tree[rt].lazy_add != 0) {
        
        tree[rt << 1].maxval += tree[rt].lazy_add;
        tree[rt << 1].lazy_add += tree[rt].lazy_add;
        
        tree[rt << 1 | 1].maxval += tree[rt].lazy_add;
        tree[rt << 1 | 1].lazy_add += tree[rt].lazy_add;
        
        tree[rt].lazy_add = 0; 
    }
}
long long query(int l,int r,int L,int R,int rt){
	if (r < L || l > R) return LLONG_MIN;
	if(L<=l&&r<=R){
		return tree[rt].maxval;
	}
	push_down(rt);
	int mid=(l+r)>>1;
	
	return max1(query(l, mid, L, R, rt << 1), query(mid + 1, r, L, R, rt << 1 | 1));
}

void update2(int L,int R, long long val, int l, int r, int rt) {

    if (L<=l&&r<=R) {
        tree[rt].maxval += val; 
        tree[rt].lazy_add+=val;
        return;
    }
    push_down(rt);
    int mid = (l + r) >> 1;
    if (L <= mid) {
        update2(L,R,val, l, mid, rt << 1);
    } 
	if(R>mid){
        update2(L,R, val, mid + 1, r, rt << 1 | 1);
    }
    
    push_up(rt);
}
void update1(int L,int R, long long val, int l, int r, int rt){
	if (L<=l&&r<=R) {
        tree[rt].maxval = val; 
        tree[rt].lazy_set=val;
        tree[rt].lazy_add=0;
        return;
    }
    push_down(rt);
    int mid = (l + r) >> 1;
    if (L <= mid) {
        update1(L,R,val, l, mid, rt << 1);
    } 
	if(R>mid){
        update1(L,R, val, mid + 1, r, rt << 1 | 1);
    }
    
    push_up(rt);
}
int main(){
    int n, q;
    scanf("%d%d", &n, &q); 
    
    for(int i = 1; i <= n; i++){
        scanf("%lld", &arr[i]);
    }
    build(1,n,1);
    for(int i = 0; i < q; i++){
        int op, l, r;
        scanf("%d%d%d", &op, &l, &r);
        long long x;
        
        if(op == 1){
            scanf("%lld", &x);
            update1(l,r,x,1,n,1);
        }
        else if(op == 2){
            scanf("%lld", &x);
            update2(l,r,x,1,n,1);
        }
        else{

           long long maxv=query(1,n,l,r,1);
            printf("%lld\n", maxv);
        }
    }
    return 0;
} 
