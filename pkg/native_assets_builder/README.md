This package contains the logic for building native assets.

This package is the backend that invokes toplevel `build.dart` scripts.
For more info on these scripts see https://github.com/dart-lang/native.

This is a separate package so that dartdev and flutter_tools can reuse
the same logic with flutter_tools having to import dartdev.
