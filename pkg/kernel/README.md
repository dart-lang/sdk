Dart Kernel
===========
**Dart Kernel** is a small high-level language derived from Dart.  It is
designed for use as an intermediate format for whole-program analysis and
transformations, and to be consumed by codegen and execution backends.

The kernel language has an in-memory representation in Dart and can be
serialized as binary or text.

Both the kernel language and its implementations are unstable and are under
development.

This package contains the Dart part of the implementation and contains:
- A transformable IR for the kernel language
- Serialization of kernel code

_Note:_ The APIs in this package are in an early state; developers should be
careful about depending on this package.  In particular, there is no semver
contract for release versions of this package.  Please depend directly
on individual versions.

See [ast.dart](lib/ast.dart) for the in-memory IR, or [binary.md](binary.md) for
a description of the binary format.  For now, the textual format is very ad-hoc
and cannot be parsed back in.
