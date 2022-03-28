// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatIfEnabledTest);
  });
}

@reflectiveTest
class FormatIfEnabledTest extends AbstractAnalysisTest {
  @override
  Future<void> setUp() async {
    super.setUp();
    await createProject();
    handler = EditDomainHandler(server);
  }

  Future<void> test_enabled() async {
    newAnalysisOptionsYamlFile2(testFolder, '''
code-style:
  format: true
''');
    addTestFile('''
void f() { int x = 3; }
''');
    newFile2('$testFolder/a.dart', '''
class A { A(); }
''');
    var edits = await _format();
    expect(edits, isNotNull);
    expect(edits, hasLength(2));
  }

  Future<void> test_notEnabled() async {
    addTestFile('''
void f() { int x = 3; }
''');
    var edits = await _format();
    expect(edits, isNotNull);
    expect(edits, hasLength(0));
  }

  Future<void> test_withErrors() async {
    addTestFile('''
void f() { int x =
''');
    var edits = await _format();
    expect(edits, isNotNull);
    expect(edits, hasLength(0));
  }

  Future<List<SourceFileEdit>> _format() async {
    await waitForTasksFinished();
    var request = EditFormatIfEnabledParams([testFolder]).toRequest('0');
    var response = await waitResponse(request);
    return EditFormatIfEnabledResult.fromResponse(response).edits;
  }
}
