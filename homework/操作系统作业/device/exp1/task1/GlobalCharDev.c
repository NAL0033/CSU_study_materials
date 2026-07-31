/* GlobalCharDev.c */
#include <linux/module.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
//copy_from_user  copy_to_user
 
MODULE_LICENSE("GPL");
MODULE_AUTHOR("GongLei");
 
#define DEV_NAME "GlobalChar"
 
/*********函数声明*********/
static ssize_t GlobalRead(struct file *, char *, size_t, loff_t*);
static ssize_t GlobalWrite(struct file *, const char *, size_t, loff_t*);
 
static int char_major = 0;//主设备号为0，表示由内核自动分配主设备号
static int GlobalData = 0;  // "GlobalChar" 设备的全局变量
 
//初始化字符设备驱动的file_operations结构体
struct file_operations globalchar_fops =
{
  .read = GlobalRead,
  .write = GlobalWrite
};
 
 
/* 模块初始化函数  执行insmod命令时候执行这个函数 */
static int __init GlobalChar_init(void)
{
  int ret;
 
  ret = register_chrdev(char_major, DEV_NAME, &globalchar_fops); 	// 注册设备驱动
  if (ret<0) 
  {
    printk(KERN_ALERT "GlobalChar Reg Fail!\n");
  } 
  else
  {
    printk(KERN_ALERT "GlobalChar Reg Success!\n");
    char_major = ret;
    printk(KERN_ALERT "Major = %d\n", char_major);
  }
  return ret;
}
 
/* 模块卸载函数  执行rmmod命令时候执行这个函数 */
static void __exit GlobalChar_exit(void)
{
  unregister_chrdev(char_major, DEV_NAME); 						// 注销设备驱动
  return;
}
 
/* 设备驱动读函数 */
static ssize_t GlobalRead(struct file *filp, char *buf, size_t len, loff_t *off)
{
  if (copy_to_user(buf, &GlobalData, sizeof(int))) 
  {		// 从内核空间复制GlobalData到用户空间
    return -EFAULT;
  }
  return sizeof(int);
}
 
/* 设备驱动写函数 */
static ssize_t GlobalWrite(struct file *filp, const char *buf, size_t len, loff_t *off)
{
  if (copy_from_user(&GlobalData, buf, sizeof(int)))
  {	// 从用户空间复制GlobalData到内核空间
    return -EFAULT;
  }
  return sizeof(int);
}
 
module_init(GlobalChar_init);
module_exit(GlobalChar_exit);