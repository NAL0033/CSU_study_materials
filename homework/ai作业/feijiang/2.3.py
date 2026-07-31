import paddle
import paddle.nn.functional as F
import numpy as np
import matplotlib.pyplot as plt
from paddle.io import Dataset, DataLoader
from paddle.vision.transforms import Normalize

class MNISTDataset(Dataset):
    def __init__(self, mode='train'):
        super().__init__()
        self.transform = Normalize(mean=[127.5], std=[127.5], data_format='CHW')
        self.dataset = paddle.vision.datasets.MNIST(mode=mode, download=True)

    def __getitem__(self, index):
        img, label = self.dataset[index]
        return self.transform(img), np.array(label).item()

    def __len__(self):
        return len(self.dataset)

train_dataset = MNISTDataset('train')
test_dataset = MNISTDataset('test')

train_loader = DataLoader(train_dataset, batch_size=64, shuffle=True, drop_last=True, num_workers=0)
test_loader = DataLoader(test_dataset, batch_size=64, shuffle=False, num_workers=0)

class MNIST(paddle.nn.Layer):
    def __init__(self):
        super().__init__()
        self.fc = paddle.nn.Linear(784, 1)

    def forward(self, x):
        x = paddle.reshape(x, [x.shape[0], -1])
        return self.fc(x)

def train(model):
    model.train()
    opt = paddle.optimizer.SGD(learning_rate=0.001, parameters=model.parameters())
    epochs = 3

    for epoch in range(epochs):
        print(f"\nEpoch {epoch}")
        for batch_id, (x, y) in enumerate(train_loader):
            y = paddle.to_tensor(y, dtype='float32').reshape([-1, 1])
            pred = model(x)
            loss = paddle.mean(F.square_error_cost(pred, y))

            if batch_id % 200 == 0:
                print(f"loss: {loss.item():.4f}")

            loss.backward()
            opt.step()
            opt.clear_grad()

    paddle.save(model.state_dict(), 'mnist.pdparams')

model = MNIST()
train(model)

model.set_state_dict(paddle.load('mnist.pdparams'))
model.eval()

img, label = test_dataset[0]
img = paddle.to_tensor(img).unsqueeze(0)
pred = int(round(model(img).item()))

print(f"\n真实: {label}, 预测: {pred}")

plt.imshow(img.numpy().squeeze(), cmap='gray')
plt.title(f'{label} -> {pred}')
plt.show()