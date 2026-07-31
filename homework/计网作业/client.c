#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <arpa/inet.h>

#define SERVER_IP "127.0.0.1"
#define PORT 8888
#define BUFFER_SIZE 1024

void *receive_message(void *arg) {
    int client_socket = *(int *)arg;
    char buffer[BUFFER_SIZE];

    while (1) {
        memset(buffer, 0, sizeof(buffer));

        int received = recv(client_socket, buffer, sizeof(buffer), 0);

        if (received <= 0) {
            printf("与服务器断开连接。\n");
            break;
        }

        printf("%s", buffer);
    }

    return NULL;
}

int main() {
    int client_socket;
    struct sockaddr_in server_addr;
    char username[50];
    char buffer[BUFFER_SIZE];

    client_socket = socket(AF_INET, SOCK_STREAM, 0);

    if (client_socket < 0) {
        perror("socket 创建失败");
        exit(1);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = inet_addr(SERVER_IP);

    if (connect(client_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("连接服务器失败");
        close(client_socket);
        exit(1);
    }

    printf("请输入用户名：");
    fgets(username, sizeof(username), stdin);
    send(client_socket, username, strlen(username), 0);

    pthread_t receive_thread;
    pthread_create(&receive_thread, NULL, receive_message, &client_socket);
    pthread_detach(receive_thread);

    printf("\n命令说明：\n");
    printf("/private 用户名 消息内容\n");
    printf("/join 群名\n");
    printf("/group 群名 消息内容\n");
    printf("/broadcast 消息内容\n");
    printf("/quit\n\n");

    while (1) {
        memset(buffer, 0, sizeof(buffer));
        fgets(buffer, sizeof(buffer), stdin);

        send(client_socket, buffer, strlen(buffer), 0);

        if (strncmp(buffer, "/quit", 5) == 0) {
            break;
        }
    }

    close(client_socket);
    return 0;
}