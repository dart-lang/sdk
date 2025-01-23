// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';

import '../lsp/request_helpers_mixin.dart';
import '../lsp/server_abstract.dart';
import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'shared_test_interface.dart';

/// Shared edit argument tests that are used by both LSP + Legacy server
/// tests.
mixin SharedEditArgumentTests
    on
        SharedTestInterface,
        LspRequestHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
  late TestCode code;

  @override
  Future<void> setUp() async {
    await super.setUp();
    setApplyEditSupport();
  }

  test_comma_addArg_addsIfExists() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '(x: 1,)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2,)',
    );
  }

  test_comma_addArg_doesNotAddIfNotExists() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2)',
    );
  }

  test_comma_editArg_doesNotAddIfNotExists() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '(x: 1, y: 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2)',
    );
  }

  test_comma_editArg_retainsIfExists() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '(x: 1, y: 1,)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2,)',
    );
  }

  test_named_addAfterNamed() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2)',
    );
  }

  test_named_addAfterNamed_afterChildNotAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y, Widget? child })',
      originalArgs: '(child: null, x: 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(child: null, x: 1, y: 2)',
    );
  }

  test_named_addAfterNamed_beforeChildAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y, Widget? child })',
      originalArgs: '(x: 1, child: null)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2, child: null)',
    );
  }

  test_named_addAfterNamed_beforeChildrenAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y, List<Widget>? children })',
      originalArgs: '(x: 1, children: [])',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2, children: [])',
    );
  }

  test_named_addAfterPositional() async {
    await _expectSimpleArgumentEdit(
      params: '(int? x, { int? y })',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(1, y: 2)',
    );
  }

  test_named_addAfterPositional_afterChildNotAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '(int? x, { int? y, Widget? child })',
      originalArgs: '(child: null, 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(child: null, 1, y: 2)',
    );
  }

  test_named_addAfterPositional_beforeChildAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '(int? x, { int? y, Widget? child })',
      originalArgs: '(1, child: null)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(1, y: 2, child: null)',
    );
  }

  test_named_addAfterPositional_beforeChildrenAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '(int? x, { int? y, List<Widget>? children })',
      originalArgs: '(1, children: [])',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(1, y: 2, children: [])',
    );
  }

  test_optionalPositional_addAfterPositional() async {
    await _expectSimpleArgumentEdit(
      params: '([int? x, int? y])',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(1, 2)',
    );
  }

  test_optionalPositional_notNext_afterPositional() async {
    await _expectFailedEdit(
      params: '([int? x, int y = 10, int? z])',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'z', newValue: 2),
      message:
          "Parameter 'z' is not editable: "
          "A value for the 3rd parameter can't be added until a value for all preceding positional parameters have been added.",
    );
  }

  test_optionalPositional_notNext_solo() async {
    await _expectFailedEdit(
      params: '([int? x = 10, int? y])',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      message:
          "Parameter 'y' is not editable: "
          "A value for the 2nd parameter can't be added until a value for all preceding positional parameters have been added.",
    );
  }

  test_requiredPositional_addAfterNamed() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectSimpleArgumentEdit(
      params: '(int? x, { int? y })',
      originalArgs: '(y: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(y: 1, 2)',
    );
  }

  test_requiredPositional_addAfterPositional() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectSimpleArgumentEdit(
      params: '(int? x, int? y)',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(1, 2)',
    );
  }

  test_requiredPositional_notNext_afterPositional() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectFailedEdit(
      params: '(int? x, int? y, int? z)',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'z', newValue: 2),
      message:
          "Parameter 'z' is not editable: "
          "A value for the 3rd parameter can't be added until a value for all preceding positional parameters have been added.",
    );
  }

  test_requiredPositional_notNext_noExisting() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectFailedEdit(
      params: '(int? x, int? y)',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      message:
          "Parameter 'y' is not editable: "
          "A value for the 2nd parameter can't be added until a value for all preceding positional parameters have been added.",
    );
  }

  test_requiredPositional_notNext_onlyNamed() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectFailedEdit(
      params: '(int? x, int? y, { int? z })',
      originalArgs: '(z: 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      message:
          "Parameter 'y' is not editable: "
          "A value for the 2nd parameter can't be added until a value for all preceding positional parameters have been added.",
    );
  }

  test_soloArgument_addNamed() async {
    await _expectSimpleArgumentEdit(
      params: '({int? x })',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  test_soloArgument_addOptionalPositional() async {
    await _expectSimpleArgumentEdit(
      params: '([int? x])',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(2)',
    );
  }

  test_soloArgument_addRequiredPositional() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectSimpleArgumentEdit(
      params: '(int? x)',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(2)',
    );
  }

  test_soloArgument_editNamed() async {
    await _expectSimpleArgumentEdit(
      params: '({int? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  test_soloArgument_editOptionalPositional() async {
    await _expectSimpleArgumentEdit(
      params: '([int? x])',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(2)',
    );
  }

  test_soloArgument_editRequiredPositional() async {
    await _expectSimpleArgumentEdit(
      params: '(int? x)',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(2)',
    );
  }

  test_type_bool_invalidType() async {
    await _expectFailedEdit(
      params: '({ bool? x })',
      originalArgs: '(x: true)',
      edit: ArgumentEdit(name: 'x', newValue: 'invalid'),
      message: 'Value for parameter "x" should be bool? but was String',
    );
  }

  test_type_bool_null_allowed() async {
    await _expectSimpleArgumentEdit(
      params: '({ bool? x })',
      originalArgs: '(x: true)',
      edit: ArgumentEdit(name: 'x'),
      expectedArgs: '(x: null)',
    );
  }

  test_type_bool_null_notAllowed() async {
    await _expectFailedEdit(
      params: '({ required bool x })',
      originalArgs: '(x: true)',
      edit: ArgumentEdit(name: 'x'),
      message: 'Value for non-nullable parameter "x" cannot be null',
    );
  }

  test_type_bool_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ bool? x })',
      originalArgs: '(x: true)',
      edit: ArgumentEdit(name: 'x', newValue: false),
      expectedArgs: '(x: false)',
    );
  }

  test_type_bool_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ bool? x })',
      originalArgs: '(x: 1 == 1)',
      edit: ArgumentEdit(name: 'x', newValue: false),
      expectedArgs: '(x: false)',
    );
  }

  test_type_double_invalidType() async {
    await _expectFailedEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1.1)',
      edit: ArgumentEdit(name: 'x', newValue: 'invalid'),
      message: 'Value for parameter "x" should be double? but was String',
    );
  }

  test_type_double_null_allowed() async {
    await _expectSimpleArgumentEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1.0)',
      edit: ArgumentEdit(name: 'x'),
      expectedArgs: '(x: null)',
    );
  }

  test_type_double_null_notAllowed() async {
    await _expectFailedEdit(
      params: '({ required double x })',
      originalArgs: '(x: 1.0)',
      edit: ArgumentEdit(name: 'x'),
      message: 'Value for non-nullable parameter "x" cannot be null',
    );
  }

  test_type_double_replaceInt() async {
    await _expectSimpleArgumentEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2.2),
      expectedArgs: '(x: 2.2)',
    );
  }

  test_type_double_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1.1)',
      edit: ArgumentEdit(name: 'x', newValue: 2.2),
      expectedArgs: '(x: 2.2)',
    );
  }

  test_type_double_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1.1 + 0.1)',
      edit: ArgumentEdit(name: 'x', newValue: 2.2),
      expectedArgs: '(x: 2.2)',
    );
  }

  test_type_double_replaceWithInt() async {
    await _expectSimpleArgumentEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1.1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  test_type_enum_invalidType() async {
    await _expectFailedEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ E? x })',
      originalArgs: '(x: E.one)',
      edit: ArgumentEdit(name: 'x', newValue: 'invalid'),
      message:
          'Value for parameter "x" should be one of "E.one", "E.two" but was "invalid"',
    );
  }

  test_type_enum_null_allowed() async {
    await _expectSimpleArgumentEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ E? x })',
      originalArgs: '(x: E.one)',
      edit: ArgumentEdit(name: 'x'),
      expectedArgs: '(x: null)',
    );
  }

  test_type_enum_null_notAllowed() async {
    await _expectFailedEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ required E x })',
      originalArgs: '(x: E.one)',
      edit: ArgumentEdit(name: 'x'),
      message: 'Value for non-nullable parameter "x" cannot be null',
    );
  }

  test_type_enum_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ E? x })',
      originalArgs: '(x: E.one)',
      edit: ArgumentEdit(name: 'x', newValue: 'E.two'),
      expectedArgs: '(x: E.two)',
    );
  }

  test_type_enum_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      additionalCode: '''
enum E { one, two }
const myConst = E.one;
''',
      params: '({ E? x })',
      originalArgs: '(x: myConst)',
      edit: ArgumentEdit(name: 'x', newValue: 'E.two'),
      expectedArgs: '(x: E.two)',
    );
  }

  test_type_int_invalidType() async {
    await _expectFailedEdit(
      params: '({ int? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 'invalid'),
      message: 'Value for parameter "x" should be int? but was String',
    );
  }

  test_type_int_null_allowed() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x'),
      expectedArgs: '(x: null)',
    );
  }

  test_type_int_null_notAllowed() async {
    await _expectFailedEdit(
      params: '({ required int x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x'),
      message: 'Value for non-nullable parameter "x" cannot be null',
    );
  }

  test_type_int_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  test_type_int_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x })',
      originalArgs: '(x: 1 + 0)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  test_type_string_containsBackslashes() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: r'a\b'),
      expectedArgs: r"(x: 'a\\b')",
    );
  }

  test_type_string_containsBothQuotes() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: '''a'b"c'''),
      expectedArgs: r'''(x: 'a\'b"c')''',
    );
  }

  test_type_string_containsSingleQuotes() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: "a'b"),
      expectedArgs: r'''(x: 'a\'b')''',
    );
  }

  test_type_string_invalidType() async {
    await _expectFailedEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: 123),
      message: 'Value for parameter "x" should be String? but was int',
    );
  }

  test_type_string_multiline() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: 'a\nb'),
      expectedArgs: r'''(x: 'a\nb')''',
    );
  }

  test_type_string_null_allowed() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x'),
      expectedArgs: '(x: null)',
    );
  }

  test_type_string_null_notAllowed() async {
    await _expectFailedEdit(
      params: '({ required String x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x'),
      message: 'Value for non-nullable parameter "x" cannot be null',
    );
  }

  test_type_string_quotes_dollar_escapedNonRaw() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: '')",
      edit: ArgumentEdit(name: 'x', newValue: r'$'),
      expectedArgs: r"(x: '\$')",
    );
  }

  test_type_string_quotes_dollar_notEscapedRaw() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: r'')",
      edit: ArgumentEdit(name: 'x', newValue: r'$'),
      expectedArgs: r"(x: r'$')",
    );
  }

  test_type_string_quotes_usesExistingDouble() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: '(x: "a")',
      edit: ArgumentEdit(name: 'x', newValue: 'a'),
      expectedArgs: '(x: "a")',
    );
  }

  test_type_string_quotes_usesExistingSingle() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: 'a'),
      expectedArgs: "(x: 'a')",
    );
  }

  test_type_string_quotes_usesExistingTripleDouble() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: '(x: """a""")',
      edit: ArgumentEdit(name: 'x', newValue: 'a'),
      expectedArgs: '(x: """a""")',
    );
  }

  test_type_string_quotes_usesExistingTripleSingle() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: '''a''')",
      edit: ArgumentEdit(name: 'x', newValue: 'a'),
      expectedArgs: "(x: '''a''')",
    );
  }

  test_type_string_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: 'b'),
      expectedArgs: "(x: 'b')",
    );
  }

  test_type_string_replaceLiteral_raw() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: r'a')",
      edit: ArgumentEdit(name: 'x', newValue: 'b'),
      expectedArgs: "(x: r'b')",
    );
  }

  test_type_string_replaceLiteral_tripleQuoted() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: '''a''')",
      edit: ArgumentEdit(name: 'x', newValue: 'b'),
      expectedArgs: "(x: '''b''')",
    );
  }

  test_type_string_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a' + 'a')",
      edit: ArgumentEdit(name: 'x', newValue: 'b'),
      expectedArgs: "(x: 'b')",
    );
  }

  test_unsupported_noApplyEditSupport() async {
    setApplyEditSupport(false);

    await _expectFailedEdit(
      params: '({ required String x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x'),
      message: 'The connected editor does not support applying edits',
    );
  }

  /// Initializes the server with [content] and tries to apply the argument
  /// [edit] at the marked location. Verifies the changes made match
  /// [expectedContent].
  Future<void> _expectArgumentEdit(
    String content,
    ArgumentEdit edit,
    String expectedContent, {
    bool open = true,
  }) async {
    code = TestCode.parse(content);
    createFile(testFilePath, code.code);
    await initializeServer();
    if (open) {
      await openFile(testFileUri, code.code);
    }
    await currentAnalysis;
    var verifier = await executeForEdits(
      () => editArgument(testFileUri, code.position.position, edit),
    );

    verifier.verifyFiles(expectedContent);
  }

  /// Initializes the server and verifies a simple argument edit fails with
  /// a given message.
  Future<void> _expectFailedEdit({
    required String params,
    required String originalArgs,
    required ArgumentEdit edit,
    required String message,
    String? additionalCode,
  }) async {
    additionalCode ??= '';
    var content = '''
import 'package:flutter/widgets.dart';

$additionalCode

class MyWidget extends StatelessWidget {
  const MyWidget$params;

  @override
  Widget build(BuildContext context) => MyW^idget$originalArgs;
}
''';

    code = TestCode.parse(content);
    createFile(testFilePath, code.code);
    await initializeServer();
    await currentAnalysis;

    await expectLater(
      editArgument(testFileUri, code.position.position, edit),
      throwsA(isResponseError(ErrorCodes.RequestFailed, message: message)),
    );
  }

  /// Initializes the server and verifies a simple argument edit.
  Future<void> _expectSimpleArgumentEdit({
    required String params,
    required String originalArgs,
    required ArgumentEdit edit,
    required String expectedArgs,
    String? additionalCode,
  }) async {
    additionalCode ??= '';
    var content = '''
import 'package:flutter/widgets.dart';

$additionalCode

class MyWidget extends StatelessWidget {
  const MyWidget$params;

  @override
  Widget build(BuildContext context) => MyW^idget$originalArgs;
}
''';
    var expectedContent = '''
>>>>>>>>>> lib/test.dart
import 'package:flutter/widgets.dart';

$additionalCode

class MyWidget extends StatelessWidget {
  const MyWidget$params;

  @override
  Widget build(BuildContext context) => MyWidget$expectedArgs;
}
''';

    await _expectArgumentEdit(content, edit, expectedContent);
  }
}
