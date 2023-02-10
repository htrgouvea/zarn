<p align="center">
  <p align="center"><b>ZARN</b></p>
  <p align="center">A lightweight static code security analysis for Modern Perl Applications</p>
  <p align="center">
    <a href="/LICENSE.md">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg">
    </a>
     <a href="https://github.com/htrgouvea/zarn/releases">
      <img src="https://img.shields.io/badge/version-0.0.2-blue.svg">
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
$ git clone https://github.com/htrgouvea/zarn && cd zarn
    
# Install libs dependencies
$ sudo cpanm --installdeps .
```
---

### Example of use

```bash
$ perl zarn.pl --rules rules/quick-wins.yml --source ../nozaki 

[warn] - FILE:../nozaki/lib/Functions/Helper.pm          Potential: Timing Attack.
[vuln] - FILE:../nozaki/lib/Engine/Orchestrator.pm       Potential: Path Traversal.
[vuln] - FILE:../nozaki/lib/Engine/Orchestrator.pm       Potential: Path Traversal.
[warn] - FILE:../nozaki/lib/Engine/FuzzerThread.pm       Potential: Timing Attack.
```
---

### Rules example

```yaml
- id: '0001'
  category: vuln
  name: Remote Command Execution // Code Injection
  message: 
  sample:
    - system
    - eval
    - exec
- id: '0002'
  category: vuln
  name: Path Traversal
  message: 
  sample:
    - open
```

---

### Using with Github Actions

```yaml
Coming soon...
```

---

### Contribution

- Your contributions and suggestions are heartily ♥ welcome. [See here the contribution guidelines.](/.github/CONTRIBUTING.md) Please, report bugs via [issues page](https://github.com/htrgouvea/nipe/issues) and for security issues, see here the [security policy.](/SECURITY.md) (✿ ◕‿◕) This project follows the best practices defined by this [style guide](https://heitorgouvea.me/projects/perl-style-guide).

---

### License

- This work is licensed under [MIT License.](/LICENSE.md)

--- 

### References

1. [https://en.wikipedia.org/wiki/Static_program_analysis](https://en.wikipedia.org/wiki/Static_program_analysis)