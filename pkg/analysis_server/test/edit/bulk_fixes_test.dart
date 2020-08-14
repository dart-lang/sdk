// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BulkFixesTest);
  });
}

@reflectiveTest
class BulkFixesTest extends AbstractAnalysisTest {
  Future<void> assertEditEquals(String expectedSource) async {
    await waitForTasksFinished();
    var edits = await _getBulkEdits();
    expect(edits, hasLength(1));
    var editedSource = SourceEdit.applySequence(testCode, edits[0].edits);
    expect(editedSource, expectedSource);
  }

  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    handler = EditDomainHandler(server);
  }

  Future<void> test_unnecessaryNew() async {
    createProject();
    addAnalysisOptionsFile('''
linter:
  rules:
    - unnecessary_new
''');
    addTestFile('''
class A {}
A f() => new A();
''');

    await assertEditEquals('''
class A {}
A f() => A();
''');
  }

  Future<List<SourceFileEdit>> _getBulkEdits() async {
    var request = EditBulkFixesParams([testFile]).toRequest('0');
    var response = await waitResponse(request);
    var result = EditBulkFixesResult.fromResponse(response);
    return result.edits;
  }
}
