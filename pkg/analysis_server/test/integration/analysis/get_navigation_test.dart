// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetNavigationTest);
  });
}

@reflectiveTest
class GetNavigationTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_navigation() async {
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

    var result =
        await sendAnalysisGetNavigation(pathname, text.indexOf('Foo foo'), 0);
    expect(result.targets, hasLength(1));
    var target = result.targets.first;
    expect(target.kind, ElementKind.CLASS);
    expect(target.offset, text.indexOf('Foo {}'));
    expect(target.length, 3);
    expect(target.startLine, 1);
    expect(target.startColumn, 7);
  }

  Future<void> test_navigation_no_result() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
//

class Foo {}

class Bar {
  Foo foo;
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    await analysisFinished;

    var result = await sendAnalysisGetNavigation(pathname, 0, 0);
    expect(result.targets, isEmpty);
  }
}
