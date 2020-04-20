Tool for extracting symbolic information from C++ Dart Runtime sources using
[cquery](https://github.com/cquery-project/cquery).

It should be invoked from the root of Dart SDK checkout and will generate
`xref.json` file containing extracted symbol information.

```
$ pushd runtime/tools/wiki/xref_extractor && pub get && popd
$ dart runtime/tools/wiki/xref_extractor/bin/main.dart cquery/build/release/bin/cquery
```

# Prerequisites

1. Build [cquery](https://github.com/cquery-project/cquery) as described [here](https://github.com/cquery-project/cquery/wiki/Building-cquery).
2. Make sure that you have ninja files generated for ReleaseX64 configuration by
running `tools/gn.py -a x64 -m release --no-goma` (`--no-goma` is important -
otherwise `cquery` can't figure out which toolchain is used).

# `xref.json` format

```typescript
interface Xrefs {
    /// Commit hash for which this xref.json is generated.
    commit: string;

    /// List of files names.
    files: string[];

    /// Class information by name.
    classes: ClassMap;

    /// Global function information.
    functions: LocationMap;
}

/// Locations are serialized as strings of form "fileIndex:lineNo", where
/// fileIndex points into files array.
type SymbolLocation = string;

/// Information about classes is stored in an array where the first element
/// describes location of the class itself and second optional element gives
/// locations of class members.
type ClassInfo = [SymbolLocation, LocationMap?];

/// Map of classes by their names.
interface ClassMap {
    [name: string]: ClassInfo;
}

/// Map of symbols to their locations.
interface LocationMap {
    [symbol: string]: SymbolLocation;
}
```