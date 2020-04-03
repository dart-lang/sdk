// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:path/path.dart' show join;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetGeneralSubscriptionsTest);
  });
}

@reflectiveTest
class SetGeneralSubscriptionsTest
    extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_options() async {
    var pathname = sourcePath('test.dart');
    writeFile(pathname, '''
class Foo {
  void bar() {}
}
''');

    standardAnalysisSetup();

    await sendAnalysisSetGeneralSubscriptions(
        [GeneralAnalysisService.ANALYZED_FILES]);
    await analysisFinished;

    expect(lastAnalyzedFiles, isNotEmpty);
    expect(lastAnalyzedFiles, contains(pathname));
    expect(
        lastAnalyzedFiles
            .any((String file) => file.endsWith(join('core', 'core.dart'))),
        true);
  }
}
