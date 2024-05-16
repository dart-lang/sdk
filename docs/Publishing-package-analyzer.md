> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

## Publishing an alpha version

`package:analyzer` depends on kernel and front_end. We push those last two packages for the benefit of `package:analyzer`, but their APIs don't currently follow semver, so we set analyzer to depend on exact versions.

Publishing a new alpha version of package analyzer involves a few steps:
- rev package:analyzer to a new alpha version (`0.31.0-alpha.0` ==> `0.31.0-alpha.1`)
- rev package:front_end to a new alpha version; update its version of package:kernel (see the next line)
- rev package:kernel to a new alpha version; update its version of package:front_end
- update the kernel and front_end version in `package:analyzer`'s pubspec
- commit a CL with the above changes
- publish `package:analyzer`, `package:kernel`, and `package:front_end`

## Publishing a new stable version

Many packages depend on `package:analyzer`. These packages often have version constraints that have an upper bound on the last major version of the analyzer. Publishing a new major version of `package:analyzer` requires careful orchestration with other major packages in the Dart ecosystem (in particular, `package:test`, and to a lesser extent, `package:angular`).
