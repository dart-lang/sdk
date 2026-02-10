// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
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
    setDocumentChangesSupport();
  }

  Future<void> test_comma_addArg_addsIfExists() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '(x: 1,)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2,)',
    );
  }

  Future<void> test_comma_addArg_doesNotAddIfNotExists() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2)',
    );
  }

  Future<void> test_comma_editArg_doesNotAddIfNotExists() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '(x: 1, y: 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2)',
    );
  }

  Future<void> test_comma_editArg_retainsIfExists() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '(x: 1, y: 1,)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2,)',
    );
  }

  Future<void> test_documentChanges_supported() async {
    // Ensure documentChanges are supported. The verification in
    // LspChangeVerifier will verify the resulting edits match the capabilities.
    setDocumentChangesSupport();
    await _expectSimpleArgumentEdit(
      params: '({ int? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  Future<void> test_documentChanges_unsupported() async {
    // documentChanges are NOT supported. The verification in
    // LspChangeVerifier will verify the resulting edits match the capabilities.
    setDocumentChangesSupport(false);
    await _expectSimpleArgumentEdit(
      params: '({ int? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  Future<void> test_format_multiline_insert_between() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y, int? children })',
      originalArgs: '''\n
      (
        x: 1,
        children: 3,
      )''',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '''\n
      (
        x: 1,
        y: 2,
        children: 3,
      )''',
    );
  }

  Future<void> test_format_multiline_insert_last() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '''\n
      (
        x: 1,
      )''',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '''\n
      (
        x: 1,
        y: 2,
      )''',
    );
  }

  Future<void> test_format_multiline_insert_solo() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x })',
      originalArgs: '''\n
      (
      )''',
      edit: ArgumentEdit(name: 'x', newValue: 1),
      expectedArgs: '''\n
      (
        x: 1,
      )''',
    );
  }

  Future<void> test_named_addAfterNamed() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2)',
    );
  }

  Future<void> test_named_addAfterNamed_afterChildNotAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y, Widget? child })',
      originalArgs: '(child: null, x: 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(child: null, x: 1, y: 2)',
    );
  }

  Future<void> test_named_addAfterNamed_beforeChild_noOthers() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? y, Widget? child })',
      originalArgs: '(child: null)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(y: 2, child: null)',
    );
  }

  Future<void> test_named_addAfterNamed_beforeChild_noOthers_multiline() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? y, Widget? child })',
      originalArgs: '''\n
      (
        child: null
      )''',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '''\n
      (
        y: 2,
        child: null
      )''',
    );
  }

  Future<void> test_named_addAfterNamed_beforeChildAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y, Widget? child })',
      originalArgs: '(x: 1, child: null)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2, child: null)',
    );
  }

  Future<void> test_named_addAfterNamed_beforeChildren_noOthers() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? y, List<Widget>? children })',
      originalArgs: '(children: [])',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(y: 2, children: [])',
    );
  }

  Future<void>
  test_named_addAfterNamed_beforeChildren_noOthers_multiline() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? y, List<Widget>? children })',
      originalArgs: '''\n
      (
        children: []
      )''',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '''\n
      (
        y: 2,
        children: []
      )''',
    );
  }

  Future<void> test_named_addAfterNamed_beforeChildrenAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x, int? y, List<Widget>? children })',
      originalArgs: '(x: 1, children: [])',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(x: 1, y: 2, children: [])',
    );
  }

  Future<void> test_named_addAfterPositional() async {
    await _expectSimpleArgumentEdit(
      params: '(int? x, { int? y })',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(1, y: 2)',
    );
  }

  Future<void> test_named_addAfterPositional_afterChildNotAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '(int? x, { int? y, Widget? child })',
      originalArgs: '(child: null, 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(child: null, 1, y: 2)',
    );
  }

  Future<void> test_named_addAfterPositional_beforeChildAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '(int? x, { int? y, Widget? child })',
      originalArgs: '(1, child: null)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(1, y: 2, child: null)',
    );
  }

  Future<void> test_named_addAfterPositional_beforeChildrenAtEnd() async {
    await _expectSimpleArgumentEdit(
      params: '(int? x, { int? y, List<Widget>? children })',
      originalArgs: '(1, children: [])',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(1, y: 2, children: [])',
    );
  }

  Future<void> test_named_privateInitializingFormal() async {
    await _expectSimpleArgumentEdit(
      params: '({this._x})',
      additionalWidgetCode: 'final int? _x;',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  Future<void> test_optionalPositional_addAfterPositional() async {
    await _expectSimpleArgumentEdit(
      params: '([int? x, int? y])',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(1, 2)',
    );
  }

  Future<void> test_optionalPositional_notNext_afterPositional() async {
    await _expectFailedEdit(
      params: '([int? x, int y = 10, int? z])',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'z', newValue: 2),
      errorCode: ServerErrorCodes.editArgumentInvalidParameter,
      message:
          "The parameter 'z' is not editable because "
          "a value for the 3rd parameter can't be added until a value for all preceding positional parameters have been added.",
    );
  }

  Future<void> test_optionalPositional_notNext_solo() async {
    await _expectFailedEdit(
      params: '([int? x = 10, int? y])',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      errorCode: ServerErrorCodes.editArgumentInvalidParameter,
      message:
          "The parameter 'y' is not editable because "
          "a value for the 2nd parameter can't be added until a value for all preceding positional parameters have been added.",
    );
  }

  Future<void> test_requiredPositional_addAfterNamed() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectSimpleArgumentEdit(
      params: '(int? x, { int? y })',
      originalArgs: '(y: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(y: 1, 2)',
    );
  }

  Future<void> test_requiredPositional_addAfterPositional() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectSimpleArgumentEdit(
      params: '(int? x, int? y)',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      expectedArgs: '(1, 2)',
    );
  }

  Future<void> test_requiredPositional_notNext_afterPositional() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectFailedEdit(
      params: '(int? x, int? y, int? z)',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'z', newValue: 2),
      errorCode: ServerErrorCodes.editArgumentInvalidParameter,
      message:
          "The parameter 'z' is not editable because "
          "a value for the 3rd parameter can't be added until a value for all preceding positional parameters have been added.",
    );
  }

  Future<void> test_requiredPositional_notNext_noExisting() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectFailedEdit(
      params: '(int? x, int? y)',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      errorCode: ServerErrorCodes.editArgumentInvalidParameter,
      message:
          "The parameter 'y' is not editable because "
          "a value for the 2nd parameter can't be added until a value for all preceding positional parameters have been added.",
    );
  }

  Future<void> test_requiredPositional_notNext_onlyNamed() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectFailedEdit(
      params: '(int? x, int? y, { int? z })',
      originalArgs: '(z: 1)',
      edit: ArgumentEdit(name: 'y', newValue: 2),
      errorCode: ServerErrorCodes.editArgumentInvalidParameter,
      message:
          "The parameter 'y' is not editable because "
          "a value for the 2nd parameter can't be added until a value for all preceding positional parameters have been added.",
    );
  }

  Future<void> test_soloArgument_addNamed() async {
    await _expectSimpleArgumentEdit(
      params: '({int? x })',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  Future<void> test_soloArgument_addOptionalPositional() async {
    await _expectSimpleArgumentEdit(
      params: '([int? x])',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(2)',
    );
  }

  Future<void> test_soloArgument_addRequiredPositional() async {
    failTestOnErrorDiagnostic = false; // Tests with missing positional.
    await _expectSimpleArgumentEdit(
      params: '(int? x)',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(2)',
    );
  }

  Future<void> test_soloArgument_editNamed() async {
    await _expectSimpleArgumentEdit(
      params: '({int? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  Future<void> test_soloArgument_editOptionalPositional() async {
    await _expectSimpleArgumentEdit(
      params: '([int? x])',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(2)',
    );
  }

  Future<void> test_soloArgument_editRequiredPositional() async {
    await _expectSimpleArgumentEdit(
      params: '(int? x)',
      originalArgs: '(1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(2)',
    );
  }

  Future<void> test_type_bool_invalidType() async {
    await _expectFailedEdit(
      params: '({ bool? x })',
      originalArgs: '(x: true)',
      edit: ArgumentEdit(name: 'x', newValue: 'invalid'),
      errorCode: ServerErrorCodes.editArgumentInvalidValue,
      message: "The value for the parameter 'x' should be bool? but was String",
    );
  }

  Future<void> test_type_bool_null_allowed() async {
    await _expectSimpleArgumentEdit(
      params: '({ bool? x })',
      originalArgs: '(x: true)',
      edit: ArgumentEdit(name: 'x'),
      expectedArgs: '(x: null)',
    );
  }

  Future<void> test_type_bool_null_notAllowed() async {
    await _expectFailedEdit(
      params: '({ required bool x })',
      originalArgs: '(x: true)',
      edit: ArgumentEdit(name: 'x'),
      errorCode: ServerErrorCodes.editArgumentInvalidValue,
      message: "The value for the parameter 'x' can't be null",
    );
  }

  Future<void> test_type_bool_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ bool? x })',
      originalArgs: '(x: true)',
      edit: ArgumentEdit(name: 'x', newValue: false),
      expectedArgs: '(x: false)',
    );
  }

  Future<void> test_type_bool_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ bool? x })',
      originalArgs: '(x: 1 == 1)',
      edit: ArgumentEdit(name: 'x', newValue: false),
      expectedArgs: '(x: false)',
    );
  }

  Future<void> test_type_double_invalidType() async {
    await _expectFailedEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1.1)',
      edit: ArgumentEdit(name: 'x', newValue: 'invalid'),
      errorCode: ServerErrorCodes.editArgumentInvalidValue,
      message:
          "The value for the parameter 'x' should be double? but was String",
    );
  }

  Future<void> test_type_double_null_allowed() async {
    await _expectSimpleArgumentEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1.0)',
      edit: ArgumentEdit(name: 'x'),
      expectedArgs: '(x: null)',
    );
  }

  Future<void> test_type_double_null_notAllowed() async {
    await _expectFailedEdit(
      params: '({ required double x })',
      originalArgs: '(x: 1.0)',
      edit: ArgumentEdit(name: 'x'),
      errorCode: ServerErrorCodes.editArgumentInvalidValue,
      message: "The value for the parameter 'x' can't be null",
    );
  }

  Future<void> test_type_double_replaceInt() async {
    await _expectSimpleArgumentEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2.2),
      expectedArgs: '(x: 2.2)',
    );
  }

  Future<void> test_type_double_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1.1)',
      edit: ArgumentEdit(name: 'x', newValue: 2.2),
      expectedArgs: '(x: 2.2)',
    );
  }

  Future<void> test_type_double_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1.1 + 0.1)',
      edit: ArgumentEdit(name: 'x', newValue: 2.2),
      expectedArgs: '(x: 2.2)',
    );
  }

  Future<void> test_type_double_replaceWithInt() async {
    await _expectSimpleArgumentEdit(
      params: '({ double? x })',
      originalArgs: '(x: 1.1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  Future<void> test_type_enum_dotshorthand_addNew() async {
    await _expectSimpleArgumentEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ E? x })',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'x', newValue: 'E.two'),
      expectedArgs: '(x: .two)',
    );
  }

  Future<void> test_type_enum_dotshorthand_disabled_addNew() async {
    await _expectSimpleArgumentEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ E? x })',
      originalArgs: '()',
      edit: ArgumentEdit(name: 'x', newValue: 'E.two'),
      expectedArgs: '(x: E.two)',
      fileComment: '// @dart = 3.8',
    );
  }

  Future<void> test_type_enum_dotshorthand_disabled_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ E? x })',
      originalArgs: '(x: E.one)',
      edit: ArgumentEdit(name: 'x', newValue: 'E.two'),
      expectedArgs: '(x: E.two)',
      fileComment: '// @dart = 3.8',
    );
  }

  Future<void> test_type_enum_dotshorthand_disabled_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      additionalCode: '''
enum E { one, two }
const E myConst = E.one;
''',
      params: '({ E? x })',
      originalArgs: '(x: myConst)',
      edit: ArgumentEdit(name: 'x', newValue: 'E.two'),
      expectedArgs: '(x: E.two)',
      fileComment: '// @dart = 3.8',
    );
  }

  Future<void> test_type_enum_dotshorthand_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ E? x })',
      originalArgs: '(x: .one)',
      edit: ArgumentEdit(name: 'x', newValue: 'E.two'),
      expectedArgs: '(x: .two)',
    );
  }

  Future<void> test_type_enum_dotshorthand_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      additionalCode: '''
enum E { one, two }
const E myConst = .one;
''',
      params: '({ E? x })',
      originalArgs: '(x: myConst)',
      edit: ArgumentEdit(name: 'x', newValue: 'E.two'),
      expectedArgs: '(x: .two)',
    );
  }

  Future<void> test_type_enum_invalidType() async {
    await _expectFailedEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ E? x })',
      originalArgs: '(x: E.one)',
      edit: ArgumentEdit(name: 'x', newValue: 'invalid'),
      errorCode: ServerErrorCodes.editArgumentInvalidValue,
      message:
          "The value for the parameter 'x' should be one of 'E.one', 'E.two' but was 'invalid'",
    );
  }

  Future<void> test_type_enum_null_allowed() async {
    await _expectSimpleArgumentEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ E? x })',
      originalArgs: '(x: E.one)',
      edit: ArgumentEdit(name: 'x'),
      expectedArgs: '(x: null)',
    );
  }

  Future<void> test_type_enum_null_notAllowed() async {
    await _expectFailedEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ required E x })',
      originalArgs: '(x: E.one)',
      edit: ArgumentEdit(name: 'x'),
      errorCode: ServerErrorCodes.editArgumentInvalidValue,
      message: "The value for the parameter 'x' can't be null",
    );
  }

  Future<void> test_type_enum_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      additionalCode: 'enum E { one, two }',
      params: '({ E? x })',
      originalArgs: '(x: E.one)',
      edit: ArgumentEdit(name: 'x', newValue: 'E.two'),
      expectedArgs: '(x: E.two)',
    );
  }

  Future<void> test_type_enum_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      additionalCode: '''
enum E { one, two }
const myConst = E.one;
''',
      params: '({ E? x })',
      originalArgs: '(x: myConst)',
      edit: ArgumentEdit(name: 'x', newValue: 'E.two'),
      expectedArgs: '(x: .two)',
    );
  }

  Future<void> test_type_int_invalidType() async {
    await _expectFailedEdit(
      params: '({ int? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 'invalid'),
      errorCode: ServerErrorCodes.editArgumentInvalidValue,
      message: "The value for the parameter 'x' should be int? but was String",
    );
  }

  Future<void> test_type_int_null_allowed() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x'),
      expectedArgs: '(x: null)',
    );
  }

  Future<void> test_type_int_null_notAllowed() async {
    await _expectFailedEdit(
      params: '({ required int x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x'),
      errorCode: ServerErrorCodes.editArgumentInvalidValue,
      message: "The value for the parameter 'x' can't be null",
    );
  }

  Future<void> test_type_int_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x })',
      originalArgs: '(x: 1)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  Future<void> test_type_int_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ int? x })',
      originalArgs: '(x: 1 + 0)',
      edit: ArgumentEdit(name: 'x', newValue: 2),
      expectedArgs: '(x: 2)',
    );
  }

  Future<void> test_type_string_containsBackslashes() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: r'a\b'),
      expectedArgs: r"(x: 'a\\b')",
    );
  }

  Future<void> test_type_string_containsBothQuotes() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: '''a'b"c'''),
      expectedArgs: r'''(x: 'a\'b"c')''',
    );
  }

  Future<void> test_type_string_containsSingleQuotes() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: "a'b"),
      expectedArgs: r'''(x: 'a\'b')''',
    );
  }

  Future<void> test_type_string_invalidType() async {
    await _expectFailedEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: 123),
      errorCode: ServerErrorCodes.editArgumentInvalidValue,
      message: "The value for the parameter 'x' should be String? but was int",
    );
  }

  Future<void> test_type_string_multiline() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: 'a\nb'),
      expectedArgs: r'''(x: 'a\nb')''',
    );
  }

  Future<void> test_type_string_null_allowed() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x'),
      expectedArgs: '(x: null)',
    );
  }

  Future<void> test_type_string_null_notAllowed() async {
    await _expectFailedEdit(
      params: '({ required String x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x'),
      errorCode: ServerErrorCodes.editArgumentInvalidValue,
      message: "The value for the parameter 'x' can't be null",
    );
  }

  Future<void> test_type_string_quotes_dollar_escapedNonRaw() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: '')",
      edit: ArgumentEdit(name: 'x', newValue: r'$'),
      expectedArgs: r"(x: '\$')",
    );
  }

  Future<void> test_type_string_quotes_dollar_notEscapedRaw() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: r'')",
      edit: ArgumentEdit(name: 'x', newValue: r'$'),
      expectedArgs: r"(x: r'$')",
    );
  }

  Future<void> test_type_string_quotes_usesExistingDouble() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: '(x: "a")',
      edit: ArgumentEdit(name: 'x', newValue: 'a'),
      expectedArgs: '(x: "a")',
    );
  }

  Future<void> test_type_string_quotes_usesExistingSingle() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: 'a'),
      expectedArgs: "(x: 'a')",
    );
  }

  Future<void> test_type_string_quotes_usesExistingTripleDouble() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: '(x: """a""")',
      edit: ArgumentEdit(name: 'x', newValue: 'a'),
      expectedArgs: '(x: """a""")',
    );
  }

  Future<void> test_type_string_quotes_usesExistingTripleSingle() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: '''a''')",
      edit: ArgumentEdit(name: 'x', newValue: 'a'),
      expectedArgs: "(x: '''a''')",
    );
  }

  Future<void> test_type_string_replaceLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x', newValue: 'b'),
      expectedArgs: "(x: 'b')",
    );
  }

  Future<void> test_type_string_replaceLiteral_raw() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: r'a')",
      edit: ArgumentEdit(name: 'x', newValue: 'b'),
      expectedArgs: "(x: r'b')",
    );
  }

  Future<void> test_type_string_replaceLiteral_tripleQuoted() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: '''a''')",
      edit: ArgumentEdit(name: 'x', newValue: 'b'),
      expectedArgs: "(x: '''b''')",
    );
  }

  Future<void> test_type_string_replaceNonLiteral() async {
    await _expectSimpleArgumentEdit(
      params: '({ String? x })',
      originalArgs: "(x: 'a' + 'a')",
      edit: ArgumentEdit(name: 'x', newValue: 'b'),
      expectedArgs: "(x: 'b')",
    );
  }

  Future<void> test_unsupported_noApplyEditSupport() async {
    setApplyEditSupport(false);

    await _expectFailedEdit(
      params: '({ required String x })',
      originalArgs: "(x: 'a')",
      edit: ArgumentEdit(name: 'x'),
      errorCode: ServerErrorCodes.editsUnsupportedByEditor,
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
    content = normalizeNewlinesForPlatform(content);
    expectedContent = normalizeNewlinesForPlatform(expectedContent);

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
    required ErrorCodes errorCode,
    required String message,
    String? additionalCode,
  }) async {
    additionalCode ??= '';
    var content =
        '''
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
      throwsA(isResponseError(errorCode, message: message)),
    );
  }

  /// Initializes the server and verifies a simple argument edit.
  Future<void> _expectSimpleArgumentEdit({
    required String params,
    required String originalArgs,
    required ArgumentEdit edit,
    required String expectedArgs,
    String? additionalCode = '',
    String? additionalWidgetCode = '',
    String? fileComment = '',
  }) async {
    var content =
        '''
$fileComment
import 'package:flutter/widgets.dart';

$additionalCode

class MyWidget extends StatelessWidget {
  const MyWidget$params;

  @override
  Widget build(BuildContext context) => MyW^idget$originalArgs;

  $additionalWidgetCode
}
''';
    var expectedContent =
        '''
>>>>>>>>>> lib/test.dart
$fileComment
import 'package:flutter/widgets.dart';

$additionalCode

class MyWidget extends StatelessWidget {
  const MyWidget$params;

  @override
  Widget build(BuildContext context) => MyWidget$expectedArgs;

  $additionalWidgetCode
}
''';

    await _expectArgumentEdit(content, edit, expectedContent);
  }
}
