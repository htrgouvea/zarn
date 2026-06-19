FROM perl:5.42-slim

COPY . /usr/src/zarn
WORKDIR /usr/src/zarn

RUN cpanm --installdeps .

ENTRYPOINT [ "perl", "./zarn.pl" ]
