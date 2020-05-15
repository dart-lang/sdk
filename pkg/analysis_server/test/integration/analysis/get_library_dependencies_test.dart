// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetLibraryDependenciesTest);
  });
}

@reflectiveTest
class GetLibraryDependenciesTest extends AbstractAnalysisServerIntegrationTest {
  @failingTest
  Future<void> test_libraryDeps() async {
    // This fails with the new analysis driver ('Bad state: Should not be used
    // with the new analysis driver') - #29310.
    var pathname = sourcePath('test.dart');
    var text = r'''
class Foo {}

class Bar {
  Foo foo;
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;

    var result = await sendAnalysisGetLibraryDependencies();
    var libraries = result.libraries;
    var packageMaps = result.packageMap;

    expect(libraries, contains(pathname));
    expect(libraries.any((String lib) => lib.endsWith('core/core.dart')), true);

    expect(packageMaps.keys, hasLength(1));
    var map = packageMaps[packageMaps.keys.first];
    expect(map.keys, isEmpty);
  }
}
