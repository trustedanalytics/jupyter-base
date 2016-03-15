# jupyter-container
A Ubuntu:14.04 container for running a local install of Python(2.7.10) and Jupyter.

An entry point has been set that will automatically start the notebook server. If you want to set any **jupyter notebook** CLI options assign them to the **IPYTHON_OPTS** env variable.

example build:
```
docker build --build-arg HTTP_PROXY=$http_proxy --build-arg HTTPS_PROXY=$http_proxy --build-arg NO_PROXY=$no_proxy --build-arg http_proxy=$http_proxy --build-arg https_proxy=$http_proxy --build-arg no_proxy=$no_proxy --build-arg PYTHON_VERSION=2.7.10 .
```

example run:
```
docker run  --env IPYTHON_OPTS="--ip='*' " -p 8889:8888  tapatk/jupyter
```
This will run the notebook and bind to all IP address inside the container and map host port 8889 to container port 8888.

The python installation is local to **/home/tap** so any new python packages that might need to be installed won't require sudo to run.

The following package are pre-installed:
- pip
- numpy>=1.8.1
- bottle>=0.12
- requests>=2.4.0
- ordereddict>=1.1
- decorator>=3.4.0
- pandas>=0.15.0
- pymongo>=3.0
- networkx>=1.10
- matplotlib>=1.4.3
- jupyter>=1.0.0
- scipy>=0.14
- scikit-learn>=0.15
- nose>=0.10.0

