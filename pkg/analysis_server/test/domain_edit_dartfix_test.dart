// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EditDartfixDomainHandlerTest);
  });
}

@reflectiveTest
class EditDartfixDomainHandlerTest extends AbstractAnalysisTest {
  String libPath;

  void expectSourceEdit(
      SourceEdit sourceEdit, String replacement, int offset, int length) {
    expect(sourceEdit.replacement, replacement);
    expect(sourceEdit.offset, offset);
    expect(sourceEdit.length, length);
  }

  void expectSuggestion(DartFixSuggestion suggestion, String partialText,
      int offset, int length) {
    expect(suggestion.description, contains(partialText));
    expect(suggestion.location.offset, offset);
    expect(suggestion.location.length, length);
  }

  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    createProject();
    libPath = resourceProvider.convertPath('/project/lib');
    testFile = resourceProvider.convertPath('/project/lib/fileToBeFixed.dart');
  }

  test_dartfix_literal_int() async {
    addTestFile('''
const double myDouble = 42.0;
    ''');

    final request = new Request(
        '33', 'edit.dartfix', new EditDartfixParams([libPath]).toJson());

    final response = await new EditDartFix(server, request).compute();
    expect(response.id, '33');

    final result = EditDartfixResult.fromResponse(response);

    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'int literal', 24, 4);

    expect(result.edits, hasLength(1));
    expect(result.edits[0].file, testFile);
    expect(result.edits[0].edits, hasLength(1));
    expectSourceEdit(result.edits[0].edits[0], '42', 24, 4);
  }

  test_dartfix_mixin() async {
    addTestFile('''
class A {}
class B extends A {}
class C with B {}
    ''');

    final request = new Request(
        '33', 'edit.dartfix', new EditDartfixParams([libPath]).toJson());

    final response = await new EditDartFix(server, request).compute();
    expect(response.id, '33');

    final result = EditDartfixResult.fromResponse(response);

    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'mixin', 17, 1);

    expect(result.edits, hasLength(1));
    expect(result.edits[0].file, testFile);
    expect(result.edits[0].edits, hasLength(1));
    expectSourceEdit(result.edits[0].edits[0], 'mixin B implements A ', 11, 18);
  }
}
