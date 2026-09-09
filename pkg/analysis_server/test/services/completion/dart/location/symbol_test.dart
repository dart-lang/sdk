// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SymbolTest);
  });
}

@reflectiveTest
class SymbolTest extends AbstractCompletionDriverTest with SymbolTestCases {}

mixin SymbolTestCases on AbstractCompletionDriverTest {
  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/39003',
    reason: "completion.getSuggestions2 failed: RequestErrorCode.SERVER_ERROR: 'package:analyzer_plugin/src/utilities/completion/optype.dart': Failed assertion: line 661 pos 12: 'false': is not true.",
  )
  Future<void> test_afterHash_atEndOfFile() async {
    await computeSuggestions('''
f() { #^
''');

    assertResponse(r'''
suggestions
''');
  }
}
