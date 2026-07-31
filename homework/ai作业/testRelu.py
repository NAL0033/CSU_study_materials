import numpy as np

def relu(z):
    return np.maximum(0, z)

def relu_grad(z):
    return (z > 0).astype(float)

# 输入
x = np.array([1, 0, 1], dtype=float)
t = 0
eta = 0.1

# 输入层 -> 隐藏层权重
W_hidden = np.array([
    [6, -2],
    [1,  3],
    [1, -1]
], dtype=float)

# 隐藏层 -> 输出层权重
W_out = np.array([2, -2], dtype=float)

# 输出层偏置权重，对应输入恒为 1
b_out = -1.0

# 正向传播
z_hidden = x @ W_hidden
f_hidden = relu(z_hidden)

z_out = f_hidden @ W_out + b_out
f = relu(z_out)

E = 0.5 * (t - f) ** 2

print("隐藏层输入 z_hidden =", z_hidden)
print("隐藏层输出 f_hidden =", f_hidden)
print("输出层输入 z_out =", z_out)
print("最终输出 f =", f)
print("误差 E =", E)

# 反向传播
delta_out = (f - t) * relu_grad(np.array([z_out]))[0]

grad_W_out = delta_out * f_hidden
grad_b_out = delta_out * 1

delta_hidden = delta_out * W_out * relu_grad(z_hidden)

grad_W_hidden = np.outer(x, delta_hidden)

# 参数更新
W_out_new = W_out - eta * grad_W_out
b_out_new = b_out - eta * grad_b_out
W_hidden_new = W_hidden - eta * grad_W_hidden

print("\n输出层 delta =", delta_out)
print("隐藏层 delta =", delta_hidden)

print("\n更新后的输出层权重 W_out_new =", W_out_new)
print("更新后的输出层偏置权重 b_out_new =", b_out_new)

print("\n更新后的隐藏层权重 W_hidden_new =")
print(W_hidden_new)