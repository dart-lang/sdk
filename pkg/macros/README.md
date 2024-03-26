☠☠ **Warning: This package is experimental and may not be available in a future
version of Dart.** ☠☠

This package is for macro authors, and exposes the APIs necessary to write
a macro. Specifically, it exports the private `_macros` SDK vendored package.

## Macro authors

Macro authors can use normal constraints on this package, and should only import
the `package:macros/macros.dart` file.

Note that the versions of this package are tied directly to your SDK version, so
you won't be able to get new feature releases without updating your SDK.

## Compilers and tools

This package also exposes some "private" sources (under lib/src), intended only
for use by compilers and tools, in order to bootstrap and execute macros.

When depending on these "private" sources, a more narrow constraint should be
used, which constraints to feature releases (which means patch versions until
such time as this package goes to 1.0.0). For example,
`macros: ">=0.1.1 <0.1.2"`.
