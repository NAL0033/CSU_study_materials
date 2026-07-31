import numpy as np

# ========= 激活函数 =========
def sigmoid(x):
    return 1 / (1 + np.exp(-x))

def sigmoid_grad(x):
    s = sigmoid(x)
    return s * (1 - s)

# ========= 输入 =========
x1, x2 = 0.5, 0.3
x = np.array([x1, x2])

# ========= 输入层 -> 隐藏层权重 =========
w11, w21 = 0.2, 0.5   # -> h1
w12, w22 = -0.4, 0.6  # -> h2

# ========= 隐藏层 -> 输出层权重 =========
v11, v21 = 0.1, -0.3   # -> o1
v12, v22 = -0.5, 0.8   # -> o2

# ========= 目标值 =========
t1, t2 = 0.23, -0.07

# ========= 学习率 =========
lr = 0.1

# =====================
# 1️⃣ 正向传播
# =====================
# 隐藏层
h1_in = x1*w11 + x2*w21
h2_in = x1*w12 + x2*w22

h1 = sigmoid(h1_in)
h2 = sigmoid(h2_in)

# 输出层
o1_in = h1*v11 + h2*v21
o2_in = h1*v12 + h2*v22

o1 = sigmoid(o1_in)
o2 = sigmoid(o2_in)

print("=== 正向传播 ===")
print("h1 =", h1)
print("h2 =", h2)
print("o1 =", o1)
print("o2 =", o2)

# =====================
# 2️⃣ 反向传播
# =====================
# 输出层误差项
delta_o1 = (t1 - o1) * o1 * (1 - o1)
delta_o2 = (t2 - o2) * o2 * (1 - o2)

# 隐藏层误差项
delta_h1 = h1 * (1 - h1) * (v11 * delta_o1 + v12 * delta_o2)
delta_h2 = h2 * (1 - h2) * (v21 * delta_o1 + v22 * delta_o2)

print("\n=== 误差项 ===")
print("delta_o1 =", delta_o1)
print("delta_o2 =", delta_o2)
print("delta_h1 =", delta_h1)
print("delta_h2 =", delta_h2)

# =====================
# 3️⃣ 权重更新
# =====================
# 输出层更新
v11_new = v11 + lr * delta_o1 * h1
v21_new = v21 + lr * delta_o1 * h2

v12_new = v12 + lr * delta_o2 * h1
v22_new = v22 + lr * delta_o2 * h2

# 隐藏层更新
w11_new = w11 + lr * delta_h1 * x1
w21_new = w21 + lr * delta_h1 * x2

w12_new = w12 + lr * delta_h2 * x1
w22_new = w22 + lr * delta_h2 * x2

print("\n=== 更新后的参数 ===")

print("\n输出层：")
print("v11_new =", v11_new)
print("v21_new =", v21_new)
print("v12_new =", v12_new)
print("v22_new =", v22_new)

print("\n隐藏层：")
print("w11_new =", w11_new)
print("w21_new =", w21_new)
print("w12_new =", w12_new)
print("w22_new =", w22_new)