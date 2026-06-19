FROM perl:5.42-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*

COPY . /usr/src/zarn
WORKDIR /usr/src/zarn

RUN cpanm --installdeps --notest .

ENTRYPOINT [ "perl", "./zarn.pl" ]
