FROM debian:stable

ENV DEBIAN_FRONTEND noninteractive

ARG PYTHON_VERSION=2.7.10

RUN apt-get update && \
    apt-get -y upgrade 

RUN apt-get install -yq --no-install-recommends --fix-missing \
    locales software-properties-common build-essential python-qt4 libxext6 \
    vim.tiny unzip tar wget 

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Setup ENVs variables and ARGs
ENV LC_ALL en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US en_US.UTF-8
ENV dpkg-reconfigure locales

# add webupd8 repository
RUN \
    echo "===> add webupd8 repository..."  && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list  && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list  && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886  && \
    apt-get update  && \
    echo "===> install Java"  && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections  && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections  && \
    DEBIAN_FRONTEND=noninteractive  apt-get install -y --force-yes oracle-java8-installer oracle-java8-set-default  && \
    echo "===> clean up..."  && \
    rm -rf /var/cache/oracle-jdk8-installer


# define default command
CMD ["java"]

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.9.0/tini && \
    echo "faafbfb5b079303691a939a747d7f60591f2143164093727e870b289a44d9872 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Create vcap user with UID=1000 and in the 'users' group
ENV SHELL /bin/bash
ENV NB_USER vcap
ENV NB_UID 1000
RUN useradd -m -s /bin/bash -d /home/$NB_USER -N -u $NB_UID $NB_USER
ENV CONDA_DIR /opt/anaconda2
RUN mkdir -p $CONDA_DIR && chown $NB_USER $CONDA_DIR

USER $NB_USER
# Download and Install Anaconda2
RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda2-4.1.11-Linux-x86_64.sh && \
    echo "b2af3b9ff39c4a4a812f50cecbafcda6 Miniconda2-4.1.11-Linux-x86_64.sh" | md5sum -c - && \
    bash Miniconda2-4.1.11-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda2-*x86_64.sh

ENV PATH $CONDA_DIR/bin:$PATH
   
# Setup vcap home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.local && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc

ENV HOME /home/$NB_USER

USER root
# Configure container startup
EXPOSE 8888
WORKDIR $HOME/jupyter
COPY assets/start-notebook.sh /usr/local/bin/
COPY assets/jupyter_notebook_config.py /home/$NB_USER/.jupyter/
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]

# Copy all files before switching users
COPY assets/requirements.txt $HOME/
COPY assets/tapmenu/ $HOME/tapmenu
RUN mkdir -p $HOME/jupyter && ls -la $HOME
RUN conda install jupyter

RUN jupyter-nbextension install $HOME/tapmenu  && jupyter-nbextension enable tapmenu/main 

# This logo gets displayed within our default notebooks
COPY assets/TAP-logo.png $CONDA_DIR/lib/python2.7/site-packages/notebook/static/base/images


# Final apt cleanup
RUN apt-get purge -y 'python3.4*' && \
    apt-get -yq autoremove && \
    apt-get -yq clean && \
    rm -rf /var/lib/apt/lists/* && \
    conda clean -y --all
    

USER $NB_USER


RUN mkdir -p $HOME/.jupyter/nbconfig
