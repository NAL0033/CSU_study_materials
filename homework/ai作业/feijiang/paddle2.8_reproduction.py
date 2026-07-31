import paddle
import paddle.nn as nn
import paddle.nn.functional as F
from paddle.vision.datasets import MNIST
from paddle.vision.transforms import Compose, Normalize
from paddle.io import DataLoader
import matplotlib.pyplot as plt
import numpy as np

# ======================
# 1. 数据加载
# ======================
def get_MNIST_dataloader():
    transform = Compose([Normalize(mean=[127.5], std=[127.5], data_format='CHW')])
    train_dataset = MNIST(mode='train', transform=transform)
    test_dataset = MNIST(mode='test', transform=transform)
    train_loader = DataLoader(train_dataset, batch_size=64, shuffle=True, num_workers=0)
    test_loader = DataLoader(test_dataset, batch_size=64, shuffle=False, num_workers=0)
    return train_loader, test_loader

train_loader, test_loader = get_MNIST_dataloader()

# ======================
# 2. 模型定义（带每层输出打印）
# ======================
class MNIST_Net(nn.Layer):
    def __init__(self):
        super(MNIST_Net, self).__init__()
        self.conv1 = nn.Conv2D(1, 16, 5, stride=1, padding=2)
        self.pool1 = nn.MaxPool2D(2)
        self.conv2 = nn.Conv2D(16, 32, 5, stride=1, padding=2)
        self.pool2 = nn.MaxPool2D(2)
        self.fc1 = nn.Linear(32*7*7, 128)
        self.fc2 = nn.Linear(128, 10)

    def forward(self, x, print_layers=False):
        # 第一层卷积
        x = self.conv1(x)
        if print_layers: print("conv1输出:", x.numpy()[:1])
        
        x = F.relu(x)
        x = self.pool1(x)

        # 第二层卷积
        x = self.conv2(x)
        if print_layers: print("conv2输出:", x.numpy()[:1])
        
        x = F.relu(x)
        x = self.pool2(x)

        # 展平
        x = paddle.flatten(x, 1)

        # 全连接层1
        x = self.fc1(x)
        if print_layers: print("fc1输出:", x.numpy()[:1])
        
        x = F.relu(x)

        # 输出层
        x = self.fc2(x)
        if print_layers: print("fc2输出:", x.numpy()[:1])
        return x

# ======================
# 3. 打印每层输出（任务1）
# ======================
print("="*50)
print("【任务1】打印神经网络每层输出")
model = MNIST_Net()
for img, label in train_loader:
    model(img[:1], print_layers=True)  # 只打印一张图的每层输出
    break

# ======================
# 4. 训练 + 记录指标（任务2~5）
# ======================
def train_and_evaluate(weight_decay=0.0):
    model = MNIST_Net()
    paddle.device.set_device('cpu')
    model.train()

    # 优化器（带正则化）
    opt = paddle.optimizer.Adam(
        learning_rate=0.001,
        parameters=model.parameters(),
        weight_decay=weight_decay
    )

    EPOCHS = 5
    train_losses = []
    test_losses = []
    train_accs = []
    test_accs = []

    for epoch in range(EPOCHS):
        # 训练
        total_loss = 0
        correct = 0
        total = 0
        for img, label in train_loader:
            pred = model(img)
            loss = F.cross_entropy(pred, label)
            avg_loss = paddle.mean(loss)

            # 准确率
            pred_class = paddle.argmax(pred, axis=1)
            correct += paddle.sum(pred_class == label).item()
            total += label.shape[0]
            total_loss += avg_loss.item()

            avg_loss.backward()
            opt.step()
            opt.clear_grad()

        train_loss = total_loss / len(train_loader)
        train_acc = correct / total
        train_losses.append(train_loss)
        train_accs.append(train_acc)

        # 测试
        model.eval()
        t_loss = 0
        t_correct = 0
        t_total = 0
        with paddle.no_grad():
            for img, label in test_loader:
                pred = model(img)
                loss = F.cross_entropy(pred, label)
                t_loss += paddle.mean(loss).item()
                pred_class = paddle.argmax(pred, axis=1)
                t_correct += paddle.sum(pred_class == label).item()
                t_total += label.shape[0]

        test_loss = t_loss / len(test_loader)
        test_acc = t_correct / t_total
        test_losses.append(test_loss)
        test_accs.append(test_acc)

        print(f"Epoch {epoch} | Train loss:{train_loss:.3f} Acc:{train_acc:.3f} | Test loss:{test_loss:.3f} Acc:{test_acc:.3f}")
        model.train()

    return train_losses, test_losses, train_accs, test_accs

# ======================
# 【任务2~5】画图对比
# ======================
print("\n" + "="*50)
print("【任务2~5】开始训练并画图")

# 1. 无正则化
tr_loss_no, te_loss_no, tr_acc_no, te_acc_no = train_and_evaluate(weight_decay=0.0)

# 2. 强正则化
tr_loss_reg, te_loss_reg, tr_acc_reg, te_acc_reg = train_and_evaluate(weight_decay=0.01)

# ======================
# 画图：准确率曲线（任务2）
# ======================
plt.figure(figsize=(12,5))

plt.subplot(1,2,1)
plt.plot(tr_acc_no, label="Train Acc (无正则)")
plt.plot(te_acc_no, label="Test Acc (无正则)")
plt.plot(tr_acc_reg, label="Train Acc (强正则)")
plt.plot(te_acc_reg, label="Test Acc (强正则)")
plt.title("准确率变化曲线")
plt.legend()

# ======================
# 画图：Loss曲线（任务4、5）
# ======================
plt.subplot(1,2,2)
plt.plot(tr_loss_no, label="Train Loss (无正则)")
plt.plot(te_loss_no, label="Test Loss (无正则)")
plt.plot(tr_loss_reg, label="Train Loss (强正则)")
plt.plot(te_loss_reg, label="Test Loss (强正则)")
plt.title("Loss变化曲线")
plt.legend()

plt.tight_layout()
plt.show()