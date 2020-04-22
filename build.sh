#!/bin/bash

set -e -o xtrace

which go 2>/dev/null 1>/dev/null
if [[ $? -ne 0 ]]; then
  echo "error: failed to find go binary- do you have Go 1.13 installed?"
  exit 1
fi

GOVERSION=$(go version)
if [[ $GOVERSION != *"go1.13"* ]]; then
  echo "error: Go version is not 1.13 (was $GOVERSION)"
  exit 1
fi

export PYTHONPATH=$(pwd)/src/github.com/go-python/gopy/

# Use the default go binary path - the way to do it with newer versions of golang!
PATH=${PATH}:~/go/bin

echo "cleaning up output folder"
rm -frv gomssql_python/*.pyc
rm -frv gomssql_python/py2/*
echo ""

if [[ "$1" == "clean" ]]; then
  exit 0
fi

if [[ "$1" != "fast" ]]; then
  # This go get doesn't seem to work anymore but the project still builds
  #    echo "getting sql"
  #    go get -v -u golang.org/pkg/database/sql
  #
  #    echo "building sql"
  #    go build -x -a golang.org/pkg/database/sql

  echo "building go-mssqldb"
  go build -x -a -mod readonly github.com/denisenkom/go-mssqldb
  # go build -x -a github.com/denisenkom/go-mssqldb
  echo ""

  echo "building gopy"
  go build -x -a -mod readonly github.com/go-python/gopy
  # go build -x -a github.com/go-python/gopy
  echo ""

  echo "installing gopy"
  go install -i -mod readonly github.com/go-python/gopy
  # go install -i github.com/go-python/gopy
  echo ""

  echo "building gomssql_python"
  go build -x -a -mod readonly gomssql_python/gomssql_python_go
  # go build -x -a gomssql_python/gomssql_python_go
  echo ""

  # Use a specific version!
  echo "getting goimports"
  go get golang.org/x/tools/cmd/goimports@v0.0.0-20190910044552-dd2b5c81c578
fi

# Using a special version of pybindgen to fix some memory leaks specific to our use case
# https://github.com/ftpsolutions/pybindgen
echo "installing pybindgen - required for gopy"
pip install --trusted-host imdemo.ftpsolutions.com.au \
  --extra-index-url http://imdemo.ftpsolutions.com.au:9011/ \
  pybindgen==0.20.0.post2+gcab0b4a

echo "build gomssql_python bindings for py2"
./gopy build -output="gomssql_python/py2" -symbols=true -vm="$(which python)" gomssql_python/gomssql_python_go
echo ""

# Yep - this is highly questionable
# This requires an entry in LD_LIBRARY_PATH to work
SHARED_OBJ_DIR=/usr/local/lib/gopy/
echo "copying shared objects to ${SHARED_OBJ_DIR}"
mkdir -p ${SHARED_OBJ_DIR}
cp gomssql_python/py2/gomssql_python_go_go.so ${SHARED_OBJ_DIR}

# gopy doesn't seem to support Python3 as yet
# echo "build gomssql_python bindings for py3"
# ./gopy bind -lang="py3" -output="gomssql_python/py3" -symbols=true -work=false gomssql_python
# echo ""

#echo "build gomssql_python bindings for cffi"
#./gopy bind -api="cffi" -output="gomssql_python/cffi" -symbols=true -work=false gomssql_python
#echo ""

echo "cleaning up"
find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf
echo ""
