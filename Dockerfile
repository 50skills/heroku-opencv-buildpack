# Base image heroku-16
FROM heroku/heroku:16

# Make folder structure
RUN mkdir /app
RUN mkdir /app/.heroku
RUN mkdir /app/.heroku/vendor
ENV LD_LIBRARY_PATH /app/.heroku/vendor/lib/


# Install ATLAS with LAPACK and BLAS
WORKDIR /app/.heroku
RUN apt-get update
RUN apt-get install -y gfortran
RUN curl -s -L http://www.netlib.org/lapack/lapack-3.6.1.tgz > lapack-3.6.1.tgz
RUN curl -s -L http://netix.dl.sourceforge.net/project/math-atlas/Stable/3.10.3/atlas3.10.3.tar.bz2 > /app/.heroku/atlas3.10.3.tar.bz2
RUN bunzip2 -c atlas3.10.3.tar.bz2 | tar xfm -
RUN mkdir /app/.heroku/ATLAS/Linux_C2D64SSE3
WORKDIR /app/.heroku/ATLAS/Linux_C2D64SSE3
RUN ../configure -b 64 -D c -DPentiumCPS=2400 \
     --prefix=/app/.heroku/vendor/ \
     --with-netlib-lapack-tarfile=/app/.heroku/lapack-3.6.1.tgz
RUN make build && make check && make ptcheck && make time && make install
WORKDIR /app/.heroku
RUN rm lapack-3.6.1.tgz
RUN rm atlas3.10.3.tar.bz2
RUN rm -r ATLAS
ENV ATLAS /app/.heroku/vendor/lib/libatlas.a
ENV BLAS /app/.heroku/vendor/lib/libcblas.a
ENV LAPACK /app/.heroku/vendor/lib/liblapack.a

RUN curl -s -L http://kent.dl.sourceforge.net/project/tcl/Tcl/8.6.6/tcl8.6.6-src.tar.gz > tcl8.6.6-src.tar.gz
RUN tar -xvf tcl8.6.6-src.tar.gz
RUN rm tcl8.6.6-src.tar.gz
WORKDIR /app/.heroku/tcl8.6.6/unix
RUN ./configure --prefix=/app/.heroku/vendor/
RUN make && make install
WORKDIR /app/.heroku/
RUN curl -s -L http://heanet.dl.sourceforge.net/project/tcl/Tcl/8.6.6/tk8.6.6-src.tar.gz > tk8.6.6-src.tar.gz
RUN tar -xvf tk8.6.6-src.tar.gz
RUN rm tk8.6.6-src.tar.gz
WORKDIR /app/.heroku/tk8.6.6/unix
RUN ./configure --prefix=/app/.heroku/vendor/ --with-tcl=/app/.heroku/tcl8.6.6/unix
RUN make && make install
WORKDIR /app/.heroku/
RUN rm -r tcl8.6.6
RUN rm -r tk8.6.6

# Install Numpy
RUN pip install -v numpy==1.11.1

# Install Scipy
RUN pip install -v scipy==0.18.0

# Install Opencv with python bindings
RUN apt-get install -y cmake
RUN curl -s -L https://github.com/opencv/opencv/archive/3.3.0.zip > opencv-3.3.0.zip
RUN unzip opencv-3.3.0.zip
RUN rm opencv-3.3.0.zip
WORKDIR /app/.heroku/opencv-3.3.0.zip
RUN cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/app/.heroku/vendor -D BUILD_DOCS=OFF -D BUILD_TESTS=OFF -D BUILD_PERF_TESTS=OFF -D WITH-FFMPEG=ON -D BUILD_EXAMPLES=OFF -D BUILD_opencv_python=ON .
RUN make install
WORKDIR /app/.heroku
RUN rm -rf opencv-3.3.0.zip

# Create vendor package
WORKDIR /app/
RUN tar cvfj /vendor.tar.bz2 .
VOLUME /vendoring
CMD cp /vendor.tar.bz2 /vendoring
