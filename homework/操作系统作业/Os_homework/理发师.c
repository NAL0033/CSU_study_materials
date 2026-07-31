#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore>
#include <time.h>

#define N 5//等待椅数量
#define CUSTOMER_NUM 15//顾客数量

sem_t chairs;//空椅子数量，初值n
sem_t barbersleep;//理发师睡眠信号
sem_t mutex;//互斥信号量

int m = 0;//当前等待人数

void cut_hair(int id) {
	printf("Barber is cutting hair for customer %d...", id);
	sleep(2);
	printf("Barber finished customer %d\n", id);
}
void* barber(void* arg) {
	while (1) {
		sem_wait(&barbersleep);
		sem_wait(&mutex);
		if (m > 0) {
			m = m - 1;
			printf("Barber wakes up,one customer starts haircut.Waiting customer=%d\n", m);
		}
		sem_post(&mutex);
		sem_post(&chairs);
		sleep(2);
		printf("Barber finished one haircut.\n");
	}
	return NULL;
}
void* customer(void* arg) {
	int id = *(int*)arg;
	free(arg);

	sem_wait(&mutex);
	if (m >= N) {
		printf("Customer %d leaves because no chair is available.\n", id);
		sem_post(&mutex);
		return NULL;
	}

	m = m + 1;
	printf("Customer %d enters shop and waits. Waiting customers = %d\n", id, m);
	sem_post(&mutex);

	sem_wait(&chairs);            // 占用一把椅子
	sem_post(&barbersleep);       // 唤醒理发师

	printf("Customer %d is getting haircut.\n", id);

	return NULL;
}
int main() {
	pthread_t barber_tid;
	pthread_t customer_tid[CUSTOMER_NUM];
	srand((unsigned int)time(NULL));
	sem_init(&chairs, 0, N);
	sem_init(&barbersleep, 0, 0);
	sem_init(&mutex, 0, 1);
	pthread_create(&barber_tid, NULL, barber, NULL);
	for (int i = 0; i < CUSTOMER_NUM; i++) {
		int* id = (int*)malloc(sizeof(int));
		*id = i + 1;
		pthread_create(&customer_tid[i], NULL, customer, id);
		sleep(rand() % 2);//模拟顾客随机达到
	}
	for (int i = 0; i < CUSTOMER_NUM; i++) {
		pthread_join(customer_tid[i], NULL);
	}
	sleep(10);
	sem_destroy(&chairs);
	sem_destroy(&barbersleep);
	sem_destroy(&mutex);
	return 0;
}