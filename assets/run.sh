#!/bin/bash
# run the ipython notebook automatically

pwd 

ls -la

echo "IPYTHON_OPTS " $IPYTHON_OPTS
pushd jupyter
jupyter notebook $IPYTHON_OPTS 
