// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.library_imports;

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'stringify.dart';

import 'library_imports_metadata.dart';

main() {
  LibraryMirror lib =
      currentMirrorSystem().findLibrary(#library_imports_metadata);

  LibraryMirror core = currentMirrorSystem().findLibrary(#dart.core);
  LibraryMirror mirrors = currentMirrorSystem().findLibrary(#dart.mirrors);
  LibraryMirror collection =
      currentMirrorSystem().findLibrary(#dart.collection);
  LibraryMirror async = currentMirrorSystem().findLibrary(#dart.async);

  Expect.setEquals([core, mirrors, collection, async],
      lib.libraryDependencies.map((dep) => dep.targetLibrary));

  Expect.stringEquals(
      'import dart.async\n'
      'import dart.collection\n'
      'import dart.core\n'
      'import dart.mirrors as mirrors\n',
      stringifyDependencies(lib));

  Expect.listEquals(
      [].map(reflect).toList(),
      lib.libraryDependencies
          .singleWhere((dep) => dep.targetLibrary == core)
          .metadata);

  Expect.listEquals(
      [m1].map(reflect).toList(),
      lib.libraryDependencies
          .singleWhere((dep) => dep.targetLibrary == mirrors)
          .metadata);

  Expect.listEquals(
      [m2, m3].map(reflect).toList(),
      lib.libraryDependencies
          .singleWhere((dep) => dep.targetLibrary == collection)
          .metadata);

  Expect.listEquals(
      [].map(reflect).toList(),
      lib.libraryDependencies
          .singleWhere((dep) => dep.targetLibrary == async)
          .metadata);
}
