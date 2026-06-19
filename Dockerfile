FROM perl:5.42-slim

COPY . /usr/src/zarn
WORKDIR /usr/src/zarn

# --notest skips the dependencies' test phase. This avoids building the
# test-only XS modules B::COW (a test dep of Clone) and Test::LeakTrace
# (a test dep of Params::Util), which fail to compile on Perl 5.42 and
# break the PPI install chain. Neither is needed at runtime.
RUN cpanm --installdeps --notest .

ENTRYPOINT [ "perl", "./zarn.pl" ]
