#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>

int main() {
    int fd[2];
    pid_t pid;
    char write_msg[] = "Hello from parent process";
    char read_msg[100];

    if (pipe(fd) == -1) {
        perror("pipe failed");
        exit(1);
    }

    pid = fork();

    if (pid < 0) {
        perror("fork failed");
        exit(1);
    }
    else if (pid > 0) {
        // 父进程写
        close(fd[0]);
        write(fd[1], write_msg, strlen(write_msg) + 1);
        close(fd[1]);
    }
    else {
        // 子进程读
        close(fd[1]);
        read(fd[0], read_msg, sizeof(read_msg));
        printf("Child process received: %s\n", read_msg);
        close(fd[0]);
    }

    return 0;
}