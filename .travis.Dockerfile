FROM ubuntu:18.10

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc-7 \
    g++-7 \
    clang-format-7 \
    clang-tools-7 \
    clang-tidy-7 \
    cmake \
    libclang-7-dev \
    libfile-spec-native-perl \
    libgtest-dev

# Set up clang compilers
ENV CC=/usr/bin/gcc-7 \
    CXX=/usr/bin/g++-7

# Fix issues with gtest installation from ubuntu debian
RUN cd /usr/src/gtest && \
    cmake . && \
    make && \
    mv libg* /usr/lib

# Fix issues with clang installation from ubuntu debian
RUN mkdir -p /usr/lib/cmake && \
    ln -s /usr/share/llvm-7/cmake /usr/lib/cmake/clang && \
    for hdr in /usr/lib/llvm-7/include/clang/*; do \
        ln -s $hdr /usr/include/clang/$(basename $hdr); \
    done && \
    ln -s /usr/lib/llvm-7/include/clang-c /usr/include/clang-c && \
    ln -s /usr/lib/llvm-7/include/llvm /usr/include/llvm && \
    ln -s /usr/lib/llvm-7/include/llvm-c /usr/include/llvm-c && \
    for lib in /usr/lib/llvm-7/lib/*; do \
        ln -s $lib /usr/lib/$(basename $lib); \
    done && \
    for bin in /usr/bin/*-7; do \
        ln -s $bin /usr/bin/$(basename $bin | rev | cut -d '-' -f2- | rev); \
    done

COPY . clangmetatool/
WORKDIR clangmetatool

# Build tool, run tests, and do a test install
RUN mkdir build && cd build && \
    cmake -DClang_DIR=/usr/share/llvm-7/cmake .. && \
    make all test && \
    make install && \
    cd .. && rm -rf build

# Fix includes for clangmetatool (due to ubuntu debian's clang)
RUN ln -s /usr/lib/llvm-7/include/clangmetatool /usr/include/clangmetatool

# Build skeleton
RUN mkdir skeleton/build && cd skeleton/build && \
    cmake -DClang_DIR=/usr/lib/llvm-7/cmake \
          -Dclangmetatool_DIR=/usr/lib/llvm-7/cmake .. && \
    make all && \
    make install && \
    cd - && rm -rf skeleton/build

# Run the tool on itself
RUN yourtoolname $(find src skeleton -name '*.cpp') -- -std=gnu++14
