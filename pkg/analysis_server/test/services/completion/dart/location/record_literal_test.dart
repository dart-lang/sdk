// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordLiteralFieldsTest);
  });
}

@reflectiveTest
class RecordLiteralFieldsTest extends AbstractCompletionDriverTest {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;

  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        final completion = suggestion.completion;
        return ['foo0', 'bar0'].any(completion.startsWith);
      },
    );
  }

  Future<void> test_context02_left_prefix_x_colon_value() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, String foo02}) f() => (foo0^: 0);
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: namedArgument
  foo02
    kind: namedArgument
''');
  }

  Future<void> test_context02_left_prefix_x_comma() async {
    var response = await getTestCodeSuggestions('''
({int foo01, String foo02}) f() => (foo0^,);
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
''');
  }

  Future<void> test_context02_left_prefix_x_right() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, String foo02}) f() => (foo0^);
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
''');
  }

  Future<void> test_context02_left_prefix_x_space_right() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, String foo02}) f() => (foo0^ );
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
''');
  }

  Future<void> test_context02_left_space_x_space_right() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, String foo02}) f() => ( ^ );
''');

    assertResponseText(response, r'''
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
  bar01
    kind: topLevelVariable
''');
  }

  Future<void> test_context02_left_value_comma_space_prefix_x_right() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, String foo02}) f() => (0, foo0^);
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
''');
  }

  Future<void> test_context02_left_value_comma_space_x_right() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, String foo02}) f() => (0, ^);
''');

    assertResponseText(response, r'''
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
  bar01
    kind: topLevelVariable
''');
  }

  Future<void> test_context02_left_x_comma() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, String foo02}) f() => (^,);
''');

    assertResponseText(response, r'''
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
  bar01
    kind: topLevelVariable
''');
  }

  Future<void> test_context02_left_x_right() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, String foo02}) f() => (^);
''');

    assertResponseText(response, r'''
suggestions
  |foo01: |
    kind: namedArgument
  |foo02: |
    kind: namedArgument
  bar01
    kind: topLevelVariable
''');
  }

  Future<void> test_context02_x_colon_value() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, String foo02}) f() => (^: 0);
''');

    assertResponseText(response, r'''
suggestions
  foo01
    kind: namedArgument
  foo02
    kind: namedArgument
''');
  }

  Future<void> test_context03_left_prefix_x_comma_named() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, int foo02, int foo03}) f() => (foo0^, foo02: 0);
''');

    // We don't suggest already specified `foo02`.
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  |foo01: |
    kind: namedArgument
  |foo03: |
    kind: namedArgument
''');
  }

  Future<void> test_context03_left_x_comma_named() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
({int foo01, int foo02, int foo03}) f() => (^, foo02: 0);
''');

    // We don't suggest already specified `foo02`.
    assertResponseText(response, r'''
suggestions
  |foo01: |
    kind: namedArgument
  |foo03: |
    kind: namedArgument
  bar01
    kind: topLevelVariable
''');
  }

  Future<void> test_context03_named_comma_space_prefix_x_right() async {
    var response = await getTestCodeSuggestions('''
({int foo01, int foo02, int foo03}) f() => (foo02: 0, foo0^);
''');

    // We don't suggest already specified `foo02`.
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  |foo01: |
    kind: namedArgument
  |foo03: |
    kind: namedArgument
''');
  }

  Future<void> test_context10_value_comma_space_x_right() async {
    var response = await getTestCodeSuggestions('''
final foo01 = 0;
(int, ) f() => (0, ^);
''');

    // We suggest a positional value anyway.
    assertResponseText(response, r'''
suggestions
  foo01
    kind: topLevelVariable
''');
  }

  Future<void> test_context11_value_comma_prefix_x_space_value() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
(int, {String foo01}) f() => (0, foo^ 0);
''');

    assertResponseText(response, r'''
replacement
  left: 3
suggestions
  foo01: ,
    kind: namedArgument
    selection: 7
''');
  }

  Future<void> test_context11_value_comma_space_prefix_x_right() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
(int, {int foo01}) f() => (0, foo0^);
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  |foo01: |
    kind: namedArgument
''');
  }

  Future<void> test_context11_value_comma_space_prefix_x_space_right() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
(int, {int foo01}) f() => (0, foo0^ );
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  |foo01: |
    kind: namedArgument
''');
  }

  Future<void> test_context11_value_comma_space_x_right() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
(int, {int foo01}) f() => (0, ^);
''');

    // We suggest a positional value anyway.
    assertResponseText(response, r'''
suggestions
  |foo01: |
    kind: namedArgument
  bar01
    kind: topLevelVariable
''');
  }

  Future<void> test_context11_value_comma_space_x_space_right() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
(int, {int foo01}) f() => (0, ^ );
''');

    // We suggest a positional value anyway.
    assertResponseText(response, r'''
suggestions
  |foo01: |
    kind: namedArgument
  bar01
    kind: topLevelVariable
''');
  }

  Future<void> test_context20_left_prefix_x_comma() async {
    var response = await getTestCodeSuggestions('''
final foo01 = 0;
(int, int) f() => (foo0^, );
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: topLevelVariable
''');
  }

  Future<void> test_context20_left_prefix_x_right() async {
    var response = await getTestCodeSuggestions('''
final foo01 = 0;
(int, int) f() => (foo0^);
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: topLevelVariable
''');
  }

  Future<void> test_context20_left_x_comma() async {
    var response = await getTestCodeSuggestions('''
final foo01 = 0;
(int, int) f() => (^, );
''');

    assertResponseText(response, r'''
suggestions
  foo01
    kind: topLevelVariable
''');
  }

  Future<void> test_context20_left_x_right() async {
    var response = await getTestCodeSuggestions('''
final foo01 = 0;
(int, int) f() => (^);
''');

    assertResponseText(response, r'''
suggestions
  foo01
    kind: topLevelVariable
''');
  }

  Future<void> test_context20_named_left_x_comma() async {
    var response = await getTestCodeSuggestions('''
final bar01 = 0;
(int foo01, int foo02) f() => (^, );
''');

    assertResponseText(response, r'''
suggestions
  bar01
    kind: topLevelVariable
''');
  }

  Future<void> test_context20_value_comma_space_prefix_x_right() async {
    var response = await getTestCodeSuggestions('''
final foo01 = 0;
(int, int) f() => (0, foo0^);
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: topLevelVariable
''');
  }

  Future<void> test_context20_value_comma_space_x_right() async {
    var response = await getTestCodeSuggestions('''
final foo01 = 0;
(int, int) f() => (0, ^);
''');

    assertResponseText(response, r'''
suggestions
  foo01
    kind: topLevelVariable
''');
  }
}
