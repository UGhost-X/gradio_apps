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

# 设置工作目录并复制所有文件
WORKDIR /app
COPY . .

# --- 关键修复：设置 PYTHONPATH ---
# 明确告诉 Python 解释器，PaddleX 的源代码在 /app/PaddleX 目录中
# 这可以解决 editable install 模式下的 ModuleNotFoundError 问题
ENV PYTHONPATH "${PYTHONPATH}:/app/PaddleX"

# 安装基础依赖和 paddlepaddle
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir paddlepaddle-gpu==3.0.0 -i https://www.paddlepaddle.org.cn/packages/stable/cu118/

# 在同一个 RUN 指令中安装 PaddleX 并立即使用它
RUN cd /app/PaddleX && \
    pip install --no-cache-dir -e ".[base]" && \
    paddlex --install PaddleTS && \
    cd ..

# 暴露端口和启动命令
EXPOSE 35700-37700
CMD ["bash", "-c", "tail -f /dev/null"]