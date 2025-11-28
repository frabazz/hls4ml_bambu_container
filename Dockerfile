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

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    /bin/bash miniconda.sh -b -p $CONDA_DIR && \
    rm miniconda.sh && \
    $CONDA_DIR/bin/conda init bash

ARG USER_UID=1000
ARG USER_NAME=bambu_user
RUN groupadd --gid $USER_UID $USER_NAME && \
    useradd --uid $USER_UID --gid $USER_NAME -m $USER_NAME

 USER $USER_NAME

RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    conda create -n bambu_env python=3.10 -y && \
    /bin/bash -c "source $CONDA_DIR/etc/profile.d/conda.sh && \
    conda activate bambu_env && \
    pip install --upgrade pip && \
    pip install tensorflow keras && \
    conda clean -a -y"

RUN /bin/bash -c "source $CONDA_DIR/etc/profile.d/conda.sh && conda activate bambu_env && pip install $GITHUB_REPO"

USER root
RUN wget release.bambuhls.eu/bambu-latest.AppImage -O local_bambu
RUN chmod +x local_bambu
RUN ./local_bambu --appimage-extract
RUN ln ./squashfs-root/usr/bin/bambu /usr/bin/bambu

# COPY ${EXECUTABLE_NAME} /usr/local/bin/
# RUN chmod +x /usr/local/bin/${EXECUTABLE_NAME}

USER $USER_NAME

ENTRYPOINT ["/bin/bash", "-c", "source /opt/conda/bin/activate bambu_env && exec \"$@\"", "bash"]
CMD ["/bin/bash"]
