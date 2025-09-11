FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/libcuda.so.1

# 使用阿里云镜像加速
RUN sed -i 's@http://archive.ubuntu.com/ubuntu/@http://mirrors.aliyun.com/ubuntu/@g' /etc/apt/sources.list && \
    sed -i 's@http://security.ubuntu.com/ubuntu/@http://mirrors.aliyun.com/ubuntu/@g' /etc/apt/sources.list

# 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        python3.10 \
        python3.10-dev \
        python3-pip \
        gcc g++ make \          # 显式安装编译工具
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libxrender1 \
        libxext6 \
    && ln -s /usr/bin/python3.10 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 配置 pip 镜像并升级工具
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip install --upgrade pip setuptools wheel

# 先安装 numpy 并确保编译通过
RUN pip install --no-cache-dir "numpy>=1.21.0" --force-reinstall

# 安装其他依赖
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# 安装 PaddlePaddle
RUN pip install --no-cache-dir paddlepaddle-gpu==3.0.0 -i https://www.paddlepaddle.org.cn/packages/stable/cu118/

COPY . .

# 安装 PaddleX
WORKDIR /app/PaddleX
RUN pip install --no-cache-dir -e ".[base]"

# 最后安装 paddlets
WORKDIR /app
RUN pip install --no-cache-dir paddlets

EXPOSE 35700-37700
CMD ["bash", "-c", "tail -f /dev/null"]