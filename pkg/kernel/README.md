Dart Kernel
===========
**Dart Kernel** is a small high-level language derived from Dart.
It is designed for use as an intermediate format for whole-program analysis
and transformations, and as a frontend for codegen and execution backends.

The kernel language has in-memory representations in Dart and C++, and
can be serialized as binary or text.

Both the kernel language and its implementations are very early in development.

This package contains the Dart part of the implementation and contains:
- A transformable IR for the kernel language
- A frontend based on the analyzer
- Serialization of kernel code

Planned or work-in-progress:
- Deserialization of text format
- More essential infrastructure
- Global type propagation
- Transformations


Command-Line Tool
-----------------

Run `bin/dartk.dart` from the command-line to convert between .dart files
and the serialized binary and textual formats.

`dartk` expects the `.dill` extension for files in the binary format.
The textual format has no preferred extension right now.

Example commands:
```bash
dartk foo.dart            # print text IR for foo.dart
dartk foo.dart -ofoo.dill # write binary IR for foo.dart to foo.dill
dartk foo.dill            # print text IR for binary file foo.dill
```

Pass the `--link` or `-l` flag to link all transitive dependencies into one file:
```bash
dartk myapp.dart -ppackages -l -omyapp.dill # Bundle everything.
dartk myapp.dill # Print it back out in a (very, very long) textual format.
```

See [ast.dart](lib/ast.dart) for the in-memory IR, or [binary.md](binary.md) for
a description of the binary format.  For now, the textual format is very ad-hoc
and cannot be parsed back in.


Library and Program Files
-------------------------
Kernel distinguishes between **library files** and **program files**.

Program files are self-contained and cannot reference anything outside the file.
Library files contain exactly one library and can import other libraries by a
URI equivalent to how imports work in a .dart file.

Library files are a provisional concept and should not be used for anything
serious yet, but can be used for quick experiments, like measuring the binary
file size on a per-library basis.
