FROM ubuntu:14.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US en_US.UTF-8
ENV dpkg-reconfigure locales
ENV HTTP_PROXY http://proxy.jf.intel.com:911
ENV HTTPS_PROXY http://proxy.jf.intel.com:912
ENV http_proxy http://proxy.jf.intel.com:911
ENV https_proxy http://proxy.jf.intel.com:912
ENV no_proxy hf.intel.com,jf.intel.com,stash-fm-prod.devtools.intel.com,192.168.0.0/16,localhost,10.54.4.50,stash01.devtools.intel.com,devtools.intel.com,github.intel.com
ENV NO_PROXY hf.intel.com,jf.intel.com,stash-fm-prod.devtools.intel.com,192.168.0.0/16,localhost,10.54.4.50,stash01.devtools.intel.com,devtools.intel.com,github.intel.com
ENV SOCKS_PROXY socks://proxy-socks.jf.intel.com:1080
ENV socks_proxy socks://proxy-socks.jf.intel.com:1080

RUN apt-get update  --fix-missing 
RUN apt-get -y install software-properties-common
RUN add-apt-repository -y  ppa:saiarcot895/myppa && apt-get update
RUN apt-get install -y apt-fast  &&  apt-fast upgrade -y
RUN apt-fast install -y build-essential dpkg-dev zlib1g zlib1g-dev libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev vim gfortran libopenblas-dev liblapack-dev

RUN useradd -m -d /home/tap tap
ENV HOME /home/tap

#add all files before switching users
ADD assets/Python-2.7.10.tar.xz  $HOME
ADD assets/get-pip.py $HOME/
ADD assets/requirements.txt $HOME/
ADD assets/tapmenu/ $HOME/tapmenu

RUN mkdir -p $HOME/jupyter && ls -la $HOME
ADD assets/README.ipynb $HOME/jupyter/README.ipynb
ADD assets/run.sh $HOME/
RUN chown -R tap:tap $HOME && chmod 400 $HOME/jupyter/README.ipynb
USER tap

#install python
WORKDIR $HOME/Python-2.7.10
RUN ./configure --enable-ipv6 && make altinstall prefix=$HOME/python exec-prefix=$HOME/python LDFLAGS="-Wl,-rpath /usr/local/lib"
WORKDIR $HOME

#add path to tap users bashrc
RUN echo " export PATH=\$PATH:$HOME/python/bin " >> .bashrc && ln -s $HOME/python/bin/python2.7  $HOME/python/bin/python && $HOME/python/bin/python2.7 --version

ENV PATH=$PATH:$HOME/python/bin

#install pip
RUN python2.7 get-pip.py

#numpy needs to be installed before scipy with this local install otherwise scipy install will not find numpy
RUN pip2.7 install -U numpy &&  pip2.7 install -U jupyter scipy

RUN pip2.7 install -r $HOME/requirements.txt &&  mkdir -p /home/tap/.jupyter/nbconfig
WORKDIR $HOME 
RUN jupyter-nbextension install --user tapmenu  && jupyter-nbextension enable tapmenu/main 


ENTRYPOINT ["/home/tap/run.sh"]
