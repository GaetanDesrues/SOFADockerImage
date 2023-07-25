FROM fedora:latest


# Docker image with preinstalled SOFA v23.06
# Author: Gaëtan Desrues, INRIA


# Update fedora (fedora:latest comes with fedora 38 and python3.11)
RUN dnf clean all && dnf update -y
RUN useradd user


# (Re)installing Python 3.11 and creating virtual env
RUN dnf install -y python3.11 python3.11-devel python3-pip
RUN python3.11 -m venv /home/user/venv
ENV PATH="/home/user/venv/bin:$PATH"
RUN chown -R user:user /home/user


# Checking installed versions
RUN python --version && pip --version

# Verify that Python 3.11 and pip match
RUN python --version | grep -q "Python 3\.11" && \
    pip --version | grep -q "python 3\.11" || \
    (echo "Python 3.11 and pip versions do not match" && exit 1)



# Set up linux env
RUN dnf install -y \
	gcc \
	cmake \
	git \
	g++ \
	boost-devel \
	eigen3-devel \
	libpng-devel \
	mesa-libGL-devel \
	glew-devel \
	qt5-qtbase-devel \
    python-devel \
    python3-devel \
    numpy \
    cython \
    libXrender \
	libXcursor \
    libXft \
    libXinerama \
    nano \
    which \
	xorg-x11-server-Xvfb && ln -s /usr/bin/Xvfb /bin/xvfb



# Set SOFA directories
RUN mkdir -p /sofa/src && \
	mkdir -p /sofa/build && \
	chown user:user -R /sofa


# Install python dependencies
USER user
RUN pip install --upgrade pip && \ 
    pip install pybind11


# Download SOFA
RUN git clone -b v23.06.00 https://github.com/sofa-framework/sofa.git /sofa/src

# Build SOFA
WORKDIR /sofa/build
# RUN git config --global --add safe.directory /sofa/build/_deps/cxxopts-src
RUN cmake \
	-DSOFA_FETCH_SOFAPYTHON3=ON \
	-DPYTHON_EXECUTABLE=$(python -c "import sys; print(sys.executable())") \
    -DPYTHON_INCLUDE_DIR=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())")  \
	-DPYTHON_LIBRARY=$(python -c "import distutils.sysconfig as sysconfig; print(sysconfig.get_config_var('LIBDIR'))") \
    -Dpybind11_DIR=$(python -c "import pybind11; print(pybind11.get_cmake_dir())") \
	../src

# Disable tests
RUN sed -i -E "s/BUILD_TESTS(.+)=ON/BUILD_TESTS\1=OFF/g" CMakeCache.txt

# Compile SOFA
RUN make -j8
ENV SOFA_ROOT=/sofa/build


USER user
WORKDIR /home/user
