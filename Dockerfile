FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

ENV EXECUTABLE_NAME="il_tuo_eseguibile"
ENV GITHUB_REPO="git+https://github.com/nghielme/hls4ml.git@bambu-backend"

RUN apt update && \
    apt install -y --no-install-recommends \
        build-essential \
        gcc \
        g++ \
        make \
        wget \
        git \
        bzip2 \
        ca-certificates \
        libsm6 \
        libxext6 \
        libxrender-dev && \
    rm -rf /var/lib/apt/lists/*

ARG USER_UID=1000
ARG USER_NAME=bambu_user
RUN groupadd --gid $USER_UID $USER_NAME && \
    useradd --uid $USER_UID --gid $USER_NAME -m $USER_NAME

USER $USER_NAME

COPY script.sh /home/$USER_NAME/
COPY environment.yml /home/$USER_NAME/

USER root 
RUN chmod +x /home/$USER_NAME/script.sh
USER $USER_NAME

CMD ["/bin/bash"]
