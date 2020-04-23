// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.library_imports_bad_metadata;

@undefined // //# 01: compile-time error
import 'dart:mirrors';
import 'package:expect/expect.dart';

main() {
  LibraryMirror thisLibrary =
      currentMirrorSystem().findLibrary(#test.library_imports_bad_metadata);

  thisLibrary.libraryDependencies.forEach((dep) {
    Expect.listEquals([], dep.metadata);
  });
}
