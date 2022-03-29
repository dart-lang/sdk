// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompilationUnitTest1);
    defineReflectiveTests(CompilationUnitTest2);
  });
}

@reflectiveTest
class CompilationUnitTest1 extends AbstractCompletionDriverTest
    with CompilationUnitTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class CompilationUnitTest2 extends AbstractCompletionDriverTest
    with CompilationUnitTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin CompilationUnitTestCases on AbstractCompletionDriverTest {
  Future<void> test_definingUnit_export() async {
    var response = await getTestCodeSuggestions('''
exp^
''');

    check(response).suggestions.includesAll([
      (suggestion) => suggestion
        ..completion.isEqualTo("export '';")
        ..kind.isKeyword
        ..hasSelection(offset: 8),
    ]);

    if (isProtocolVersion2) {
      check(response).suggestions.excludesAll([
        (suggestion) => suggestion.completion.startsWith('import'),
      ]);
    }
  }

  Future<void> test_definingUnit_import() async {
    var response = await getTestCodeSuggestions('''
imp^
''');

    check(response).suggestions.includesAll([
      (suggestion) => suggestion
        ..completion.isEqualTo("import '';")
        ..kind.isKeyword
        ..hasSelection(offset: 8),
    ]);

    if (isProtocolVersion2) {
      check(response).suggestions.excludesAll([
        (suggestion) => suggestion.completion.startsWith('export'),
      ]);
    }
  }

  Future<void> test_definingUnit_part() async {
    var response = await getTestCodeSuggestions('''
par^
''');

    check(response).suggestions.includesAll([
      (suggestion) => suggestion
        ..completion.isEqualTo("part '';")
        ..kind.isKeyword
        ..hasSelection(offset: 6),
    ]);
  }
}
