FROM debian:bullseye-slim AS binary

LABEL authors="Erik Garrison, Simon Heumos, Andrea Guarracino"
LABEL description="Preliminary docker image containing all requirements for pggb pipeline"
LABEL base_image="debian:bullseye-slim"
LABEL software="pggb"
LABEL about.home="https://github.com/pangenome/pggb"
LABEL about.license="SPDX:MIT"

# dependencies
RUN apt-get update \
    && apt-get install -y \
                       git \
                       bash \
                       cmake \
                       make \
                       g++ \
                       python3-dev \
                       bc \
                       libatomic-ops-dev \
                       autoconf \
                       libgsl-dev \
                       zlib1g-dev \
                       libzstd-dev \
                       libjemalloc-dev \
                       libhts-dev \
                       build-essential \
                       pkg-config \
                       time \
                       curl \
                       pigz \
                       tabix

RUN git clone --recursive https://github.com/waveygang/wfmash \
    && cd wfmash \
    && git pull \
    && git checkout b277f1ae6796c9cc1ba360fe57bcc92d819f29c7 \
    && git submodule update --init --recursive \
    && cmake -H. -DCMAKE_BUILD_TYPE=Generic -Bbuild && cmake --build build -- -j $(nproc) \
    && cp build/bin/wfmash /usr/local/bin/wfmash \
    && cd ../

RUN git clone --recursive https://github.com/ekg/seqwish \
    && cd seqwish \
    && git pull \
    && git checkout f209482924bbb7763d927029ee63cd16c5ddb44c \
    && git submodule update --init --recursive \
    && cmake -H. -DCMAKE_BUILD_TYPE=Generic -Bbuild && cmake --build build -- -j $(nproc) \
    && cp bin/seqwish /usr/local/bin/seqwish \
    && cd ../

RUN git clone --recursive https://github.com/pangenome/smoothxg \
    && cd smoothxg \
    && git pull \
    && git checkout b0bc70fd42f7b263251d2802e47ab9102a27cd26 \
    && git submodule update --init --recursive \
    && sed -i 's/-march=native/-march=haswell/g' deps/abPOA/CMakeLists.txt \
    && cmake -H. -DCMAKE_BUILD_TYPE=Generic -Bbuild && cmake --build build -- -j $(nproc) \
    && cp bin/smoothxg /usr/local/bin/smoothxg \
    && cp deps/odgi/bin/odgi /usr/local/bin/odgi

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo --help

RUN git clone https://github.com/marschall-lab/GFAffix.git \
    && cd GFAffix \
    && git pull \
    && git checkout 9581a29d6dfe1e76a98f8c360ed33adf0348fa27 \
    && cargo install --force --path . && mv /root/.cargo/bin/gfaffix /usr/local/bin/gfaffix

RUN apt-get update && apt-get install -y pip && pip install multiqc==1.11 && apt-get install -y bcftools

RUN apt-get install wget && wget https://github.com/vgteam/vg/releases/download/v1.39.0/vg && chmod +x vg && mv vg /usr/local/bin/vg

COPY pggb /usr/local/bin/pggb
RUN chmod 777 /usr/local/bin/pggb

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
