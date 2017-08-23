FROM nvidia/cuda:8.0-cudnn6-devel

ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

RUN mkdir -p $CONDA_DIR && \
    echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh && \
    apt-get update && \
    apt-get install -y wget git libhdf5-dev g++ graphviz openmpi-bin && \
    wget --quiet https://repo.continuum.io/archive/Anaconda3-4.4.0-Linux-x86_64.sh && \
    /bin/bash /Anaconda3-4.4.0-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Anaconda3-4.4.0-Linux-x86_64.sh

ENV NB_USER keras
ENV NB_UID 1000

RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown keras $CONDA_DIR -R && \
    mkdir -p /src && \
    chown keras /src && \
    mkdir -p /notebooks && \
    chown keras /notebooks && \
    mkdir -p /logs && \
    chown keras /logs

USER keras

# Python
ARG python_version=3.5

RUN conda install -y python=${python_version} && \
    pip install --upgrade pip && \
    pip install https://cntk.ai/PythonWheel/GPU/cntk-2.1-cp35-cp35m-linux_x86_64.whl && \
    pip install tensorflow-gpu && \
    conda install -y Pillow scikit-learn notebook pandas matplotlib mkl nose pyyaml six h5py && \
    conda install -y theano pygpu && \
    git clone https://github.com/fchollet/keras.git /src && pip install -e /src[tests] && \
    pip install git+https://github.com/fchollet/keras.git && \
    conda clean -yt

ADD theanorc /home/keras/.theanorc

ENV PYTHONPATH='/src/:$PYTHONPATH'

WORKDIR /notebooks

EXPOSE 8888 6006

RUN jupyter notebook --generate-config && \
    echo "c.NotebookApp.token='my_secret_token'" >> ~/.jupyter/jupyter_notebook_config.py

CMD jupyter notebook --port=8888 --ip=0.0.0.0 --no-browser
