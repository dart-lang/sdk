// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.library_imports_prefixed_show_hide;

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'stringify.dart';

import 'library_imports_prefixed_show_hide.dart';

test(MirrorSystem mirrors) {
  LibraryMirror prefixed_show_hide =
      mirrors.findLibrary(#library_imports_prefixed_show_hide);
  LibraryMirror a = mirrors.findLibrary(#library_imports_a);
  LibraryMirror b = mirrors.findLibrary(#library_imports_b);
  LibraryMirror core = mirrors.findLibrary(#dart.core);

  Expect.setEquals([a, b, core],
      prefixed_show_hide.libraryDependencies.map((dep) => dep.targetLibrary));

  Expect.stringEquals(
      'import dart.core\n'
      'import library_imports_a as prefixa\n'
      ' show somethingFromA\n'
      'import library_imports_b as prefixb\n'
      ' hide somethingFromB\n',
      stringifyDependencies(prefixed_show_hide));
}

main() {
  test(currentMirrorSystem());
}
