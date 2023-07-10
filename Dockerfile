ARG TAG=latest
FROM continuumio/miniconda3:$TAG

RUN apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        git \
        locales \
        sudo \
        build-essential \
        dpkg-dev \
        wget \
        openssh-server \
        ca-certificates \
        netbase\
        tzdata \
        nano \
        software-properties-common \
        python3-venv \
        python3-tk \
        pip \
        bash \
        git \
        ncdu \
        net-tools \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        unzip \
        htop \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 libtcmalloc-minimal4  \
    && rm -rf /var/lib/apt/lists/*

# Setting up locales
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# RUN service ssh start
EXPOSE 5111

# Create user:
RUN groupadd --gid 1020 gun-group
RUN useradd -rm -d /home/gun-user -s /bin/bash -G users,sudo,gun-group -u 1000 gun-user

# Update user password:
RUN echo 'gun-user:admin' | chpasswd

RUN mkdir /home/gun-user/gun

RUN cd /home/gun-user/gun

RUN python3 -m pip install torch torchvision torchaudio

# Clone the repository
RUN git clone https://github.com/XingangPan/DragGAN.git /home/gun-user/gun

RUN chmod 777 /home/gun-user/gun

RUN rm -frv /home/gun-user/gun/environment.yml

ADD ./environment.yml /home/gun-user/gun/

# conda init bash for $user
RUN su - gun-user -c "conda init bash"

# Настройка окружения из yaml:
RUN cd /home/gun-user/gun && \
    conda env create -f ./environment.yml

# Install the dependencies
RUN python3 -m pip install -r /home/gun-user/gun/requirements.txt

RUN export PYTORCH_ENABLE_MPS_FALLBACK=1

RUN cd /home/gun-user/gun/scripts/ && \
    python3 download_model.py

RUN mkdir /home/gun-user/gun/checkpoints

# Preparing for login
ENV HOME home/gun-user/gun/
WORKDIR ${HOME}

CMD python3 visualizer_drag_gradio.py

# Docker:
# docker build -t draggun .
# docker run -dit --name localgpt -p 5111:5111 -v D:/Develop/NeuronNetwork/localGPT/NN_localGPT/SOURCE_DOCUMENTS:/home/gpt-user/gpt/SOURCE_DOCUMENTS --gpus all --restart unless-stopped localgpt:latest

# docker run -dit --name draggun -p 7860:7860 --gpus all --restart unless-stopped draggun:latest

# debug: docker container attach draggun

# Интерфейс доступен на:
# http://localhost:5111/