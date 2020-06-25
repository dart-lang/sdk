# vm_snapshot_analysis

This package provides libraries and a utility for analysing the size and
contents of Dart VM AOT snapshots based on the output of
`--print-instructions-sizes-to` and `--write-v8-snapshot-profile-to` VM flags.

## AOT Snapshot Basics

Dart VM AOT snapshot is simply a serialized representation of the Dart VM
heap graph. It consists of two parts: data (e.g. strings, `const` instances,
objects representing classes, libraries, functions and runtime metadata) and
executable code (machine code generated from Dart sources). Some nodes in this
graph have clean and direct relationship to  the original program (e.g. objects
representing libraries, classes, functions), while other nodes don't. Bitwise
equivalent objects can be deduplicated and shared (e.g. two functions with the
same body will end up using the same machine code object). This makes
impossible to attribute of every single byte from the snapshot to a particular
place in the program with a 100% accuracy.

* `--print-instructions-sizes-to` attributes _executable code_ from the snapshot
to a particular Dart function (or internal stub) from which this code
originated (ignoring deduplication). Executable code usually constitutes around
half of the snapshot, those this varies depending on the application.
* `--write-v8-snapshot-profile-to` is a graph representation of the snapshot,
it attributes bytes written into a snapshot to a node in the heap graph. This
format covers both data and code sections of the snapshot.

## CLI

The command line interface to the tools in this package is provided by a single
entry point `bin/analyse.dart`. It consumes output of
`--print-instructions-sizes-to` and `--write-v8-snapshot-profile-to` flags and
presents it in different human readable ways.

This script can be intalled globally as `snapshot_analysis` using

```console
$ pub global activate vm_snapshot_analysis
```

`snapshot_analysis` supports the following subcommands:

### `summary`

```console
$ snapshot_analysis summary [-b granularity] [-w filter] <input.json>
```

This command shows breakdown of snapshot bytes at the given `granularity` (e.g.
`method`, `class`, `library` or `package`), filtered by the given substring
`filter`.

For example, here is a output showing how many bytes from a snapshot
can be attributed to classes in the `dart:core` library:

```console
$ pkg/vm/bin/snapshot_analysis.dart summary -b class -w dart:core profile.json
+-----------+------------------------+--------------+---------+----------+
| Library   | Class                  | Size (Bytes) | Percent | Of total |
+-----------+------------------------+--------------+---------+----------+
| dart:core | _Uri                   |        43563 |  15.53% |    5.70% |
| dart:core | _StringBase            |        28831 |  10.28% |    3.77% |
| dart:core | ::                     |        27559 |   9.83% |    3.60% |
| @other    |                        |        25467 |   9.08% |    3.33% |
| dart:core | Uri                    |        14936 |   5.33% |    1.95% |
| dart:core | int                    |        12276 |   4.38% |    1.61% |
| dart:core | NoSuchMethodError      |        12222 |   4.36% |    1.60% |
...
```

Here objects which can be attributed to `_Uri` take `5.7%` of the snapshot,
at the same time objects which can be attributed to `dart:core` library
but not to any specific class within this library take `3.33%` of the snapshot.


### `compare`

```console
$ snapshot_analysis compare [-b granularity] <old.json> <new.json>
```

This command shows comparison between two size profiles, allowing to understand
changes to which part of the program contributed most to the change in the
overall snapshot size.

```console
$ pkg/vm/bin/snapshot_analysis.dart compare -b class old.json new.json
+------------------------+--------------------------+--------------+---------+
| Library                | Class                    | Diff (Bytes) | Percent |
+------------------------+--------------------------+--------------+---------+
| dart:core              | _SimpleUri               |        11519 |  22.34% |
| dart:core              | _Uri                     |         6563 |  12.73% |
| dart:io                | _RandomAccessFile        |         5337 |  10.35% |
| @other                 |                          |         4009 |   7.78% |
...
```

In this example `11519` more bytes can be attributed to `_SimpleUri` class in
`new.json` compared to `old.json`.

### `treemap`

```console
$ snapshot_analysis treemap <input.json> <output-dir>
$ google-chrome <output-dir>/index.html
```

This command generates treemap representation of the information from the
profile `input.json` and stores it in `output-dir` directory. Treemap can
later be viewed by opening `<output-dir>/index.html` in the browser of your
choice.

## API

This package can also be used as a building block for other packages which
want to analyse VM AOT snapshots.

* `package:vm_snapshot_analysis/instruction_sizes.dart` provides helpers to
read output of `--print-instructions-sizes-to=...`
* `package:vm_snapshot_analysis/v8_profile.dart` provides helpers to read
output of `--write-v8-snapshot-profile-to=...`

Both formats can be converted into a `ProgramInfo` structure which attempts
to breakdown snapshot size into hierarchical representation of the program
structure which can be understood by a Dart developer, attributing bytes
to packages, libraries, classes and functions.

* `package:vm_snapshot_analysis/utils.dart` contains helper method
`loadProgramInfo` which automatically detects format of the input JSON file
and creates `ProgramInfo` in an appropriate way, allowing to write code
which works in the same way with both formats.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/sdk/issues
