FROM perl:5.36

COPY . /usr/src/secureperl
WORKDIR /usr/src/secureperl

RUN cpanm --installdeps .

ENTRYPOINT [ "perl", "./secureperl.pl" ]