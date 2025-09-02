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
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';

/// An error reporter that knows how to convert a Fasta error into an analyzer
/// error.
class FastaErrorReporter {
  /// The underlying diagnostic reporter to which diagnostics are reported.
  final DiagnosticReporter? diagnosticReporter;

  /// Initialize a newly created error reporter to report diagnostics to the
  /// given [diagnosticReporter].
  FastaErrorReporter(this.diagnosticReporter);

  void reportByCode(
    String? analyzerCode,
    int offset,
    int length,
    Message message,
  ) {
    Map<String, dynamic> arguments = message.arguments;

    String lexeme() => (arguments['lexeme'] as Token).lexeme;

    switch (analyzerCode) {
      case "ASYNC_FOR_IN_WRONG_CONTEXT":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.asyncForInWrongContext,
        );
        return;
      case "ASYNC_KEYWORD_USED_AS_IDENTIFIER":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.asyncKeywordUsedAsIdentifier,
        );
        return;
      case "AWAIT_IN_WRONG_CONTEXT":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.awaitInWrongContext,
        );
        return;
      case "BUILT_IN_IDENTIFIER_AS_TYPE":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.builtInIdentifierAsType,
          arguments: [lexeme()],
        );
        return;
      case "CONCRETE_CLASS_WITH_ABSTRACT_MEMBER":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.concreteClassWithAbstractMember,
        );
        return;
      case "CONST_CONSTRUCTOR_WITH_BODY":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.constConstructorWithBody,
        );
        return;
      case "CONST_NOT_INITIALIZED":
        var name = arguments['name'] as String;
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.constNotInitialized,
          arguments: [name],
        );
        return;
      case "DEFAULT_VALUE_IN_FUNCTION_TYPE":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.defaultValueInFunctionType,
        );
        return;
      case "LABEL_UNDEFINED":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.labelUndefined,
          arguments: [arguments['name'] as Object],
        );
        return;
      case "EMPTY_ENUM_BODY":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.emptyEnumBody,
        );
        return;
      case "EXPECTED_CLASS_MEMBER":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.expectedClassMember,
        );
        return;
      case "EXPECTED_EXECUTABLE":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.expectedExecutable,
        );
        return;
      case "EXPECTED_STRING_LITERAL":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.expectedStringLiteral,
        );
        return;
      case "EXPECTED_TOKEN":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.expectedToken,
          arguments: [arguments['string'] as Object],
        );
        return;
      case "EXPECTED_TYPE_NAME":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.expectedTypeName,
        );
        return;
      case "EXTENSION_DECLARES_INSTANCE_FIELD":
        // Reported by
        // [ErrorVerifier._checkForExtensionDeclaresInstanceField]
        return;
      case "FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode:
              CompileTimeErrorCode.fieldInitializerRedirectingConstructor,
        );
        return;
      case "FINAL_NOT_INITIALIZED":
        var name = arguments['name'] as String;
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.finalNotInitialized,
          arguments: [name],
        );
        return;
      case "FINAL_NOT_INITIALIZED_CONSTRUCTOR_1":
        var name = arguments['name'] as String;
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.finalNotInitializedConstructor1,
          arguments: [name],
        );
        return;
      case "GETTER_WITH_PARAMETERS":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.getterWithParameters,
        );
        return;
      case "ILLEGAL_CHARACTER":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ScannerErrorCode.illegalCharacter,
        );
        return;
      case "INVALID_ASSIGNMENT":
        var type1 = arguments['type'] as Object;
        var type2 = arguments['type2'] as Object;
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidAssignment,
          arguments: [type1, type2],
        );
        return;
      case "INVALID_INLINE_FUNCTION_TYPE":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidInlineFunctionType,
        );
        return;
      case "INVALID_LITERAL_IN_CONFIGURATION":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.invalidLiteralInConfiguration,
        );
        return;
      case "IMPORT_OF_NON_LIBRARY":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.importOfNonLibrary,
        );
        return;
      case "INVALID_CAST_FUNCTION":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidCastFunction,
        );
        return;
      case "INVALID_CAST_FUNCTION_EXPR":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidCastFunctionExpr,
        );
        return;
      case "INVALID_CAST_LITERAL_LIST":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidCastLiteralList,
        );
        return;
      case "INVALID_CAST_LITERAL_MAP":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidCastLiteralMap,
        );
        return;
      case "INVALID_CAST_LITERAL_SET":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidCastLiteralSet,
        );
        return;
      case "INVALID_CAST_METHOD":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidCastMethod,
        );
        return;
      case "INVALID_CAST_NEW_EXPR":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidCastNewExpr,
        );
        return;
      case "INVALID_CODE_POINT":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.invalidCodePoint,
          arguments: ['\\u{...}'],
        );
        return;
      case "INVALID_GENERIC_FUNCTION_TYPE":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.invalidGenericFunctionType,
        );
        return;
      case "INVALID_METHOD_OVERRIDE":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.invalidOverride,
        );
        return;
      case "INVALID_MODIFIER_ON_SETTER":
        _reportByCode(
          offset: offset,
          length: length,
          code: CompileTimeErrorCode.invalidModifierOnSetter,
          message: message,
        );
        return;
      case "INVALID_OPERATOR_FOR_SUPER":
        _reportByCode(
          offset: offset,
          length: length,
          code: ParserErrorCode.invalidOperatorForSuper,
          message: message,
        );
        return;
      case "MISSING_DIGIT":
        diagnosticReporter?.atOffset(
          diagnosticCode: ScannerErrorCode.missingDigit,
          offset: offset,
          length: length,
        );
        return;
      case "MISSING_ENUM_BODY":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingEnumBody,
        );
        return;
      case "MISSING_FUNCTION_BODY":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingFunctionBody,
        );
        return;
      case "MISSING_FUNCTION_PARAMETERS":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingFunctionParameters,
        );
        return;
      case "MISSING_HEX_DIGIT":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ScannerErrorCode.missingHexDigit,
        );
        return;
      case "MISSING_IDENTIFIER":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingIdentifier,
        );
        return;
      case "MISSING_METHOD_PARAMETERS":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingMethodParameters,
        );
        return;
      case "MISSING_STAR_AFTER_SYNC":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingStarAfterSync,
        );
        return;
      case "MISSING_TYPEDEF_PARAMETERS":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.missingTypedefParameters,
        );
        return;
      case "MULTIPLE_IMPLEMENTS_CLAUSES":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.multipleImplementsClauses,
        );
        return;
      case "NAMED_FUNCTION_EXPRESSION":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.namedFunctionExpression,
        );
        return;
      case "NAMED_PARAMETER_OUTSIDE_GROUP":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.namedParameterOutsideGroup,
        );
        return;
      case "NON_PART_OF_DIRECTIVE_IN_PART":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.nonPartOfDirectiveInPart,
        );
        return;
      case "NON_SYNC_FACTORY":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.nonSyncFactory,
        );
        return;
      case "POSITIONAL_AFTER_NAMED_ARGUMENT":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.positionalAfterNamedArgument,
        );
        return;
      case "RECURSIVE_CONSTRUCTOR_REDIRECT":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.recursiveConstructorRedirect,
        );
        return;
      case "RETURN_IN_GENERATOR":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.returnInGenerator,
        );
        return;
      case "SUPER_INVOCATION_NOT_LAST":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.superInvocationNotLast,
        );
        return;
      case "SUPER_IN_REDIRECTING_CONSTRUCTOR":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.superInRedirectingConstructor,
        );
        return;
      case "UNDEFINED_CLASS":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.undefinedClass,
        );
        return;
      case "UNDEFINED_GETTER":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.undefinedGetter,
        );
        return;
      case "UNDEFINED_METHOD":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.undefinedMethod,
        );
        return;
      case "UNDEFINED_SETTER":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: CompileTimeErrorCode.undefinedSetter,
        );
        return;
      case "UNEXPECTED_DOLLAR_IN_STRING":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ScannerErrorCode.unexpectedDollarInString,
        );
        return;
      case "UNEXPECTED_TOKEN":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.unexpectedToken,
          arguments: [lexeme()],
        );
        return;
      case "UNTERMINATED_MULTI_LINE_COMMENT":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ScannerErrorCode.unterminatedMultiLineComment,
        );
        return;
      case "UNTERMINATED_STRING_LITERAL":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ScannerErrorCode.unterminatedStringLiteral,
        );
        return;
      case "WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER":
        diagnosticReporter?.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: ParserErrorCode.wrongSeparatorForPositionalParameter,
        );
        return;
      case "YIELD_IN_NON_GENERATOR":
        // Reported by [YieldStatementResolver._resolve_notGenerator]
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
        // CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD.
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
        diagnosticReporter!.reportError(
          Diagnostic.tmp(
            source: diagnosticReporter!.source,
            offset: offset,
            length: length,
            diagnosticCode: errorCode,
            arguments: message.arguments.values.toList(),
          ),
        );
        return;
      }
    }
    reportByCode(code.analyzerCodes?.first, offset, length, message);
  }

  void reportScannerError(
    ScannerErrorCode errorCode,
    int offset,
    List<Object>? arguments,
  ) {
    // TODO(danrubel): update client to pass length in addition to offset.
    int length = 1;
    diagnosticReporter?.atOffset(
      diagnosticCode: errorCode,
      offset: offset,
      length: length,
      arguments: arguments ?? const [],
    );
  }

  void _reportByCode({
    required int offset,
    required int length,
    required DiagnosticCode code,
    required Message message,
  }) {
    if (diagnosticReporter != null) {
      diagnosticReporter!.reportError(
        Diagnostic.tmp(
          source: diagnosticReporter!.source,
          offset: offset,
          length: length,
          diagnosticCode: code,
          arguments: message.arguments.values.toList(),
        ),
      );
    }
  }
}
