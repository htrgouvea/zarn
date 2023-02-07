FROM perl:5.36

COPY . /usr/src/zarn
WORKDIR /usr/src/zarn

RUN cpanm --installdeps .

ENTRYPOINT [ "perl", "./zarn.pl" ]