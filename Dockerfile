# GLM-OCR 推理服务镜像（transformers + FastAPI，阶段 1 默认引擎）
# 基础镜像 CUDA 12.4 与服务器驱动 595.84 兼容
# 版本锁定（2026-08，与服务器 venv 核对）：torch 2.13.0 + torchvision 0.28.0 + transformers 5.3.0
FROM nvidia/cuda:12.4.1-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PIP_NO_CACHE_DIR=1

# apt 换清华源（国内构建加速；若镜像为 deb822 格式源则改 /etc/apt/sources.list.d/ubuntu.sources）
# gcc/g++/make + python3.10-dev：torch 2.13 的 Triton 内核需要运行时 JIT 编译（C 编译器 + Python.h），必须安装
RUN sed -i 's#http://archive.ubuntu.com/ubuntu#https://mirrors.tuna.tsinghua.edu.cn/ubuntu#g; s#http://security.ubuntu.com/ubuntu#https://mirrors.tuna.tsinghua.edu.cn/ubuntu#g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.10 python3.10-venv python3.10-dev python3-pip ca-certificates curl \
        gcc g++ make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/glm-ocr/app

# pip 走清华源
RUN python3.10 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip

COPY requirements.txt .
RUN python3.10 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt

# 应用代码（容器化改造后版本，含 GLM_OCR_MODEL_PATH 环境变量支持；task-api/batch_worker 供集群 MVP 复用）
COPY server.py task-api.py batch_worker.py table_dict.py table_split.py table_recognize.py table_pipeline.py pdf_pipeline.py ./

# 运行配置：模型通过卷挂载注入（规模化阶段可改为 bake 进镜像）
ENV GLM_OCR_MODEL_PATH=/opt/glm-ocr/models/GLM-OCR \
    GLM_OCR_LAYOUT_MODEL_DIR=/opt/glm-ocr/models/PP-DocLayoutV3_safetensors \
    GLM_OCR_DTYPE=bfloat16 \
    GLM_OCR_PORT=18080

EXPOSE 18080

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -fs http://127.0.0.1:18080/health || exit 1

CMD ["python3.10", "server.py"]
