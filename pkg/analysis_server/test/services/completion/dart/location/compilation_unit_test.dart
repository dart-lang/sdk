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

  Future<void> test_library_export() async {
    await computeSuggestions('''
library;
exp^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  export '^';
    kind: keyword
''');
  }

  Future<void> test_library_import() async {
    await computeSuggestions('''
library;
imp^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  import '^';
    kind: keyword
''');
  }

  Future<void> test_library_part() async {
    await computeSuggestions('''
library;
par^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  part '^';
    kind: keyword
''');
  }

  Future<void> test_library_part_hasImport() async {
    await computeSuggestions('''
library;
import 'dart:math';
par^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  part '^';
    kind: keyword
''');
  }

  Future<void> test_part_export() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await computeSuggestions('''
part of 'lib.dart';
exp^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  export '^';
    kind: keyword
''');
  }

  Future<void> test_part_import() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await computeSuggestions('''
part of 'lib.dart';
imp^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  import '^';
    kind: keyword
''');
  }

  Future<void> test_part_part() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await computeSuggestions('''
part of 'lib.dart';
par^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  part '^';
    kind: keyword
''');
  }

  Future<void> test_part_part_hasImport() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await computeSuggestions('''
part of 'lib.dart';
import 'dart:math';
par^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  part '^';
    kind: keyword
''');
  }

  Future<void> test_unknown_export() async {
    await computeSuggestions('''
exp^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  export '^';
    kind: keyword
''');
  }

  Future<void> test_unknown_import() async {
    await computeSuggestions('''
imp^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  import '^';
    kind: keyword
''');
  }

  Future<void> test_unknown_part() async {
    await computeSuggestions('''
par^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  part '^';
    kind: keyword
  part of '^';
    kind: keyword
''');
  }

  Future<void> test_unknown_part_hasImport() async {
    await computeSuggestions('''
import 'dart:math';
par^
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  part '^';
    kind: keyword
''');
  }
}
