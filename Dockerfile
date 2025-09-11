FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/libcuda.so.1

RUN sed -i 's@http://archive.ubuntu.com/ubuntu/@http://mirrors.aliyun.com/ubuntu/@g' /etc/apt/sources.list && \
    sed -i 's@http://security.ubuntu.com/ubuntu/@http://mirrors.aliyun.com/ubuntu/@g' /etc/apt/sources.list

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
        gfortran \
        libopenblas-dev \
        liblapack-dev \
        pkg-config \
    && ln -s /usr/bin/python3.10 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 关键修复：降级 setuptools 到兼容版本，并安装预编译的核心包
RUN pip install --upgrade pip && \
    pip install "setuptools<60" wheel && \
    pip install --only-binary=:all: "numpy>=1.21.0,<1.25.0" "pandas>=1.3.0" "scipy>=1.7.0"

# 尝试安装 paddlets，如果失败则使用备选方案
RUN pip install --no-cache-dir paddlets --prefer-binary || \
    (pip install --no-cache-dir --no-deps paddlets && echo "Installed paddlets without dependencies")

# 安装其他依赖
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

RUN pip install --no-cache-dir paddlepaddle-gpu==3.0.0 -i https://www.paddlepaddle.org.cn/packages/stable/cu118/

COPY . .
WORKDIR /app/PaddleX
RUN pip install --no-cache-dir -e ".[base]"

WORKDIR /app
EXPOSE 35700-37700
CMD ["bash", "-c", "tail -f /dev/null"]