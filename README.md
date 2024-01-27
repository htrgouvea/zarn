<p align="center">
  <p align="center"><b>ZARN</b></p>
  <p align="center">A lightweight static code security analysis for Modern Perl Applications</p>
  <p align="center">
    <a href="/LICENSE.md">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg">
    </a>
     <a href="https://github.com/htrgouvea/zarn/releases">
      <img src="https://img.shields.io/badge/version-0.0.9-blue.svg">
    </a>
    <br/>
    <img src="https://github.com/htrgouvea/zarn/actions/workflows/linter.yml/badge.svg">
    <img src="https://github.com/htrgouvea/zarn/actions/workflows/sast.yml/badge.svg">
  </p>
</p>

---

### Summary

Performing [static analysis](https://en.wikipedia.org/wiki/Static_program_analysis), Zarn is able to identify possible vulnerabilities: for this purpose, each file is parsed using [AST analysis](https://en.wikipedia.org/wiki/Abstract_syntax_tree) to recognize tokens that present risks and subsequently runs the [taint tracking](https://en.wikipedia.org/wiki/Taint_checking) process to confirm that it is a whether exploitable or not, to validate whether a malicious agent is able to target the method in question.

Currently, Zarn do single file context analysis, which means that it is not able to identify vulnerabilities that are not directly related to the file being analyzed. But in the future, we plan to implement a [call graph](https://en.wikipedia.org/wiki/Call_graph) analysis to identify vulnerabilities that are not directly related to the file being analyzed.

You can read the full publication about Zarn at: [a lightweight static security analysis tool for modern Perl Apps.](https://heitorgouvea.me/2023/03/19/static-security-analysis-tool-perl)

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
$ perl zarn.pl --rules rules/quick-wins.yml --source ../nozaki --sarif report.sarif

[warn] - FILE:../nozaki/lib/Functions/Helper.pm          Potential: Timing Attack.
[vuln] - FILE:../nozaki/lib/Engine/Orchestrator.pm       Potential: Path Traversal.
[vuln] - FILE:../nozaki/lib/Engine/Orchestrator.pm       Potential: Path Traversal.
[warn] - FILE:../nozaki/lib/Engine/FuzzerThread.pm       Potential: Timing Attack.
```
---

### Rules example

```yaml
rules:
  - id: '0001'
    category: info
    name: Debug module enabled
    message:
    sample:
      - Dumper
  - id: '0002'
    category: vuln
    name: Code Injection
    message: 
    sample:
      - system
      - eval
      - exec
  - id: '0003'
    category: vuln
    name: Path Traversal
    message: 
    sample:
      - open
```

---

### Github Actions

```yaml
name: ZARN SAST

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  schedule:
    - cron: '28 23 * * 1'

jobs:
  zarn:
    name: Security Static Analysis with ZARN
    runs-on: ubuntu-20.04
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Perform Static Analysis
      uses: htrgouvea/zarn@0.0.9
```

---

### Contribution

Your contributions and suggestions are heartily ♥ welcome. [See here the contribution guidelines.](/.github/CONTRIBUTING.md) Please, report bugs via [issues page](https://github.com/htrgouvea/zarn/issues) and for security issues, see here the [security policy.](/SECURITY.md) (✿ ◕‿◕) This project follows this [style guide: (https://github.com/htrgouvea/perl-style-guide)](https://github.com/htrgouvea/perl-style-guide).


---

### License

This work is licensed under [MIT License.](/LICENSE.md)