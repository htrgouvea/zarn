FROM perl:5.34

COPY . /usr/src/secureperl
WORKDIR /usr/src/secureperl

RUN cpanm --installdeps .

ENTRYPOINT [ "perl", "./secureperl.pl" ]