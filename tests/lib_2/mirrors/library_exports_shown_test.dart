// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.library_exports_shown;

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'stringify.dart';

import 'library_exports_shown.dart';

test(MirrorSystem mirrors) {
  LibraryMirror shown = mirrors.findLibrary(#library_exports_shown);
  LibraryMirror a = mirrors.findLibrary(#library_imports_a);
  LibraryMirror b = mirrors.findLibrary(#library_imports_b);

  LibraryMirror core = mirrors.findLibrary(#dart.core);

  Expect.setEquals(
      [a, b, core], shown.libraryDependencies.map((dep) => dep.targetLibrary));

  Expect.stringEquals(
      'import dart.core\n'
      'export library_imports_a\n'
      ' show somethingFromA\n'
      ' show somethingFromBoth\n'
      'export library_imports_b\n'
      ' show somethingFromB\n',
      stringifyDependencies(shown));
}

main() {
  test(currentMirrorSystem());
}
