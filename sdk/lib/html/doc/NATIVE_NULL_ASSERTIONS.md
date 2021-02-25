# Native Null Assertions in Dart Dev Compiler and Dart2JS

## Overview

In the Dart web platform libraries, e.g. `dart:html`, there are APIs that depend
on JS interoperability. With null-safety, the types returned from these interop
procedures are not null-checked by default. In both DDC and dart2js, there
exists a flag to turn on checks, or native null assertions, for these instances.
In DDC, it's called `nativeNonNullAsserts` and in dart2js, it's called
`--native-null-assertions`.

Specifically, the flag focused on two cases. The first case is checks around
types returned from APIs that are declared `native`. If the return type here is
non-nullable, enabling native null assertions will throw an error if a `null`
value is returned. For example,

`int get foo native;`

will throw an error if `.foo` returns a `null` value. This may happen due to a
number of reasons, one of which could be browser incompatibility.

The second case is on `JS()` invocations. `JS()` is an internal-only function
that allows you to inline JavaScript. If the static type of the `JS()`
invocation is non-nullable, but a `null` value is returned, there will be an
error thrown if native null assertions are enabled.

The goals with these native null assertions are to ensure the Dart web platform
libraries are typed correctly and to help achieve sound null-safety.

If you come across an error related to this flag, this may or may not be a bug
in the Dart web platform libraries. If so, please file a bug at:
https://github.com/dart-lang/sdk/issues/labels/web-libraries

## Disabling native null assertions

Native null assertions will be turned on by default across different build
systems. If it is enabled, here's how you can disable it in the following build
systems:

### build_web_compilers

https://github.com/dart-lang/build/tree/master/docs/native_null_assertions.md
