# 使用您的原始基础镜像
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# 环境变量和 CUDA 链接保持不变
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/libcuda.so.1

# 设置国内镜像源
RUN sed -i 's@http://archive.ubuntu.com/ubuntu/@http://mirrors.aliyun.com/ubuntu/@g' /etc/apt/sources.list && \
    sed -i 's@http://security.ubuntu.com/ubuntu/@http://mirrors.aliyun.com/ubuntu/@g' /etc/apt/sources.list

# 安装完整的编译环境和 Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        python3.10 \
        python3.10-dev \
        python3-pip \
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libxrender1 \
        libxext6 \
    && ln -s /usr/bin/python3.10 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# 优先升级 pip 并设置 Pypi 镜像
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip install --upgrade pip setuptools wheel

# --- 最终解决方案：原子化安装 ---
# 将所有东西（requirements, 项目本身, paddlets）放在一个 pip install 命令中
# 这会强制 pip 的依赖解析器一次性找到所有包的兼容版本

WORKDIR /app
COPY . .

# 在一个指令中安装所有来自标准 PyPI 的包
# 关键：我们提供了所有约束，让 pip 做出最优解，而不是在已安装的环境上打补丁
RUN pip install \
    --no-cache-dir \
    -r requirements.txt \
    -e ./PaddleX[base] \
    paddlets \
    "numpy==1.26.4"

# 然后单独安装来自特殊源的 paddlepaddle
RUN pip install --no-cache-dir paddlepaddle-gpu==3.0.0 -i https://www.paddlepaddle.org.cn/packages/stable/cu118/

# 暴露端口和启动命令
EXPOSE 35700-37700
CMD ["bash", "-c", "tail -f /dev/null"]