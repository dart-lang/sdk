// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'utils.dart';

/// Test that library flags are serialized and read correctly.
main() {
  setSynthetic(Library lib, bool isSynthetic) {
    lib.isSynthetic = isSynthetic;
  }

  verifySynthetic(Library lib, bool isSynthetic) {
    if (lib.isSynthetic != isSynthetic) {
      throw "Serialized and re-read library had change in synthetic flag.";
    }
  }

  setNonNullableByDefault(Library lib, bool isNonNullableByDefault) {
    lib.isNonNullableByDefault = isNonNullableByDefault;
  }

  verifyNonNullableByDefault(Library lib, bool isNonNullableByDefault) {
    if (lib.isNonNullableByDefault != isNonNullableByDefault) {
      throw "Serialized and re-read library had change in "
          "isNonNullableByDefault flag.";
    }
  }

  setNonNullableByDefaultCompiledMode(Library lib,
      NonNullableByDefaultCompiledMode nonNullableByDefaultCompiledMode) {
    lib.nonNullableByDefaultCompiledMode = nonNullableByDefaultCompiledMode;
  }

  verifyNonNullableByDefaultCompiledMode(Library lib,
      NonNullableByDefaultCompiledMode nonNullableByDefaultCompiledMode) {
    if (lib.nonNullableByDefaultCompiledMode !=
        nonNullableByDefaultCompiledMode) {
      throw "Serialized and re-read library had change in "
          "nonNullableByDefaultCompiledMode flag.";
    }
  }

  int combination = 0;
  for (bool isSynthetic in [true, false]) {
    for (bool isNonNullableByDefault in [true, false]) {
      for (NonNullableByDefaultCompiledMode nonNullableByDefaultCompiledMode
          in [
        NonNullableByDefaultCompiledMode.Weak,
        NonNullableByDefaultCompiledMode.Strong,
        NonNullableByDefaultCompiledMode.Agnostic,
      ]) {
        combination++;
        print("Checking combination #$combination ("
            "isSynthetic: $isSynthetic; "
            "isNonNullableByDefault: $isNonNullableByDefault; "
            "nonNullableByDefaultCompiledMode:"
            " $nonNullableByDefaultCompiledMode");
        Library lib = new Library(Uri.parse("foo://bar.dart"));
        setSynthetic(lib, isSynthetic);
        setNonNullableByDefault(lib, isNonNullableByDefault);
        setNonNullableByDefaultCompiledMode(
            lib, nonNullableByDefaultCompiledMode);
        Library lib2 = libRoundTrip(lib);
        verifySynthetic(lib2, isSynthetic);
        verifyNonNullableByDefault(lib2, isNonNullableByDefault);
        verifyNonNullableByDefaultCompiledMode(
            lib2, nonNullableByDefaultCompiledMode);
      }
    }
  }

  print("Done: Everything looks good.");
}
