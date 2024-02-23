// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show
        Code,
        Message,
        codeAssertAsExpression,
        codeSetOrMapLiteralTooManyTypeArguments;
import 'package:analyzer/dart/ast/token.dart' show Token;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';

/// An error reporter that knows how to convert a Fasta error into an analyzer
/// error.
class FastaErrorReporter {
  /// The underlying error reporter to which errors are reported.
  final ErrorReporter? errorReporter;

  /// Initialize a newly created error reporter to report errors to the given
  /// [errorReporter].
  FastaErrorReporter(this.errorReporter);

  void reportByCode(
      String? analyzerCode, int offset, int length, Message message) {
    Map<String, dynamic> arguments = message.arguments;

    String lexeme() => (arguments['lexeme'] as Token).lexeme;

    switch (analyzerCode) {
      case "ASYNC_FOR_IN_WRONG_CONTEXT":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT,
        );
        return;
      case "ASYNC_KEYWORD_USED_AS_IDENTIFIER":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER,
        );
        return;
      case "AWAIT_IN_WRONG_CONTEXT":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT,
        );
        return;
      case "BUILT_IN_IDENTIFIER_AS_TYPE":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE,
          arguments: [lexeme()],
        );
        return;
      case "CONCRETE_CLASS_WITH_ABSTRACT_MEMBER":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER,
        );
        return;
      case "CONST_CONSTRUCTOR_WITH_BODY":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY,
        );
        return;
      case "CONST_NOT_INITIALIZED":
        var name = arguments['name'] as String;
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.CONST_NOT_INITIALIZED,
          arguments: [name],
        );
        return;
      case "DEFAULT_VALUE_IN_FUNCTION_TYPE":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE,
        );
        return;
      case "LABEL_UNDEFINED":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.LABEL_UNDEFINED,
          arguments: [arguments['name'] as Object],
        );
        return;
      case "EMPTY_ENUM_BODY":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.EMPTY_ENUM_BODY,
        );
        return;
      case "EXPECTED_CLASS_MEMBER":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.EXPECTED_CLASS_MEMBER,
        );
        return;
      case "EXPECTED_EXECUTABLE":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.EXPECTED_EXECUTABLE,
        );
        return;
      case "EXPECTED_STRING_LITERAL":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.EXPECTED_STRING_LITERAL,
        );
        return;
      case "EXPECTED_TOKEN":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.EXPECTED_TOKEN,
          arguments: [arguments['string'] as Object],
        );
        return;
      case "EXPECTED_TYPE_NAME":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.EXPECTED_TYPE_NAME,
        );
        return;
      case "FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode:
              CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR,
        );
        return;
      case "FINAL_NOT_INITIALIZED":
        var name = arguments['name'] as String;
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.FINAL_NOT_INITIALIZED,
          arguments: [name],
        );
        return;
      case "FINAL_NOT_INITIALIZED_CONSTRUCTOR_1":
        var name = arguments['name'] as String;
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1,
          arguments: [name],
        );
        return;
      case "GETTER_WITH_PARAMETERS":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.GETTER_WITH_PARAMETERS,
        );
        return;
      case "ILLEGAL_CHARACTER":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ScannerErrorCode.ILLEGAL_CHARACTER,
        );
        return;
      case "INVALID_ASSIGNMENT":
        var type1 = arguments['type'] as Object;
        var type2 = arguments['type2'] as Object;
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_ASSIGNMENT,
          arguments: [type1, type2],
        );
        return;
      case "INVALID_INLINE_FUNCTION_TYPE":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_INLINE_FUNCTION_TYPE,
        );
        return;
      case "INVALID_LITERAL_IN_CONFIGURATION":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.INVALID_LITERAL_IN_CONFIGURATION,
        );
        return;
      case "IMPORT_OF_NON_LIBRARY":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY,
        );
        return;
      case "INVALID_CAST_FUNCTION":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_CAST_FUNCTION,
        );
        return;
      case "INVALID_CAST_FUNCTION_EXPR":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_CAST_FUNCTION_EXPR,
        );
        return;
      case "INVALID_CAST_LITERAL_LIST":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST,
        );
        return;
      case "INVALID_CAST_LITERAL_MAP":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP,
        );
        return;
      case "INVALID_CAST_LITERAL_SET":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_CAST_LITERAL_SET,
        );
        return;
      case "INVALID_CAST_METHOD":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_CAST_METHOD,
        );
        return;
      case "INVALID_CAST_NEW_EXPR":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_CAST_NEW_EXPR,
        );
        return;
      case "INVALID_CODE_POINT":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.INVALID_CODE_POINT,
          arguments: ['\\u{...}'],
        );
        return;
      case "INVALID_GENERIC_FUNCTION_TYPE":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE,
        );
        return;
      case "INVALID_METHOD_OVERRIDE":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_OVERRIDE,
        );
        return;
      case "INVALID_MODIFIER_ON_SETTER":
        _reportByCode(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER,
          message: message,
        );
        return;
      case "INVALID_OPERATOR_FOR_SUPER":
        _reportByCode(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.INVALID_OPERATOR_FOR_SUPER,
          message: message,
        );
        return;
      case "MISSING_DIGIT":
        errorReporter?.atOffset(
          errorCode: ScannerErrorCode.MISSING_DIGIT,
          offset: offset,
          length: length,
        );
        return;
      case "MISSING_ENUM_BODY":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.MISSING_ENUM_BODY,
        );
        return;
      case "MISSING_FUNCTION_BODY":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.MISSING_FUNCTION_BODY,
        );
        return;
      case "MISSING_FUNCTION_PARAMETERS":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.MISSING_FUNCTION_PARAMETERS,
        );
        return;
      case "MISSING_HEX_DIGIT":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ScannerErrorCode.MISSING_HEX_DIGIT,
        );
        return;
      case "MISSING_IDENTIFIER":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.MISSING_IDENTIFIER,
        );
        return;
      case "MISSING_METHOD_PARAMETERS":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.MISSING_METHOD_PARAMETERS,
        );
        return;
      case "MISSING_STAR_AFTER_SYNC":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.MISSING_STAR_AFTER_SYNC,
        );
        return;
      case "MISSING_TYPEDEF_PARAMETERS":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.MISSING_TYPEDEF_PARAMETERS,
        );
        return;
      case "MULTIPLE_IMPLEMENTS_CLAUSES":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES,
        );
        return;
      case "NAMED_FUNCTION_EXPRESSION":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.NAMED_FUNCTION_EXPRESSION,
        );
        return;
      case "NAMED_PARAMETER_OUTSIDE_GROUP":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP,
        );
        return;
      case "NON_PART_OF_DIRECTIVE_IN_PART":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART,
        );
        return;
      case "NON_SYNC_FACTORY":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.NON_SYNC_FACTORY,
        );
        return;
      case "POSITIONAL_AFTER_NAMED_ARGUMENT":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT,
        );
        return;
      case "RECURSIVE_CONSTRUCTOR_REDIRECT":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT,
        );
        return;
      case "RETURN_IN_GENERATOR":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.RETURN_IN_GENERATOR,
        );
        return;
      case "SUPER_INVOCATION_NOT_LAST":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.SUPER_INVOCATION_NOT_LAST,
        );
        return;
      case "SUPER_IN_REDIRECTING_CONSTRUCTOR":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR,
        );
        return;
      case "UNDEFINED_CLASS":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.UNDEFINED_CLASS,
        );
        return;
      case "UNDEFINED_GETTER":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.UNDEFINED_GETTER,
        );
        return;
      case "UNDEFINED_METHOD":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.UNDEFINED_METHOD,
        );
        return;
      case "UNDEFINED_SETTER":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.UNDEFINED_SETTER,
        );
        return;
      case "UNEXPECTED_DOLLAR_IN_STRING":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ScannerErrorCode.UNEXPECTED_DOLLAR_IN_STRING,
        );
        return;
      case "UNEXPECTED_TOKEN":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.UNEXPECTED_TOKEN,
          arguments: [lexeme()],
        );
        return;
      case "UNTERMINATED_MULTI_LINE_COMMENT":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT,
        );
        return;
      case "UNTERMINATED_STRING_LITERAL":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
        );
        return;
      case "WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER,
        );
        return;
      case "WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER,
        );
        return;
      case "YIELD_IN_NON_GENERATOR":
        errorReporter?.atOffset(
          offset: offset,
          length: length,
          errorCode: CompileTimeErrorCode.YIELD_IN_NON_GENERATOR,
        );
        return;
      case "BUILT_IN_IDENTIFIER_IN_DECLARATION":
        // Reported by [ErrorVerifier._checkForBuiltInIdentifierAsName].
        return;
      case "PRIVATE_OPTIONAL_PARAMETER":
        // Reported by [ErrorVerifier._checkForPrivateOptionalParameter].
        return;
      case "NON_SYNC_ABSTRACT_METHOD":
        // Not reported but followed by a MISSING_FUNCTION_BODY error.
        return;
      case "ABSTRACT_EXTENSION_FIELD":
        // Not reported but followed by a
        // ParserErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD.
        return;
      case "EXTENSION_TYPE_WITH_ABSTRACT_MEMBER":
        // Reported by [ErrorVerifier._checkForExtensionTypeWithAbstractMember].
        return;
      case "EXTENSION_TYPE_DECLARES_INSTANCE_FIELD":
        // Reported by
        // [ErrorVerifier._checkForExtensionTypeDeclaresInstanceField]
        return;
      case null:
        switch (message.code) {
          case codeAssertAsExpression:
            // Reported as UNDEFINED_IDENTIFIER in
            // [SimpleIdentifierResolver._resolve1],
            // followed by an EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD error,
            // or followed by an EXPECTED_TOKEN error as seen in
            // `language/constructor/explicit_instantiation_syntax_test`
            // TODO(srawlins): See below
            // TODO(johnniwinther): How can we be sure that no other
            // cases exists?
            return;
          case codeSetOrMapLiteralTooManyTypeArguments:
            // Reported as EXPECTED_TWO_MAP_TYPE_ARGUMENTS in
            // [TypeArgumentsVerifier.checkMapLiteral].
            return;
          default:
        }
    }
    assert(false, "Unreported message $analyzerCode.");
  }

  /// Report an error based on the given [message] whose range is described by
  /// the given [offset] and [length].
  void reportMessage(Message message, int offset, int length) {
    Code code = message.code;
    int index = code.index;
    if (index > 0 && index < fastaAnalyzerErrorCodes.length) {
      var errorCode = fastaAnalyzerErrorCodes[index];
      if (errorCode != null) {
        errorReporter!.reportError(
          AnalysisError.tmp(
            source: errorReporter!.source,
            offset: offset,
            length: length,
            errorCode: errorCode,
            arguments: message.arguments.values.toList(),
          ),
        );
        return;
      }
    }
    reportByCode(code.analyzerCodes?.first, offset, length, message);
  }

  void reportScannerError(
      ScannerErrorCode errorCode, int offset, List<Object>? arguments) {
    // TODO(danrubel): update client to pass length in addition to offset.
    int length = 1;
    errorReporter?.atOffset(
      errorCode: errorCode,
      offset: offset,
      length: length,
      arguments: arguments ?? const [],
    );
  }

  void _reportByCode({
    required int offset,
    required int length,
    required ErrorCode errorCode,
    required Message message,
  }) {
    if (errorReporter != null) {
      errorReporter!.reportError(
        AnalysisError.tmp(
          source: errorReporter!.source,
          offset: offset,
          length: length,
          errorCode: errorCode,
          arguments: message.arguments.values.toList(),
        ),
      );
    }
  }
}
