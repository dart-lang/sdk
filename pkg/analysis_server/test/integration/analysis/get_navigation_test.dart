// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetNavigationTest);
  });
}

@reflectiveTest
class GetNavigationTest extends AbstractAnalysisServerIntegrationTest {
  test_navigation() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
class Foo {}

class Bar {
  Foo foo;
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    await analysisFinished;

    AnalysisGetNavigationResult result =
        await sendAnalysisGetNavigation(pathname, text.indexOf('Foo foo'), 0);
    expect(result.targets, hasLength(1));
    NavigationTarget target = result.targets.first;
    expect(target.kind, ElementKind.CLASS);
    expect(target.offset, text.indexOf('Foo {}'));
    expect(target.length, 3);
    expect(target.startLine, 1);
    expect(target.startColumn, 7);
  }

  @failingTest
  test_navigation_no_result() async {
    // This fails - it returns navigation results for a whitespace area (#28799).
    String pathname = sourcePath('test.dart');
    String text = r'''
//

class Foo {}

class Bar {
  Foo foo;
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    await analysisFinished;

    AnalysisGetNavigationResult result =
        await sendAnalysisGetNavigation(pathname, 0, 0);
    expect(result.targets, isEmpty);
  }

  @override
  bool get enableNewAnalysisDriver => true;
}
