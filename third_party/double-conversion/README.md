Double Conversion
========
https://github.com/google/double-conversion

[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/google/double-conversion/badge)](https://securityscorecards.dev/viewer/?uri=github.com/google/double-conversion)

This project (double-conversion) provides binary-decimal and decimal-binary
routines for IEEE doubles.

The library consists of efficient conversion routines that have been extracted
from the V8 JavaScript engine. The code has been refactored and improved so that
it can be used more easily in other projects.

There is extensive documentation in `double-conversion/string-to-double.h` and
`double-conversion/double-to-string.h`. Other examples can be found in
`test/cctest/test-conversions.cc`.


Building
========

This library can be built with [scons][0], [cmake][1] or [bazel][2].
The checked-in Makefile simply forwards to scons, and provides a
shortcut to run all tests:

    make
    make test

Scons
-----

The easiest way to install this library is to use `scons`. It builds
the static and shared library, and is set up to install those at the
correct locations:

    scons install

Use the `DESTDIR` option to change the target directory:

    scons DESTDIR=alternative_directory install

Cmake
-----

To use cmake run `cmake .` in the root directory. This overwrites the
existing Makefile.

Use `-DBUILD_SHARED_LIBS=ON` to enable the compilation of shared libraries.
Note that this disables static libraries. There is currently no way to
build both libraries at the same time with cmake.

Use `-DBUILD_TESTING=ON` to build the test executable.

    cmake . -DBUILD_TESTING=ON
    make
    test/cctest/cctest

Bazel
---

The simplest way to adopt this library is through the [Bazel Central Registry](https://registry.bazel.build/modules/double-conversion).

To build the library from the latest repository, run:

```
bazel build //:double-conversion
```

To run the unit test, run:

```
bazel test //:cctest
```

[0]: http://www.scons.org/
[1]: https://cmake.org/
[2]: https://bazel.build/
