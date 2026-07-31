#include <linux/module.h>
#include <linux/errno.h>
#include <linux/interrupt.h>
#include <linux/mm.h>
#include <linux/fs.h>
#include <linux/kernel.h>
#include <linux/timer.h>
#include <linux/genhd.h>
#include <linux/hdreg.h>
#include <linux/ioport.h>
#include <linux/init.h>
#include <linux/wait.h>
#include <linux/blkdev.h>
#include <linux/mutex.h>
#include <linux/blkpg.h>
#include <linux/delay.h>
#include <linux/io.h>
#include <linux/gfp.h>

#include <asm/uaccess.h>
#include <asm/dma.h>


#define RAMBLOCK_SIZE (1024*1024)

static int major = 0;

static char *ramblock_buf;

static DEFINE_SPINLOCK(ramblock_lock);

static struct gendisk *ramblock_disk;

static struct request_queue *ramblock_queue;


static int ramblock_getgeo(struct block_device *bdev, struct hd_geometry *geo)
{
    /* 总容量 = 盘面数 * 柱面数 * 扇区数 * 512 */
    geo->heads = 4;
    geo->cylinders = 32;
    geo->sectors = RAMBLOCK_SIZE/geo->heads/geo->cylinders/512;
    return 0;
}


static struct block_device_operations ramblock_fops = {
    .owner    = THIS_MODULE,
    .getgeo = ramblock_getgeo,
};


static void do_ramblock_request(struct request_queue * q)
{
    int res = 0;
    struct request *req;

    req = blk_fetch_request(q);
    while (req) {
        /* 源/目的 */
        unsigned long offset = blk_rq_pos(req) * 512;

        /* 目的/源 */
        //request->buffer
    
        /* 长度 */
        unsigned long length = blk_rq_cur_sectors(req) * 512;

        // if (req->cmd_type != REQ_TYPE_FS)
        //     goto done;

        if(rq_data_dir(req) == READ)
        {
            memcpy(bio_data(req->bio), ramblock_buf+offset, length);
        }
        else
        {
            memcpy(ramblock_buf+offset, bio_data(req->bio), length);
        }

    done:
    /* wrap up, 0 = success, -errno = fail */
        if (!__blk_end_request_cur(req, res))
            req = blk_fetch_request(q);
    }
}

int ramblock_init(void)
{    
    major = register_blkdev(0, "ramblock");

    /* 分配并初始化request_queue队列 */
    ramblock_queue = blk_init_queue(do_ramblock_request, &ramblock_lock);

    /* 分配gendisk结构体 */
    ramblock_disk = alloc_disk(16);    //次设备号：分区个数

    /* 初始化gendisk结构体 */
    ramblock_disk->major = major;
    ramblock_disk->first_minor = 0;
    sprintf(ramblock_disk->disk_name, "ramblock_disk");
    ramblock_disk->fops = &ramblock_fops;
    ramblock_disk->queue = ramblock_queue;
    set_capacity(ramblock_disk, RAMBLOCK_SIZE / 512);

    /* 分配块设备读写操作的内存 */
    ramblock_buf = kzalloc(RAMBLOCK_SIZE, GFP_KERNEL);

    /* 注册gendisk */
    add_disk(ramblock_disk);

    return 0;
}

void ramblock_exit(void)
{
    unregister_blkdev(major, "ramblock");

    del_gendisk(ramblock_disk);
    put_disk(ramblock_disk);

    blk_cleanup_queue(ramblock_queue);    

    kfree(ramblock_buf);
}

module_init(ramblock_init);
module_exit(ramblock_exit);

MODULE_LICENSE("GPL");