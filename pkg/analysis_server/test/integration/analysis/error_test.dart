// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisErrorIntegrationTest);
  });
}

@reflectiveTest
class AnalysisErrorIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_analysisRootDoesNotExist() async {
    var packagePath = sourcePath('package');
    var filePath = sourcePath('package/lib/test.dart');
    var content = '''
void f() {
  print(null) // parse error: missing ';'
}''';
    await sendServerSetSubscriptions([ServerService.STATUS]);
    await sendAnalysisUpdateContent({filePath: AddContentOverlay(content)});
    await sendAnalysisSetAnalysisRoots([packagePath], []);
    await analysisFinished;

    expect(currentAnalysisErrors[filePath], isList);
    var errors = existingErrorsForFile(filePath);
    expect(errors, hasLength(1));
    expect(errors[0].location.file, equals(filePath));
  }

  Future<void> test_detect_simple_error() async {
    var pathname = sourcePath('test.dart');
    writeFile(pathname, '''
void f() {
  print(null) // parse error: missing ';'
}''');
    await standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isList);
    var errors = existingErrorsForFile(pathname);
    expect(errors, hasLength(1));
    expect(errors[0].location.file, equals(pathname));
  }
}
