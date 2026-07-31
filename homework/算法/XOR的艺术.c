#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define maxn 200005
int n, m;
char str[maxn];

typedef struct {
	int cnt1;
	int cnt0;
	int lazy;
} Node;

Node tr[4 * maxn];

void swap(int* a, int* b) {
	int tmp = *a;
	*a = *b;
	*b = tmp;
}

void push_up(int x) {
	tr[x].cnt0 = tr[x << 1].cnt0 + tr[x << 1 | 1].cnt0;
	tr[x].cnt1 = tr[x << 1].cnt1 + tr[x << 1 | 1].cnt1;
}
void push_down(int x){
    if (tr[x].lazy) {
		swap(&tr[x << 1].cnt0, &tr[x << 1].cnt1);
		swap(&tr[x << 1 | 1].cnt0, &tr[x << 1 | 1].cnt1);
		tr[x << 1].lazy ^= 1;
		tr[x << 1 | 1].lazy ^= 1;
		tr[x].lazy = 0;
	}
}
void build(int x, int l, int r) {
	if (l == r) {
		if (str[l] == '1') {
			tr[x].cnt0 = 0;
			tr[x].cnt1 = 1;
		} else {
			tr[x].cnt0 = 1;
			tr[x].cnt1 = 0;
		}
		tr[x].lazy = 0;
		return;
	}
	int mid = (l + r) >> 1;
	build(x << 1, l, mid);
	build(x << 1 | 1, mid + 1, r);
	push_up(x);
}

int query(int x, int l, int r, int s, int t) {
	if (l <= s && t <= r) {
		return tr[x].cnt1;
	}
	push_down(x);
	int mid = (s + t) >> 1;
	int sum = 0;
	if (l <= mid) sum += query(x << 1, l, r, s, mid);
	if (r > mid) sum += query(x << 1 | 1, l, r, mid + 1, t);
	return sum;
}

void update(int x, int l, int r, int s, int t) {
	if (l <= s && t <= r) {
		swap(&tr[x].cnt0, &tr[x].cnt1);
		tr[x].lazy ^= 1;
		return;
	}
	push_down(x);
	int mid = (s + t) >> 1;
	if (l <= mid) update(x << 1, l, r, s, mid);
	if (r > mid) update(x << 1 | 1, l, r, mid + 1, t);
	push_up(x);
}

int main() {
	scanf("%d %d", &n, &m);
	for (int i = 1; i <= n; i++) {
		scanf(" %c", &str[i]);
	}
	build(1, 1, n);
	while (m--) {
		int op, l, r;
		scanf("%d%d%d", &op, &l, &r);
		if (op == 0) {
			update(1, l, r, 1, n);
		} else {
			int ans = query(1, l, r, 1, n);
			printf("%d\n", ans);
		}
	}
	return 0;
}
