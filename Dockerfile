FROM perl:5.42-slim

COPY . /usr/src/zarn
WORKDIR /usr/src/zarn

# --notest skips the test phase of dependencies. This avoids pulling in
# Clone's test-only dependency B::COW, which fails to build on Perl 5.42.
RUN cpanm --installdeps --notest .

ENTRYPOINT [ "perl", "./zarn.pl" ]
