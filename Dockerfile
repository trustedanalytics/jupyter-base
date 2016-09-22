FROM debian:stable

ENV DEBIAN_FRONTEND noninteractive


# Install required software and tools
RUN \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -yq --no-install-recommends --fix-missing \
    bzip2 \
    locales \
    tar \
    unzip \
    vim.tiny \
    wget


# Setup en_US locales to handle non-ASCII characters correctly
RUN \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen


# Setup some ENV variables and ARGs
ENV LC_ALL en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US en_US.UTF-8
ENV dpkg-reconfigure locales


# Add webupd8 repository to install JDK 1.8
RUN \
    echo "===> add webupd8 repository..." && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 && \
    apt-get update && \
    echo "===> install Java" && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
    apt-get install -yq --no-install-recommends --fix-missing oracle-java8-installer oracle-java8-set-default && \
    echo "===> clean up..." && \
    rm -rf /var/cache/oracle-jdk8-installer


# define default command
CMD ["java"]


# Install Tini
RUN \
    wget -q --no-check-certificate https://github.com/krallin/tini/releases/download/v0.10.0/tini -P /usr/local/bin/ && \
    chmod +x /usr/local/bin/tini


# Create vcap user with UID=1000 and in the 'users' group
ENV SHELL /bin/bash
ENV NB_USER vcap
ENV NB_UID 1000
RUN useradd -m -s /bin/bash -d /home/$NB_USER -N -u $NB_UID $NB_USER
ENV CONDA_DIR /opt/anaconda2
RUN \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:users $CONDA_DIR


# Download and Install Miniconda
ENV CONDA_VERSION 2-4.1.11
RUN \
    wget -q --no-check-certificate https://repo.continuum.io/miniconda/Miniconda${CONDA_VERSION}-Linux-x86_64.sh -P $CONDA_DIR && \
    bash $CONDA_DIR/Miniconda${CONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm -rf $CONDA_DIR/Miniconda${CONDA_VERSION}*x86_64.sh && \
    chown -R $NB_USER:users $CONDA_DIR


USER $NB_USER
ENV PATH $CONDA_DIR/bin:$PATH
   

# Setup vcap home directory
RUN \
    mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.local && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc
ENV HOME /home/$NB_USER


# Configure container startup
USER root
EXPOSE 8888
WORKDIR $HOME/jupyter
RUN \
    mkdir -p $HOME/jupyter && \
    chown -R $NB_USER:users $HOME/jupyter
COPY assets/start-notebook.sh /usr/local/bin/
COPY assets/jupyter_notebook_config.py /home/$NB_USER/.jupyter/
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]


# Copy all files before switching users
USER $NB_USER
COPY assets/tapmenu/ $HOME/tapmenu
RUN conda install jupyter


# This logo gets displayed within our default notebooks
USER root
RUN \
    jupyter-nbextension install $HOME/tapmenu && \
    jupyter-nbextension enable tapmenu/main
COPY assets/TAP-logo.png $CONDA_DIR/lib/python2.7/site-packages/notebook/static/base/images


# Final apt cleanup
RUN apt-get purge -y 'python3.4*' && \
    apt-get -yq autoremove && \
    apt-get -yq autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    conda clean -y --all
    

USER $NB_USER
RUN mkdir -p $HOME/.jupyter/nbconfig
