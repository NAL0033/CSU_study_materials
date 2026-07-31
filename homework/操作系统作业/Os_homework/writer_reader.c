#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore>
#define READER_NUM 5
#define WRITER_NUM 2
sem_t mutex;
sem_t wrt;
int readcount = 0;
void* reader(void* args) {
	int id = *(int*)arg;
	free(arg);
	while (1) {
		sem_wait(&mutex);
		readcount++;
		if (readcount == 1)sem_wait(&wrt);
		sem_post(&mutex);
		printf("Reader %d is reading\n", id);
		sleep(1);
		sem_wait(&mutex);
		readcount--;
		if (readcount == 0)sem_post(&wrt);
		sem_post(&mutex);
		sleep(1);
	}
}
void* writer(void* arg) {
	int id = *(int*)arg;
	free(arg);
	while (1) {
		sem_wait(&wrt);
		printf("Writer %d is writing\n", id);
		sleep(2);
		sem_post(&wrt);
		sleep(2);
	}
}
int main() {
	pthread_t r[READER_NUM], w[WRITER_NUM];
	sem_init(&mutex, 0, 1);
	sem_init(&wrt, 0, 1);
	for (int i = 0; i < READER_NUM; i++) {
		int* id = malloc(sizeof(int));
		*id = i + 1;
		pthread_create(&r[i], NULL, reader, id);
	}
	for (int i = 0; i < WRITER_NUM; i++) {
		int* id = malloc(sizeof(int));
		*id = i + 1;
		pthread_create(&w[i], NULL, writer, id);
	}
	for (int i = 0; i < READER_NUM; i++)
		pthread_join(r[i], NULL);

	for (int i = 0; i < WRITER_NUM; i++)
		pthread_join(w[i], NULL);

	return 0;
}