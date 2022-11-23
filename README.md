<p align="center">
  <p align="center">SECUREPERL</p>
  <p align="center">A lightweight static code security analysis for Modern Perl Applications</p>
  <p align="center">
    <a href="/LICENSE.md">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg">
    </a>
  </p>
</p>

---

### Summary

"Static program analysis is the analysis of computer software that is performed without actually executing programs, in contrast with dynamic analysis, which is analysis performed on programs while they are executing."[[1]](#references)

---

### Download and install

```bash
# Download
$ git clone https://github.com/htrgouvea/secureperl && cd secureperl
    
# Install libs and dependencies
$ sudo cpan install Perl::Critic Path::Iterator::Rule
```
---

### Example of use

```bash
```
---

### Using with Github Actions

```yaml
name: secureperl
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v1
    - name: Audit code
      run: |
        sudo apt install -y libpath-iterator-rule-perl libtest-perl-critic-perl 
        curl https://raw.githubusercontent.com/htrgouvea/secureperl/main/secureperl.pl | perl
```

### Contribution

- Your contributions and suggestions are heartily ♥ welcome. [See here the contribution guidelines.](/.github/CONTRIBUTING.md) Please, report bugs via [issues page](https://github.com/htrgouvea/nipe/issues) and for security issues, see here the [security policy.](/SECURITY.md) (✿ ◕‿◕) This project follows the best practices defined by this [style guide](https://heitorgouvea.me/projects/perl-style-guide).

---

### License

- This work is licensed under [MIT License.](/LICENSE.md)


### References

1. [https://en.wikipedia.org/wiki/Static_program_analysis](https://en.wikipedia.org/wiki/Static_program_analysis)
2. [https://metacpan.org/pod/Perl::Critic](https://metacpan.org/pod/Perl::Critic)