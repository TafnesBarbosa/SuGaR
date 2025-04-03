ARG CUDA_VERSION=11.8.0
ARG OS_VERSION=22.04
# Define base image.
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${OS_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

ARG CUDA_ARCHITECTURES=70 # 70 para DGX-1. 86 para Nvidia RTX 3070 TI.

# Instale o Conda
RUN apt-get update && \
    apt-get install -y wget bzip2 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    /bin/bash miniconda.sh -b -p /opt/conda

# Defina a variável de ambiente CUDA_HOME
ENV CUDA_HOME=/usr/local/cuda

# Adicione o CUDA ao PATH
ENV PATH=$CUDA_HOME/bin:$PATH

# Adicione Conda ao PATH
ENV PATH="/opt/conda/bin:${PATH}"

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc g++

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc-10 g++-10 && \
    export CC=/usr/bin/gcc-10 && \
    export CXX=/usr/bin/g++-10 && \
    export CUDAHOSTCXX=/usr/bin/g++-10

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    cmake \
    ninja-build \
    build-essential \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libeigen3-dev \
    libflann-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgtest-dev \
    libsqlite3-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libceres-dev

RUN git clone https://github.com/colmap/colmap.git && \
    cd colmap && \
    mkdir build && \
    cd build && \
    cmake .. -GNinja -DCUDA_ENABLED=ON -DCMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES} && \
    ninja && \
    ninja install && \
    cd ../.. && \
    rm -rf colmap

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg

RUN git clone https://github.com/TafnesBarbosa/SuGaR.git --recursive

WORKDIR /SuGaR

RUN conda env create -f environment.yml

# RUN sudo /opt/conda/bin/conda create --name sugar

SHELL ["/bin/bash", "-c"]
# RUN conda create --name sugar
RUN conda init bash
RUN echo "conda activate sugar" >> ~/.bashrc
RUN source ~/.bashrc

ENV PATH /opt/conda/envs/sugar/bin:$PATH
SHELL ["/bin/bash", "-c"]

RUN echo "cd gaussian_splatting/submodules/diff-gaussian-rasterization/" >> ~/.bashrc && \
    echo "pip install -e ." >> ~/.bashrc && \
    echo "cd ../simple-knn/" >> ~/.bashrc && \
    echo "pip install -e ." >> ~/.bashrc && \
    echo "cd ../../../" >> ~/.bashrc
RUN source ~/.bashrc

RUN git clone https://github.com/NVlabs/nvdiffrast
RUN echo "cd nvdiffrast" >> ~/.bashrc && \
    echo "pip install ." >> ~/.bashrc && \
    echo "cd ../" >> ~/.bashrc
RUN source ~/.bashrc

RUN pip install gdown

RUN echo "conda deactivate" >> ~/.bashrc && \
    echo "cd ../" >> ~/.bashrc
RUN source ~/.bashrc

RUN conda create --name nerfstudio -y python=3.8

SHELL ["/bin/bash", "-c"]
RUN conda init bash
RUN echo "conda activate nerfstudio" >> ~/.bashrc
RUN source ~/.bashrc

RUN echo "pip install --upgrade pip" >> ~/.bashrc
RUN source ~/.bashrc

RUN echo "pip install torch==2.1.2+cu118 torchvision==0.16.2+cu118 --extra-index-url https://download.pytorch.org/whl/cu118" >> ~/.bashrc && \
    echo "pip install ninja git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch" >> ~/.bashrc
RUN source ~/.bashrc

RUN git clone https://github.com/nerfstudio-project/nerfstudio.git
RUN echo "cd nerfstudio" >> ~/.bashrc && \
    echo "pip install --upgrade pip setuptools" >> ~/.bashrc && \
    echo "pip install -e ." >> ~/.bashrc && \
    echo "cd ../" >> ~/.bashrc
RUN source ~/.bashrc

RUN git clone https://github.com/TafnesBarbosa/auditor_classifier.git

RUN mkdir videos

RUN mkdir video_input_folder && cd video_input_folder && mkdir input

EXPOSE 80
