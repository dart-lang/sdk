// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/token.dart' show Token;
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:front_end/src/api_prototype/compilation_message.dart';
import 'package:front_end/src/fasta/messages.dart' show Code, Message;

/// An error reporter that knows how to convert a Fasta error into an analyzer
/// error.
class FastaErrorReporter {
  /// The underlying error reporter to which errors are reported.
  final ErrorReporter errorReporter;

  /// Initialize a newly created error reporter to report errors to the given
  /// [errorReporter].
  FastaErrorReporter(this.errorReporter);

  void reportByCode(
      String analyzerCode, int offset, int length, Message message) {
    Map<String, dynamic> arguments = message.arguments;

    String stringOrTokenLexeme() {
      var text = arguments['string'];
      if (text == null) {
        Token token = arguments['token'];
        if (token != null) {
          text = token.lexeme;
        }
      }
      return text;
    }

    switch (analyzerCode) {
      case "ABSTRACT_CLASS_MEMBER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.ABSTRACT_CLASS_MEMBER, offset, length);
        return;
      case "ANNOTATION_ON_ENUM_CONSTANT":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.ANNOTATION_ON_ENUM_CONSTANT, offset, length);
        return;
      case "ASYNC_FOR_IN_WRONG_CONTEXT":
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT, offset, length);
        return;
      case "ASYNC_KEYWORD_USED_AS_IDENTIFIER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, offset, length);
        return;
      case "BREAK_OUTSIDE_OF_LOOP":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, offset, length);
        return;
      case "BUILT_IN_IDENTIFIER_AS_TYPE":
        String name = stringOrTokenLexeme();
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE,
            offset,
            length,
            [name]);
        return;
      case "CLASS_IN_CLASS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CLASS_IN_CLASS, offset, length);
        return;
      case "COLON_IN_PLACE_OF_IN":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.COLON_IN_PLACE_OF_IN, offset, length);
        return;
      case "CONST_AFTER_FACTORY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONST_AFTER_FACTORY, offset, length);
        return;
      case "CONST_AND_COVARIANT":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONST_AND_COVARIANT, offset, length);
        return;
      case "CONST_AND_FINAL":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONST_AND_FINAL, offset, length);
        return;
      case "CONST_AND_VAR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONST_AND_VAR, offset, length);
        return;
      case "CONST_CLASS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONST_CLASS, offset, length);
        return;
      case "CONST_FACTORY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONST_FACTORY, offset, length);
        return;
      case "CONST_NOT_INITIALIZED":
        String name = arguments['name'];
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.CONST_NOT_INITIALIZED, offset, length, [name]);
        return;
      case "CONTINUE_OUTSIDE_OF_LOOP":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, offset, length);
        return;
      case "CONTINUE_WITHOUT_LABEL_IN_CASE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE, offset, length);
        return;
      case "COVARIANT_AFTER_FINAL":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.COVARIANT_AFTER_FINAL, offset, length);
        return;
      case "COVARIANT_AFTER_VAR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.COVARIANT_AFTER_VAR, offset, length);
        return;
      case "COVARIANT_AND_STATIC":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.COVARIANT_AND_STATIC, offset, length);
        return;
      case "DEFAULT_VALUE_IN_FUNCTION_TYPE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, offset, length);
        return;
      case "COVARIANT_MEMBER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.COVARIANT_MEMBER, offset, length);
        return;
      case "DEFERRED_AFTER_PREFIX":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DEFERRED_AFTER_PREFIX, offset, length);
        return;
      case "DIRECTIVE_AFTER_DECLARATION":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DIRECTIVE_AFTER_DECLARATION, offset, length);
        return;
      case "DUPLICATE_DEFERRED":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DUPLICATE_DEFERRED, offset, length);
        return;
      case "DUPLICATED_MODIFIER":
        String text = stringOrTokenLexeme();
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DUPLICATED_MODIFIER, offset, length, [text]);
        return;
      case "DUPLICATE_PREFIX":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.DUPLICATE_PREFIX, offset, length);
        return;
      case "EMPTY_ENUM_BODY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EMPTY_ENUM_BODY, offset, length);
        return;
      case "ENUM_IN_CLASS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.ENUM_IN_CLASS, offset, length);
        return;
      case "EQUALITY_CANNOT_BE_EQUALITY_OPERAND":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND,
            offset,
            length);
        return;
      case "EXPECTED_CLASS_MEMBER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXPECTED_CLASS_MEMBER, offset, length);
        return;
      case "EXPECTED_EXECUTABLE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXPECTED_EXECUTABLE, offset, length);
        return;
      case "EXPECTED_STRING_LITERAL":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXPECTED_STRING_LITERAL, offset, length);
        return;
      case "EXPECTED_TOKEN":
        String text = stringOrTokenLexeme();
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXPECTED_TOKEN, offset, length, [text]);
        return;
      case "EXPECTED_TYPE_NAME":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXPECTED_TYPE_NAME, offset, length);
        return;
      case "EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
            offset,
            length);
        return;
      case "EXTERNAL_AFTER_CONST":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_AFTER_CONST, offset, length);
        return;
      case "EXTERNAL_AFTER_FACTORY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_AFTER_FACTORY, offset, length);
        return;
      case "EXTERNAL_AFTER_STATIC":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_AFTER_STATIC, offset, length);
        return;
      case "EXTERNAL_CLASS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_CLASS, offset, length);
        return;
      case "EXTERNAL_CONSTRUCTOR_WITH_BODY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY, offset, length);
        return;
      case "EXTERNAL_ENUM":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_ENUM, offset, length);
        return;
      case "EXTERNAL_FIELD":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_FIELD, offset, length);
        return;
      case "EXTERNAL_METHOD_WITH_BODY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, offset, length);
        return;
      case "EXTERNAL_TYPEDEF":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTERNAL_TYPEDEF, offset, length);
        return;
      case "EXTRANEOUS_MODIFIER":
        String text = stringOrTokenLexeme();
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.EXTRANEOUS_MODIFIER, offset, length, [text]);
        return;
      case "FACTORY_TOP_LEVEL_DECLARATION":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION, offset, length);
        return;
      case "FINAL_AND_COVARIANT":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.FINAL_AND_COVARIANT, offset, length);
        return;
      case "FINAL_AND_VAR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.FINAL_AND_VAR, offset, length);
        return;
      case "FINAL_NOT_INITIALIZED":
        String name = arguments['name'];
        errorReporter?.reportErrorForOffset(
            StaticWarningCode.FINAL_NOT_INITIALIZED, offset, length, [name]);
        return;
      case "FUNCTION_TYPED_PARAMETER_VAR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, offset, length);
        return;
      case "GETTER_WITH_PARAMETERS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.GETTER_WITH_PARAMETERS, offset, length);
        return;
      case "ILLEGAL_CHARACTER":
        errorReporter?.reportErrorForOffset(
            ScannerErrorCode.ILLEGAL_CHARACTER, offset, length);
        return;
      case "INVALID_ASSIGNMENT":
        var type1 = arguments['type'];
        var type2 = arguments['type2'];
        errorReporter?.reportErrorForOffset(
            StaticTypeWarningCode.INVALID_ASSIGNMENT,
            offset,
            length,
            [type1, type2]);
        return;
      case "INVALID_AWAIT_IN_FOR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.INVALID_AWAIT_IN_FOR, offset, length);
        return;
      case "IMPLEMENTS_BEFORE_EXTENDS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS, offset, length);
        return;
      case "IMPLEMENTS_BEFORE_WITH":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.IMPLEMENTS_BEFORE_WITH, offset, length);
        return;
      case "IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
            offset,
            length);
        return;
      case "INVALID_CAST_FUNCTION":
        errorReporter?.reportErrorForOffset(
            StrongModeCode.INVALID_CAST_FUNCTION, offset, length);
        return;
      case "INVALID_CAST_FUNCTION_EXPR":
        errorReporter?.reportErrorForOffset(
            StrongModeCode.INVALID_CAST_FUNCTION_EXPR, offset, length);
        return;
      case "INVALID_CAST_LITERAL_LIST":
        errorReporter?.reportErrorForOffset(
            StrongModeCode.INVALID_CAST_LITERAL_LIST, offset, length);
        return;
      case "INVALID_CAST_LITERAL_MAP":
        errorReporter?.reportErrorForOffset(
            StrongModeCode.INVALID_CAST_LITERAL_MAP, offset, length);
        return;
      case "INVALID_CAST_METHOD":
        errorReporter?.reportErrorForOffset(
            StrongModeCode.INVALID_CAST_METHOD, offset, length);
        return;
      case "INVALID_CAST_NEW_EXPR":
        errorReporter?.reportErrorForOffset(
            StrongModeCode.INVALID_CAST_NEW_EXPR, offset, length);
        return;
      case "INVALID_METHOD_OVERRIDE":
        errorReporter?.reportErrorForOffset(
            StrongModeCode.INVALID_METHOD_OVERRIDE, offset, length);
        return;
      case "INVALID_MODIFIER_ON_SETTER":
        _reportByCode(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, message,
            offset, length);
        return;
      case "INVALID_OPERATOR":
        String text = stringOrTokenLexeme();
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.INVALID_OPERATOR, offset, length, [text]);
        return;
      case "INVALID_OPERATOR_FOR_SUPER":
        _reportByCode(ParserErrorCode.INVALID_OPERATOR_FOR_SUPER, message,
            offset, length);
        return;
      case "LIBRARY_DIRECTIVE_NOT_FIRST":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST, offset, length);
        return;
      case "MISSING_ASSIGNMENT_IN_INITIALIZER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, offset, length);
        return;
      case "MISSING_CATCH_OR_FINALLY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_CATCH_OR_FINALLY, offset, length);
        return;
      case "MISSING_CLASS_BODY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_CLASS_BODY, offset, length);
        return;
      case "MISSING_CONST_FINAL_VAR_OR_TYPE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, offset, length);
        return;
      case "MISSING_DIGIT":
        errorReporter?.reportErrorForOffset(
            ScannerErrorCode.MISSING_DIGIT, offset, length);
        return;
      case "MISSING_FUNCTION_BODY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_FUNCTION_BODY, offset, length);
        return;
      case "MISSING_FUNCTION_PARAMETERS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_FUNCTION_PARAMETERS, offset, length);
        return;
      case "MISSING_HEX_DIGIT":
        errorReporter?.reportErrorForOffset(
            ScannerErrorCode.MISSING_HEX_DIGIT, offset, length);
        return;
      case "MISSING_IDENTIFIER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_IDENTIFIER, offset, length);
        return;
      case "MISSING_INITIALIZER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_INITIALIZER, offset, length);
        return;
      case "MISSING_KEYWORD_OPERATOR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_KEYWORD_OPERATOR, offset, length);
        return;
      case "MISSING_METHOD_PARAMETERS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_METHOD_PARAMETERS, offset, length);
        return;
      case "MISSING_PREFIX_IN_DEFERRED_IMPORT":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT, offset, length);
        return;
      case "MISSING_STAR_AFTER_SYNC":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_STAR_AFTER_SYNC, offset, length);
        return;
      case "MISSING_TYPEDEF_PARAMETERS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, offset, length);
        return;
      case "MULTIPLE_EXTENDS_CLAUSES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES, offset, length);
        return;
      case "MULTIPLE_IMPLEMENTS_CLAUSES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES, offset, length);
        return;
      case "MULTIPLE_LIBRARY_DIRECTIVES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES, offset, length);
        return;
      case "MULTIPLE_WITH_CLAUSES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MULTIPLE_WITH_CLAUSES, offset, length);
        return;
      case "MULTIPLE_PART_OF_DIRECTIVES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES, offset, length);
        return;
      case "NAMED_FUNCTION_EXPRESSION":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.NAMED_FUNCTION_EXPRESSION, offset, length);
        return;
      case "NAMED_PARAMETER_OUTSIDE_GROUP":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, offset, length);
        return;
      case "NATIVE_CLAUSE_SHOULD_BE_ANNOTATION":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION, offset, length);
        return;
      case "NON_PART_OF_DIRECTIVE_IN_PART":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, offset, length);
        return;
      case "POSITIONAL_AFTER_NAMED_ARGUMENT":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT, offset, length);
        return;
      case "PREFIX_AFTER_COMBINATOR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.PREFIX_AFTER_COMBINATOR, offset, length);
        return;
      case "REDIRECTING_CONSTRUCTOR_WITH_BODY":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY, offset, length);
        return;
      case "REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR,
            offset,
            length);
        return;
      case "RETURN_IN_GENERATOR":
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.RETURN_IN_GENERATOR, offset, length);
        return;
      case "STATIC_AFTER_CONST":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.STATIC_AFTER_CONST, offset, length);
        return;
      case "STATIC_AFTER_FINAL":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.STATIC_AFTER_FINAL, offset, length);
        return;
      case "STATIC_AFTER_VAR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.STATIC_AFTER_VAR, offset, length);
        return;
      case "STATIC_OPERATOR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.STATIC_OPERATOR, offset, length);
        return;
      case "SWITCH_HAS_CASE_AFTER_DEFAULT_CASE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE, offset, length);
        return;
      case "SWITCH_HAS_MULTIPLE_DEFAULT_CASES":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES, offset, length);
        return;
      case "TOP_LEVEL_OPERATOR":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.TOP_LEVEL_OPERATOR, offset, length);
        return;
      case "TYPEDEF_IN_CLASS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.TYPEDEF_IN_CLASS, offset, length);
        return;
      case "UNDEFINED_GETTER":
        errorReporter?.reportErrorForOffset(
            StaticTypeWarningCode.UNDEFINED_GETTER, offset, length);
        return;
      case "UNDEFINED_METHOD":
        errorReporter?.reportErrorForOffset(
            StaticTypeWarningCode.UNDEFINED_METHOD, offset, length);
        return;
      case "UNDEFINED_SETTER":
        errorReporter?.reportErrorForOffset(
            StaticTypeWarningCode.UNDEFINED_SETTER, offset, length);
        return;
      case "UNEXPECTED_TOKEN":
        String text = stringOrTokenLexeme();
        if (text == ';') {
          errorReporter?.reportErrorForOffset(
              ParserErrorCode.EXPECTED_TOKEN, offset, length, [text]);
        } else {
          errorReporter?.reportErrorForOffset(
              ParserErrorCode.UNEXPECTED_TOKEN, offset, length, [text]);
        }
        return;
      case "UNTERMINATED_MULTI_LINE_COMMENT":
        errorReporter?.reportErrorForOffset(
            ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT, offset, length);
        return;
      case "UNTERMINATED_STRING_LITERAL":
        errorReporter?.reportErrorForOffset(
            ScannerErrorCode.UNTERMINATED_STRING_LITERAL, offset, length);
        return;
      case "VAR_AND_TYPE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.VAR_AND_TYPE, offset, length);
        return;
      case "VAR_RETURN_TYPE":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.VAR_RETURN_TYPE, offset, length);
        return;
      case "WITH_BEFORE_EXTENDS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.WITH_BEFORE_EXTENDS, offset, length);
        return;
      case "WITH_WITHOUT_EXTENDS":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.WITH_WITHOUT_EXTENDS, offset, length);
        return;
      case "WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER":
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER,
            offset,
            length);
        return;
      case "WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER":
        errorReporter?.reportErrorForOffset(
            ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER,
            offset,
            length);
        return;
      case "YIELD_IN_NON_GENERATOR":
        errorReporter?.reportErrorForOffset(
            CompileTimeErrorCode.YIELD_IN_NON_GENERATOR, offset, length);
        return;
      default:
      // fall through
    }
  }

  void reportCompilationMessage(CompilationMessage message) {
    String errorCodeStr = message.analyzerCode;
    ErrorCode errorCode = _getErrorCode(errorCodeStr);
    if (errorCode != null) {
      errorReporter.reportError(new AnalysisError.forValues(
          errorReporter.source,
          message.span.start.offset,
          message.span.length,
          errorCode,
          message.message,
          message.tip));
    } else {
      // TODO(mfairhurst) throw here, and fail all tests that trip this.
    }
  }

  /// Report an error based on the given [message] whose range is described by
  /// the given [offset] and [length].
  void reportMessage(Message message, int offset, int length) {
    Code code = message.code;

    reportByCode(code.analyzerCode, offset, length, message);
  }

  void _reportByCode(
      ErrorCode errorCode, Message message, int offset, int length) {
    if (errorReporter != null) {
      errorReporter.reportError(new AnalysisError.forValues(
          errorReporter.source,
          offset,
          length,
          errorCode,
          message.message,
          null));
    }
  }

  /// Return the [ErrorCode] for the given [shortName], or `null` if not found.
  static ErrorCode _getErrorCode(String shortName) {
    const prefixes = const {
      CompileTimeErrorCode: 'CompileTimeErrorCode',
      ParserErrorCode: 'ParserErrorCode',
      StaticTypeWarningCode: 'StaticTypeWarningCode',
      StaticWarningCode: 'StaticWarningCode'
    };
    for (var prefix in prefixes.values) {
      var uniqueName = '$prefix.$shortName';
      var errorCode = errorCodeByUniqueName(uniqueName);
      if (errorCode != null) {
        return errorCode;
      }
    }
    return null;
  }
}
