/* GlobalCharTest.c */
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#define DEV_NAME "/dev/GlobalChar"
 
int main()
{
  int fd, num;
 
  /* 打开设备文件 */
  fd = open(DEV_NAME, O_RDWR, S_IRUSR | S_IWUSR);
  if (fd<0) {
    printf("Open Deivce Fail!\n");
    return -1;
  }
 
  /* 读取当前设备数值 */
  read(fd, &num, sizeof(int));
  printf("The GlobalChar is %d\n", num);
 
  printf("Please input a number written to GlobalChar: ");
  scanf("%d", &num);
 
  /* 写入新的数值 */
  write(fd, &num, sizeof(int));
 
  /* 重新读取设备数值 */
  read(fd, &num, sizeof(int));
  printf("The GlobalChar is %d\n", num);
 
  close(fd);
  return 0;
}