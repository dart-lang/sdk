// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/dependencies/library_dependencies.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryDependenciesTest);
  });
}

@reflectiveTest
class LibraryDependenciesTest extends AbstractContextTest {
  @override
  bool get enableNewAnalysisDriver => false;

  test_LibraryDependencies() {
    addSource('/lib1.dart', 'import "lib2.dart";');
    addSource('/lib2.dart', 'import "lib1.dart";');
    addSource('/lib3.dart', 'import "lib2.dart";');
    addSource('/lib4.dart', 'import "lib5.dart";');
    provider.newFile('/lib5.dart', 'import "lib6.dart";');
    provider.newFile('/lib6.dart', '');

    _performAnalysis();

    var libs =
        new LibraryDependencyCollector([context]).collectLibraryDependencies();

    // Cycles
    expect(libs, contains('/lib1.dart'));
    expect(libs, contains('/lib2.dart'));
    // Regular sources
    expect(libs, contains('/lib3.dart'));
    expect(libs, contains('/lib4.dart'));
    // Non-source, referenced by source
    expect(libs, contains('/lib5.dart'));
    // Non-source, referenced by non-source
    expect(libs, contains('/lib6.dart'));
  }

  test_PackageMaps() {
    //TODO(pquitslund): add test
  }

  void _performAnalysis() {
    while (context.performAnalysisTask().hasMoreWork) {}
  }
}
