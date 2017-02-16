// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetAnalysisRootsTest);
  });
}

@reflectiveTest
class SetAnalysisRootsTest extends AbstractAnalysisServerIntegrationTest {
  test_options() async {
    String pathname = sourcePath('test.dart');
    writeFile(
        pathname,
        '''
class Foo {
  void bar() {}
}
''');

    // Calling this will call analysis.setAnalysisRoots.
    standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);
  }

  @override
  bool get enableNewAnalysisDriver => true;
}
