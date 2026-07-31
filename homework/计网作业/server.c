#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <arpa/inet.h>

#define PORT 8888
#define MAX_CLIENTS 100
#define MAX_GROUPS 20
#define BUFFER_SIZE 1024

typedef struct {
    int socket_fd;
    char username[50];
} Client;

typedef struct {
    char group_name[50];
    char members[MAX_CLIENTS][50];
    int member_count;
} Group;

Client clients[MAX_CLIENTS];
Group groups[MAX_GROUPS];

int client_count = 0;
int group_count = 0;

pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

void trim_newline(char *str) {
    str[strcspn(str, "\n")] = '\0';
}

void send_message(int socket_fd, const char *message) {
    send(socket_fd, message, strlen(message), 0);
}

int find_client_index(const char *username) {
    for (int i = 0; i < client_count; i++) {
        if (strcmp(clients[i].username, username) == 0) {
            return i;
        }
    }
    return -1;
}

int find_group_index(const char *group_name) {
    for (int i = 0; i < group_count; i++) {
        if (strcmp(groups[i].group_name, group_name) == 0) {
            return i;
        }
    }
    return -1;
}

int is_member(int group_index, const char *username) {
    for (int i = 0; i < groups[group_index].member_count; i++) {
        if (strcmp(groups[group_index].members[i], username) == 0) {
            return 1;
        }
    }
    return 0;
}

void private_chat(const char *sender, char *target, char *content) {
    pthread_mutex_lock(&mutex);

    int target_index = find_client_index(target);

    if (target_index != -1) {
        char message[BUFFER_SIZE];
        snprintf(message, sizeof(message), "[私聊] %s: %s\n", sender, content);
        send_message(clients[target_index].socket_fd, message);
    } else {
        int sender_index = find_client_index(sender);
        if (sender_index != -1) {
            send_message(clients[sender_index].socket_fd, "目标用户不存在。\n");
        }
    }

    pthread_mutex_unlock(&mutex);
}

void join_group(const char *username, char *group_name) {
    pthread_mutex_lock(&mutex);

    int group_index = find_group_index(group_name);

    if (group_index == -1) {
        if (group_count >= MAX_GROUPS) {
            int user_index = find_client_index(username);
            if (user_index != -1) {
                send_message(clients[user_index].socket_fd, "群组数量已达上限。\n");
            }
            pthread_mutex_unlock(&mutex);
            return;
        }

        strcpy(groups[group_count].group_name, group_name);
        groups[group_count].member_count = 0;
        group_index = group_count;
        group_count++;
    }

    if (!is_member(group_index, username)) {
        strcpy(groups[group_index].members[groups[group_index].member_count], username);
        groups[group_index].member_count++;
    }

    int user_index = find_client_index(username);
    if (user_index != -1) {
        char message[BUFFER_SIZE];
        snprintf(message, sizeof(message), "你已加入群组：%s\n", group_name);
        send_message(clients[user_index].socket_fd, message);
    }

    pthread_mutex_unlock(&mutex);
}

void group_chat(const char *sender, char *group_name, char *content) {
    pthread_mutex_lock(&mutex);

    int group_index = find_group_index(group_name);
    int sender_index = find_client_index(sender);

    if (group_index == -1) {
        if (sender_index != -1) {
            send_message(clients[sender_index].socket_fd, "群组不存在。\n");
        }
        pthread_mutex_unlock(&mutex);
        return;
    }

    if (!is_member(group_index, sender)) {
        if (sender_index != -1) {
            send_message(clients[sender_index].socket_fd, "你尚未加入该群组。\n");
        }
        pthread_mutex_unlock(&mutex);
        return;
    }

    char message[BUFFER_SIZE];
    snprintf(message, sizeof(message), "[群聊:%s] %s: %s\n", group_name, sender, content);

    for (int i = 0; i < groups[group_index].member_count; i++) {
        if (strcmp(groups[group_index].members[i], sender) != 0) {
            int member_index = find_client_index(groups[group_index].members[i]);
            if (member_index != -1) {
                send_message(clients[member_index].socket_fd, message);
            }
        }
    }

    pthread_mutex_unlock(&mutex);
}

void broadcast_chat(const char *sender, char *content) {
    pthread_mutex_lock(&mutex);

    char message[BUFFER_SIZE];
    snprintf(message, sizeof(message), "[广播] %s: %s\n", sender, content);

    for (int i = 0; i < client_count; i++) {
        if (strcmp(clients[i].username, sender) != 0) {
            send_message(clients[i].socket_fd, message);
        }
    }

    pthread_mutex_unlock(&mutex);
}

void remove_client(const char *username) {
    pthread_mutex_lock(&mutex);

    int index = find_client_index(username);

    if (index != -1) {
        close(clients[index].socket_fd);

        for (int i = index; i < client_count - 1; i++) {
            clients[i] = clients[i + 1];
        }

        client_count--;
    }

    for (int i = 0; i < group_count; i++) {
        for (int j = 0; j < groups[i].member_count; j++) {
            if (strcmp(groups[i].members[j], username) == 0) {
                for (int k = j; k < groups[i].member_count - 1; k++) {
                    strcpy(groups[i].members[k], groups[i].members[k + 1]);
                }
                groups[i].member_count--;
                break;
            }
        }
    }

    pthread_mutex_unlock(&mutex);
}

void *handle_client(void *arg) {
    int client_socket = *(int *)arg;
    free(arg);

    char username[50];
    char buffer[BUFFER_SIZE];

    memset(username, 0, sizeof(username));
    int bytes = recv(client_socket, username, sizeof(username), 0);

    if (bytes <= 0) {
        close(client_socket);
        return NULL;
    }

    trim_newline(username);

    pthread_mutex_lock(&mutex);

    if (client_count >= MAX_CLIENTS) {
        send_message(client_socket, "服务器人数已满。\n");
        close(client_socket);
        pthread_mutex_unlock(&mutex);
        return NULL;
    }

    strcpy(clients[client_count].username, username);
    clients[client_count].socket_fd = client_socket;
    client_count++;

    pthread_mutex_unlock(&mutex);

    printf("用户 %s 已连接。\n", username);
    send_message(client_socket, "连接服务器成功。\n");

    while (1) {
        memset(buffer, 0, sizeof(buffer));

        int received = recv(client_socket, buffer, sizeof(buffer), 0);

        if (received <= 0) {
            break;
        }

        trim_newline(buffer);

        if (strcmp(buffer, "/quit") == 0) {
            break;
        }

        if (strncmp(buffer, "/private ", 9) == 0) {
            char *target = strtok(buffer + 9, " ");
            char *content = strtok(NULL, "");

            if (target != NULL && content != NULL) {
                private_chat(username, target, content);
            } else {
                send_message(client_socket, "格式错误：/private 用户名 消息内容\n");
            }
        } else if (strncmp(buffer, "/join ", 6) == 0) {
            char *group_name = buffer + 6;

            if (strlen(group_name) > 0) {
                join_group(username, group_name);
            } else {
                send_message(client_socket, "格式错误：/join 群名\n");
            }
        } else if (strncmp(buffer, "/group ", 7) == 0) {
            char *group_name = strtok(buffer + 7, " ");
            char *content = strtok(NULL, "");

            if (group_name != NULL && content != NULL) {
                group_chat(username, group_name, content);
            } else {
                send_message(client_socket, "格式错误：/group 群名 消息内容\n");
            }
        } else if (strncmp(buffer, "/broadcast ", 11) == 0) {
            char *content = buffer + 11;

            if (strlen(content) > 0) {
                broadcast_chat(username, content);
            } else {
                send_message(client_socket, "格式错误：/broadcast 消息内容\n");
            }
        } else {
            send_message(client_socket, "未知命令。\n");
        }
    }

    printf("用户 %s 已断开连接。\n", username);
    remove_client(username);

    return NULL;
}

int main() {
    int server_socket;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_addr_len = sizeof(client_addr);

    server_socket = socket(AF_INET, SOCK_STREAM, 0);

    if (server_socket < 0) {
        perror("socket 创建失败");
        exit(1);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("bind 失败");
        close(server_socket);
        exit(1);
    }

    if (listen(server_socket, 10) < 0) {
        perror("listen 失败");
        close(server_socket);
        exit(1);
    }

    printf("服务器已启动，监听端口 %d\n", PORT);

    while (1) {
        int *client_socket = malloc(sizeof(int));
        *client_socket = accept(server_socket, (struct sockaddr *)&client_addr, &client_addr_len);

        if (*client_socket < 0) {
            perror("accept 失败");
            free(client_socket);
            continue;
        }

        pthread_t tid;
        pthread_create(&tid, NULL, handle_client, client_socket);
        pthread_detach(tid);
    }

    close(server_socket);
    return 0;
}