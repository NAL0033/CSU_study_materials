#include <linux/init.h>     //定义了module_init
#include <linux/module.h>   //最基本的头文件，其中定义了MODULE_LICENSE这一类宏
#include <linux/fs.h>       // file_operations结构体定义在该头文件中

static const char* dev_name = "first_driver";  //  定义设备名
static unsigned int major = 55;               //定义设备号

//定义了open函数
static int first_drv_open (struct inode *inode, struct file *file)
{
        printk("open\n");
        return 0;
}

//定义了write函数
static ssize_t first_drv_write (struct file *file, const char __user *buf, size_t size, loff_t * ppos)
{
        printk("write\n");
        return 0;
}

//在file_operations中注册open和write函数
static struct file_operations first_drv_fo =
{
        .owner  =  THIS_MODULE,

        //将对应的函数关联在file_operations的结构体中
        .open   =  first_drv_open,      
        .write  =  first_drv_write,
};

//init驱动的入口函数
static int first_drv_init(void)
{      
        //注册设备，实际是将file_operations结构体放到内核的制定数组中，以便管理
        //在register_chrdev中制定major作为主设备号
        register_chrdev(major, dev_name , &first_drv_fo);
        printk("init\n");
        if(dev_id < 0) 
            printk("error\n");
        return 0;
}

//驱动的出口函数
static void first_drv_exit(void)
{
        printk("exit\n");
        unregister_chrdev(major, dev_name);  //卸载设备，实际是将file_operations结构体从内核维护的相关数组中以主设备号作为索引删除
}

//内核将通过这个宏，来直到这个驱动的入口和出口函数
module_init(first_drv_init);  
module_exit(first_drv_exit);

MODULE_AUTHOR("Ethan Lee <4128127@qq.com>");
MODULE_LICENSE("GPL");  //指定协议