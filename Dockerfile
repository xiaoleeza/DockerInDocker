# 基础镜像：保留 OpenJDK JRE 17（Ubuntu 22.04 Jammy）
FROM eclipse-temurin:17-jre-jammy

# 安装基础工具（用于下载和添加源）
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# ========== 安装 MiKTeX（基于您提供的官方指南） ==========
# 1. 注册 GPG 密钥
RUN curl -fsSL https://miktex.org/download/key | gpg --dearmor -o /usr/share/keyrings/miktex.gpg

# 2. 注册安装源（针对 Ubuntu 22.04 Jammy）
RUN echo "deb [signed-by=/usr/share/keyrings/miktex.gpg] https://miktex.org/download/ubuntu jammy universe" > /etc/apt/sources.list.d/miktex.list

# 3. 安装 MiKTeX
RUN apt-get update && apt-get install -y miktex \
    && rm -rf /var/lib/apt/lists/*

# 4. 完成系统级（共享）安装配置
RUN miktexsetup --shared=yes finish

# 5. 启用自动安装缺失宏包功能
RUN initexmf --admin --set-config-value [MPM]AutoInstall=1

# ========== 安装 OfficeCLI（指定 v1.0.139 二进制版本） ==========
# 下载 linux-x64 二进制文件并放到 PATH 目录下，赋予执行权限
RUN wget -q -O /usr/local/bin/officecli \
    https://github.com/iOfficeAI/OfficeCLI/releases/download/v1.0.139/officecli-linux-x64 \
    && chmod +x /usr/local/bin/officecli

# 设置容器启动命令（直接调用二进制）
ENTRYPOINT ["officecli"]
