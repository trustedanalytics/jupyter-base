FROM debian:stable

ENV DEBIAN_FRONTEND noninteractive

ARG PYTHON_VERSION=2.7.10

RUN apt-get update \
    && apt-get -y upgrade 

RUN apt-get install -yq --no-install-recommends --fix-missing \
    locales software-properties-common build-essential \
    vim-tiny unzip bzip2 tar sudo wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Setup ENVs variables and ARGs
ENV LC_ALL en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US en_US.UTF-8
ENV dpkg-reconfigure locales

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.9.0/tini && \
    echo "faafbfb5b079303691a939a747d7f60591f2143164093727e870b289a44d9872 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Create tap user with UID=1000 and in the 'users' group
ENV SHELL /bin/bash
ENV NB_USER tap
ENV NB_UID 1000
RUN useradd -m -s /bin/bash -d /home/$NB_USER -N -u $NB_UID $NB_USER 

USER $NB_USER
# Setup tap home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.local && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc

ENV HOME /home/$NB_USER

USER root
# Install modern pip then kernel gateway
RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
        python-dev libblas-dev liblapack-dev libatlas-base-dev gfortran python-setuptools \
        python-scipy python-matplotlib \
        python-setuptools python-dev \
        python3-dev python3-setuptools && \
    easy_install pip && \
    easy_install3 pip && \
    pip2.7 install jupyter_kernel_gateway==0.3.1 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy all files before switching users
COPY assets/requirements.txt $HOME/
COPY assets/tapmenu/ $HOME/tapmenu
RUN mkdir -p $HOME/jupyter && ls -la $HOME
COPY assets/README.ipynb $HOME/jupyter/README.ipynb
COPY assets/run.sh $HOME/
RUN chown -R tap:users $HOME && chmod 400 $HOME/jupyter/README.ipynb

# Install TrustedAnalytics Clien dependencies and install the helper notebook
RUN pip2.7 install -r $HOME/requirements.txt &&  mkdir -p $HOME/.jupyter/nbconfig
RUN jupyter-nbextension install $HOME/tapmenu  && jupyter-nbextension enable tapmenu/main 

# Configure container startup
EXPOSE 8888
WORKDIR $HOME/jupyter
COPY assets/start-notebook.sh /usr/local/bin/
COPY assets/jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]

USER $NB_USER

