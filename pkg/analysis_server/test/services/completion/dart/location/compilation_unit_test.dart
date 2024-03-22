// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompilationUnitTest);
  });
}

@reflectiveTest
class CompilationUnitTest extends AbstractCompletionDriverTest
    with CompilationUnitTestCases {}

mixin CompilationUnitTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        return suggestion.kind == CompletionSuggestionKind.KEYWORD;
      },
    );
  }

  Future<void> test_definingUnit_export() async {
    await computeSuggestions('''
exp^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  export '';
    kind: keyword
    selection: 8
''');
  }

  Future<void> test_definingUnit_import() async {
    await computeSuggestions('''
imp^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  import '';
    kind: keyword
    selection: 8
''');
  }

  Future<void> test_definingUnit_part() async {
    await computeSuggestions('''
par^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  part '';
    kind: keyword
    selection: 6
  part of '';
    kind: keyword
    selection: 9
''');
  }

  Future<void> test_definingUnit_part_hasImport() async {
    await computeSuggestions('''
import 'dart:math';
par^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  part '';
    kind: keyword
    selection: 6
''');
  }
}
