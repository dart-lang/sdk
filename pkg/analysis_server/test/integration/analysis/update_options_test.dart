// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateOptionsTest);
  });
}

@reflectiveTest
class UpdateOptionsTest extends AbstractAnalysisServerIntegrationTest {
  @failingTest
  test_options() async {
    // We fail after the first analysis.updateOptions - we should not see a hint
    // for the unused import (#28800).
    String pathname = sourcePath('test.dart');
    writeFile(pathname, '''
import 'dart:async'; // unused

class Foo {
  void bar() {}
}
''');
    standardAnalysisSetup();

    // ignore: deprecated_member_use
    await sendAnalysisUpdateOptions(
        new AnalysisOptions()..generateHints = false);
    await sendAnalysisReanalyze();
    await analysisFinished;
    expect(getErrors(pathname), isEmpty);

    // ignore: deprecated_member_use
    await sendAnalysisUpdateOptions(
        new AnalysisOptions()..generateHints = true);
    await sendAnalysisReanalyze();
    await analysisFinished;
    expect(getErrors(pathname), hasLength(1));
  }
}
