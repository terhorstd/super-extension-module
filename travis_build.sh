#!/bin/bash

# travis_build.sh
#
# This file is part of the NEST example module.
#
# Copyright (C) 2004 The NEST Initiative
#
# NEST is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# NEST is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with NEST.  If not, see <http://www.gnu.org/licenses/>.


# This shell script is part of the NEST example module Travis CI build
# and test environment. It is invoked by the top-level Travis script
# '.travis.yml'.
#

# Exit shell if any subcommand or pipline returns a non-zero status.
set -e

# We need to do this, because  update-alternatives is not available on MacOS
if [[ $OSTYPE = darwin* ]]; then
  export CC=$(ls /usr/local/bin/gcc-* | grep '^/usr/local/bin/gcc-\d$')
  export CXX=$(ls /usr/local/bin/g++-* | grep '^/usr/local/bin/g++-\d$')
fi

SOURCEDIR=$PWD
cd ..

# Install current NEST version.
git clone https://github.com/nest/nest-simulator.git
cd nest-simulator

if [[ $OSTYPE = darwin* ]]; then
  PYPREFIX="/usr/local/Cellar/python/3.7.5/Frameworks/Python.framework/Versions/3.7"
  CONFIGURE_PYTHON="\
    -DPYTHON_LIBRARY=$PYPREFIX/lib/libpython3.7.dylib
    -DPYTHON_INCLUDE_DIR=$PYPREFIX/include/python3.7m/"
else
  PYPREFIX="/opt/python/3.6.10"
  CONFIGURE_PYTHON="\
    -DPYTHON_LIBRARY=$PYPREFIX/lib/libpython3.6m.so
    -DPYTHON_INCLUDE_DIR=$PYPREFIX/include/python3.6m/"
fi

# Explicitly allow MPI oversubscription. This is required by Open MPI versions > 3.0.
# Not having this in place leads to a "not enough slots available" error.
cp extras/nestrc.sli ~/.nestrc
if [[ "$OSTYPE" = "darwin"* ]] ; then
  sed -i -e 's/mpirun -np/mpirun --oversubscribe -np/g' ~/.nestrc
fi

mkdir build && cd build
cmake \
    -Dwith-optimize=ON -Dwith-warning=ON \
    -Dwith-mpi=ON \
    $CONFIGURE_PYTHON \
    -DCMAKE_INSTALL_PREFIX=$HOME/install \
    ..

VERBOSE=1 make -j 2
make install

cd $SOURCEDIR
mkdir build && cd build
cmake \
    -Dwith-optimize=ON -Dwith-warning=ON \
    -Dwith-nest=$HOME/install/bin/nest-config \
    -Dwith-mpi=ON \
    $CONFIGURE_PYTHON \
    -DCMAKE_INSTALL_PREFIX=$HOME/install \
    ..

VERBOSE=1 make -j 2
make install


# TODO: replace by proper testsuite!
. $HOME/install/bin/nest_vars.sh
python -c 'import nest; nest.Install("mymodule")'
exit $?
