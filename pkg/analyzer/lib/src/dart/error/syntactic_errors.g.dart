// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/dart/error/syntactic_errors.dart";

class ParserErrorCode extends DiagnosticCodeWithExpectedTypes {
  /// No parameters.
  static const DiagnosticWithoutArguments abstractClassMember =
      DiagnosticWithoutArgumentsImpl(
        name: 'ABSTRACT_CLASS_MEMBER',
        problemMessage:
            "Members of classes can't be declared to be 'abstract'.",
        correctionMessage:
            "Try removing the 'abstract' keyword. You can add the 'abstract' "
            "keyword before the class declaration.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ABSTRACT_CLASS_MEMBER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments abstractExternalField =
      DiagnosticWithoutArgumentsImpl(
        name: 'ABSTRACT_EXTERNAL_FIELD',
        problemMessage:
            "Fields can't be declared both 'abstract' and 'external'.",
        correctionMessage: "Try removing the 'abstract' or 'external' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ABSTRACT_EXTERNAL_FIELD',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments abstractFinalBaseClass =
      DiagnosticWithoutArgumentsImpl(
        name: 'ABSTRACT_FINAL_BASE_CLASS',
        problemMessage:
            "An 'abstract' class can't be declared as both 'final' and 'base'.",
        correctionMessage: "Try removing either the 'final' or 'base' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ABSTRACT_FINAL_BASE_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  abstractFinalInterfaceClass = DiagnosticWithoutArgumentsImpl(
    name: 'ABSTRACT_FINAL_INTERFACE_CLASS',
    problemMessage:
        "An 'abstract' class can't be declared as both 'final' and 'interface'.",
    correctionMessage:
        "Try removing either the 'final' or 'interface' keyword.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.ABSTRACT_FINAL_INTERFACE_CLASS',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments abstractLateField =
      DiagnosticWithoutArgumentsImpl(
        name: 'ABSTRACT_LATE_FIELD',
        problemMessage: "Abstract fields cannot be late.",
        correctionMessage: "Try removing the 'abstract' or 'late' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ABSTRACT_LATE_FIELD',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments abstractSealedClass =
      DiagnosticWithoutArgumentsImpl(
        name: 'ABSTRACT_SEALED_CLASS',
        problemMessage:
            "A 'sealed' class can't be marked 'abstract' because it's already "
            "implicitly abstract.",
        correctionMessage: "Try removing the 'abstract' keyword.",
        hasPublishedDocs: true,
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ABSTRACT_SEALED_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments abstractStaticField =
      DiagnosticWithoutArgumentsImpl(
        name: 'ABSTRACT_STATIC_FIELD',
        problemMessage: "Static fields can't be declared 'abstract'.",
        correctionMessage: "Try removing the 'abstract' or 'static' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ABSTRACT_STATIC_FIELD',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments abstractStaticMethod =
      DiagnosticWithoutArgumentsImpl(
        name: 'ABSTRACT_STATIC_METHOD',
        problemMessage: "Static methods can't be declared to be 'abstract'.",
        correctionMessage: "Try removing the keyword 'abstract'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ABSTRACT_STATIC_METHOD',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  annotationOnTypeArgument = DiagnosticWithoutArgumentsImpl(
    name: 'ANNOTATION_ON_TYPE_ARGUMENT',
    problemMessage:
        "Type arguments can't have annotations because they aren't declarations.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.ANNOTATION_ON_TYPE_ARGUMENT',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments annotationSpaceBeforeParenthesis =
      DiagnosticWithoutArgumentsImpl(
        name: 'ANNOTATION_SPACE_BEFORE_PARENTHESIS',
        problemMessage:
            "Annotations can't have spaces or comments before the parenthesis.",
        correctionMessage:
            "Remove any spaces or comments before the parenthesis.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ANNOTATION_SPACE_BEFORE_PARENTHESIS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments annotationWithTypeArguments =
      DiagnosticWithoutArgumentsImpl(
        name: 'ANNOTATION_WITH_TYPE_ARGUMENTS',
        problemMessage: "An annotation can't use type arguments.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ANNOTATION_WITH_TYPE_ARGUMENTS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  annotationWithTypeArgumentsUninstantiated = DiagnosticWithoutArgumentsImpl(
    name: 'ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED',
    problemMessage:
        "An annotation with type arguments must be followed by an argument list.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED',
    expectedTypes: [],
  );

  /// 16.32 Identifier Reference: It is a compile-time error if any of the
  /// identifiers async, await, or yield is used as an identifier in a function
  /// body marked with either async, async, or sync.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments
  asyncKeywordUsedAsIdentifier = DiagnosticWithoutArgumentsImpl(
    name: 'ASYNC_KEYWORD_USED_AS_IDENTIFIER',
    problemMessage:
        "The keywords 'await' and 'yield' can't be used as identifiers in an "
        "asynchronous or generator function.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments baseEnum =
      DiagnosticWithoutArgumentsImpl(
        name: 'BASE_ENUM',
        problemMessage: "Enums can't be declared to be 'base'.",
        correctionMessage: "Try removing the keyword 'base'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.BASE_ENUM',
        expectedTypes: [],
      );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  binaryOperatorWrittenOut = DiagnosticWithArguments(
    name: 'BINARY_OPERATOR_WRITTEN_OUT',
    problemMessage:
        "Binary operator '{0}' is written as '{1}' instead of the written out "
        "word.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT',
    withArguments: _withArgumentsBinaryOperatorWrittenOut,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  breakOutsideOfLoop = DiagnosticWithoutArgumentsImpl(
    name: 'BREAK_OUTSIDE_OF_LOOP',
    problemMessage:
        "A break statement can't be used outside of a loop or switch statement.",
    correctionMessage: "Try removing the break statement.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.BREAK_OUTSIDE_OF_LOOP',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  catchSyntax = DiagnosticWithoutArgumentsImpl(
    name: 'CATCH_SYNTAX',
    problemMessage:
        "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
    correctionMessage:
        "No types are needed, the first is given by 'on', the second is always "
        "'StackTrace'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.CATCH_SYNTAX',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  catchSyntaxExtraParameters = DiagnosticWithoutArgumentsImpl(
    name: 'CATCH_SYNTAX_EXTRA_PARAMETERS',
    problemMessage:
        "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
    correctionMessage:
        "No types are needed, the first is given by 'on', the second is always "
        "'StackTrace'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.CATCH_SYNTAX_EXTRA_PARAMETERS',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments classInClass =
      DiagnosticWithoutArgumentsImpl(
        name: 'CLASS_IN_CLASS',
        problemMessage: "Classes can't be declared inside other classes.",
        correctionMessage: "Try moving the class to the top-level.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.CLASS_IN_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments colonInPlaceOfIn =
      DiagnosticWithoutArgumentsImpl(
        name: 'COLON_IN_PLACE_OF_IN',
        problemMessage: "For-in loops use 'in' rather than a colon.",
        correctionMessage: "Try replacing the colon with the keyword 'in'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.COLON_IN_PLACE_OF_IN',
        expectedTypes: [],
      );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  conflictingModifiers = DiagnosticWithArguments(
    name: 'CONFLICTING_MODIFIERS',
    problemMessage: "Members can't be declared to be both '{0}' and '{1}'.",
    correctionMessage: "Try removing one of the keywords.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.CONFLICTING_MODIFIERS',
    withArguments: _withArgumentsConflictingModifiers,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  constAndFinal = DiagnosticWithoutArgumentsImpl(
    name: 'CONST_AND_FINAL',
    problemMessage: "Members can't be declared to be both 'const' and 'final'.",
    correctionMessage: "Try removing either the 'const' or 'final' keyword.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.CONST_AND_FINAL',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  constClass = DiagnosticWithoutArgumentsImpl(
    name: 'CONST_CLASS',
    problemMessage: "Classes can't be declared to be 'const'.",
    correctionMessage:
        "Try removing the 'const' keyword. If you're trying to indicate that "
        "instances of the class can be constants, place the 'const' keyword on "
        " the class' constructor(s).",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.CONST_CLASS',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments constConstructorWithBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'CONST_CONSTRUCTOR_WITH_BODY',
        problemMessage: "Const constructors can't have a body.",
        correctionMessage:
            "Try removing either the 'const' keyword or the body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  constFactory = DiagnosticWithoutArgumentsImpl(
    name: 'CONST_FACTORY',
    problemMessage:
        "Only redirecting factory constructors can be declared to be 'const'.",
    correctionMessage:
        "Try removing the 'const' keyword, or replacing the body with '=' "
        "followed by a valid target.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.CONST_FACTORY',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments constMethod =
      DiagnosticWithoutArgumentsImpl(
        name: 'CONST_METHOD',
        problemMessage:
            "Getters, setters and methods can't be declared to be 'const'.",
        correctionMessage: "Try removing the 'const' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.CONST_METHOD',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments constructorWithReturnType =
      DiagnosticWithoutArgumentsImpl(
        name: 'CONSTRUCTOR_WITH_RETURN_TYPE',
        problemMessage: "Constructors can't have a return type.",
        correctionMessage: "Try removing the return type.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  constructorWithTypeArguments = DiagnosticWithoutArgumentsImpl(
    name: 'CONSTRUCTOR_WITH_TYPE_ARGUMENTS',
    problemMessage:
        "A constructor invocation can't have type arguments after the constructor "
        "name.",
    correctionMessage:
        "Try removing the type arguments or placing them after the class name.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.CONSTRUCTOR_WITH_TYPE_ARGUMENTS',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  constWithoutPrimaryConstructor = DiagnosticWithoutArgumentsImpl(
    name: 'CONST_WITHOUT_PRIMARY_CONSTRUCTOR',
    problemMessage:
        "'const' can only be used together with a primary constructor declaration.",
    correctionMessage:
        "Try removing the 'const' keyword or adding a primary constructor "
        "declaration.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.CONST_WITHOUT_PRIMARY_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  continueOutsideOfLoop = DiagnosticWithoutArgumentsImpl(
    name: 'CONTINUE_OUTSIDE_OF_LOOP',
    problemMessage:
        "A continue statement can't be used outside of a loop or switch statement.",
    correctionMessage: "Try removing the continue statement.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  continueWithoutLabelInCase = DiagnosticWithoutArgumentsImpl(
    name: 'CONTINUE_WITHOUT_LABEL_IN_CASE',
    problemMessage:
        "A continue statement in a switch statement must have a label as a target.",
    correctionMessage:
        "Try adding a label associated with one of the case clauses to the "
        "continue statement.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments covariantAndStatic =
      DiagnosticWithoutArgumentsImpl(
        name: 'COVARIANT_AND_STATIC',
        problemMessage:
            "Members can't be declared to be both 'covariant' and 'static'.",
        correctionMessage:
            "Try removing either the 'covariant' or 'static' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.COVARIANT_AND_STATIC',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments covariantConstructor =
      DiagnosticWithoutArgumentsImpl(
        name: 'COVARIANT_CONSTRUCTOR',
        problemMessage: "A constructor can't be declared to be 'covariant'.",
        correctionMessage: "Try removing the keyword 'covariant'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.COVARIANT_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments covariantMember =
      DiagnosticWithoutArgumentsImpl(
        name: 'COVARIANT_MEMBER',
        problemMessage:
            "Getters, setters and methods can't be declared to be 'covariant'.",
        correctionMessage: "Try removing the 'covariant' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.COVARIANT_MEMBER',
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments defaultInSwitchExpression =
      DiagnosticWithoutArgumentsImpl(
        name: 'DEFAULT_IN_SWITCH_EXPRESSION',
        problemMessage:
            "A switch expression may not use the `default` keyword.",
        correctionMessage: "Try replacing `default` with `_`.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.DEFAULT_IN_SWITCH_EXPRESSION',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments defaultValueInFunctionType =
      DiagnosticWithoutArgumentsImpl(
        name: 'DEFAULT_VALUE_IN_FUNCTION_TYPE',
        problemMessage:
            "Parameters in a function type can't have default values.",
        correctionMessage: "Try removing the default value.",
        hasPublishedDocs: true,
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  deferredAfterPrefix = DiagnosticWithoutArgumentsImpl(
    name: 'DEFERRED_AFTER_PREFIX',
    problemMessage:
        "The deferred keyword should come immediately before the prefix ('as' "
        "clause).",
    correctionMessage: "Try moving the deferred keyword before the prefix.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.DEFERRED_AFTER_PREFIX',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments directiveAfterDeclaration =
      DiagnosticWithoutArgumentsImpl(
        name: 'DIRECTIVE_AFTER_DECLARATION',
        problemMessage: "Directives must appear before any declarations.",
        correctionMessage: "Try moving the directive before any declarations.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.DIRECTIVE_AFTER_DECLARATION',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments duplicateDeferred =
      DiagnosticWithoutArgumentsImpl(
        name: 'DUPLICATE_DEFERRED',
        problemMessage:
            "An import directive can only have one 'deferred' keyword.",
        correctionMessage: "Try removing all but one 'deferred' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.DUPLICATE_DEFERRED',
        expectedTypes: [],
      );

  /// Parameters:
  /// 0: the modifier that was duplicated
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode duplicatedModifier =
      DiagnosticCodeWithExpectedTypes(
        name: 'DUPLICATED_MODIFIER',
        problemMessage: "The modifier '{0}' was already specified.",
        correctionMessage:
            "Try removing all but one occurrence of the modifier.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.DUPLICATED_MODIFIER',
        expectedTypes: [ExpectedType.token],
      );

  /// Parameters:
  /// 0: the label that was duplicated
  ///
  /// Parameters:
  /// Name name: undocumented
  static const DiagnosticCode duplicateLabelInSwitchStatement =
      DiagnosticCodeWithExpectedTypes(
        name: 'DUPLICATE_LABEL_IN_SWITCH_STATEMENT',
        problemMessage:
            "The label '{0}' was already used in this switch statement.",
        correctionMessage: "Try choosing a different name for this label.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT',
        expectedTypes: [ExpectedType.name],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments duplicatePrefix =
      DiagnosticWithoutArgumentsImpl(
        name: 'DUPLICATE_PREFIX',
        problemMessage:
            "An import directive can only have one prefix ('as' clause).",
        correctionMessage: "Try removing all but one prefix.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.DUPLICATE_PREFIX',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments emptyEnumBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EMPTY_ENUM_BODY',
        problemMessage: "An enum must declare at least one constant name.",
        correctionMessage: "Try declaring a constant.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EMPTY_ENUM_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments emptyRecordLiteralWithComma =
      DiagnosticWithoutArgumentsImpl(
        name: 'EMPTY_RECORD_LITERAL_WITH_COMMA',
        problemMessage:
            "A record literal without fields can't have a trailing comma.",
        correctionMessage: "Try removing the trailing comma.",
        hasPublishedDocs: true,
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EMPTY_RECORD_LITERAL_WITH_COMMA',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments emptyRecordTypeNamedFieldsList =
      DiagnosticWithoutArgumentsImpl(
        name: 'EMPTY_RECORD_TYPE_NAMED_FIELDS_LIST',
        problemMessage:
            "The list of named fields in a record type can't be empty.",
        correctionMessage: "Try adding a named field to the list.",
        hasPublishedDocs: true,
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EMPTY_RECORD_TYPE_NAMED_FIELDS_LIST',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments emptyRecordTypeWithComma =
      DiagnosticWithoutArgumentsImpl(
        name: 'EMPTY_RECORD_TYPE_WITH_COMMA',
        problemMessage:
            "A record type without fields can't have a trailing comma.",
        correctionMessage: "Try removing the trailing comma.",
        hasPublishedDocs: true,
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EMPTY_RECORD_TYPE_WITH_COMMA',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments enumInClass =
      DiagnosticWithoutArgumentsImpl(
        name: 'ENUM_IN_CLASS',
        problemMessage: "Enums can't be declared inside classes.",
        correctionMessage: "Try moving the enum to the top-level.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ENUM_IN_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments equalityCannotBeEqualityOperand =
      DiagnosticWithoutArgumentsImpl(
        name: 'EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
        problemMessage:
            "A comparison expression can't be an operand of another comparison "
            "expression.",
        correctionMessage:
            "Try putting parentheses around one of the comparisons.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedCaseOrDefault =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_CASE_OR_DEFAULT',
        problemMessage: "Expected 'case' or 'default'.",
        correctionMessage: "Try placing this code inside a case clause.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_CASE_OR_DEFAULT',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedCatchClauseBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_BODY',
        problemMessage: "A catch clause must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_CATCH_CLAUSE_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedClassBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_BODY',
        problemMessage:
            "A class declaration must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_CLASS_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedClassMember =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_CLASS_MEMBER',
        problemMessage: "Expected a class member.",
        correctionMessage: "Try placing this code inside a class member.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_CLASS_MEMBER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedElseOrComma =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_ELSE_OR_COMMA',
        problemMessage: "Expected 'else' or comma.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_ELSE_OR_COMMA',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  expectedExecutable = DiagnosticWithoutArgumentsImpl(
    name: 'EXPECTED_EXECUTABLE',
    problemMessage:
        "Expected a method, getter, setter or operator declaration.",
    correctionMessage:
        "This appears to be incomplete code. Try removing it or completing it.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.EXPECTED_EXECUTABLE',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedExtensionBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_BODY',
        problemMessage:
            "An extension declaration must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_EXTENSION_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  expectedExtensionTypeBody = DiagnosticWithoutArgumentsImpl(
    name: 'EXPECTED_BODY',
    problemMessage:
        "An extension type declaration must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.EXPECTED_EXTENSION_TYPE_BODY',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedFinallyClauseBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_BODY',
        problemMessage:
            "A finally clause must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_FINALLY_CLAUSE_BODY',
        expectedTypes: [],
      );

  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode expectedIdentifierButGotKeyword =
      DiagnosticCodeWithExpectedTypes(
        name: 'EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD',
        problemMessage:
            "'{0}' can't be used as an identifier because it's a keyword.",
        correctionMessage:
            "Try renaming this to be an identifier that isn't a keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD',
        expectedTypes: [ExpectedType.token],
      );

  /// Parameters:
  /// String string: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String string})
  >
  expectedInstead = DiagnosticWithArguments(
    name: 'EXPECTED_INSTEAD',
    problemMessage: "Expected '{0}' instead of this.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.EXPECTED_INSTEAD',
    withArguments: _withArgumentsExpectedInstead,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  expectedListOrMapLiteral = DiagnosticWithoutArgumentsImpl(
    name: 'EXPECTED_LIST_OR_MAP_LITERAL',
    problemMessage: "Expected a list or map literal.",
    correctionMessage:
        "Try inserting a list or map literal, or remove the type arguments.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedMixinBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_BODY',
        problemMessage:
            "A mixin declaration must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_MIXIN_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedNamedTypeExtends =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_NAMED_TYPE',
        problemMessage: "Expected a class name.",
        correctionMessage:
            "Try using a class name, possibly with type arguments.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_NAMED_TYPE_EXTENDS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedNamedTypeImplements =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_NAMED_TYPE',
        problemMessage: "Expected the name of a class or mixin.",
        correctionMessage:
            "Try using a class or mixin name, possibly with type arguments.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_NAMED_TYPE_IMPLEMENTS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedNamedTypeOn =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_NAMED_TYPE',
        problemMessage: "Expected the name of a class or mixin.",
        correctionMessage:
            "Try using a class or mixin name, possibly with type arguments.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_NAMED_TYPE_ON',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedNamedTypeWith =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_NAMED_TYPE',
        problemMessage: "Expected a mixin name.",
        correctionMessage:
            "Try using a mixin name, possibly with type arguments.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_NAMED_TYPE_WITH',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedRepresentationField =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_REPRESENTATION_FIELD',
        problemMessage: "Expected a representation field.",
        correctionMessage:
            "Try providing the representation field for this extension type.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_REPRESENTATION_FIELD',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedRepresentationType =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_REPRESENTATION_TYPE',
        problemMessage: "Expected a representation type.",
        correctionMessage:
            "Try providing the representation type for this extension type.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_REPRESENTATION_TYPE',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedStringLiteral =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_STRING_LITERAL',
        problemMessage: "Expected a string literal.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_STRING_LITERAL',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedSwitchExpressionBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_BODY',
        problemMessage:
            "A switch expression must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_SWITCH_EXPRESSION_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedSwitchStatementBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_BODY',
        problemMessage:
            "A switch statement must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_SWITCH_STATEMENT_BODY',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the token that was expected but not found
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  expectedToken = DiagnosticWithArguments(
    name: 'EXPECTED_TOKEN',
    problemMessage: "Expected to find '{0}'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.EXPECTED_TOKEN',
    withArguments: _withArgumentsExpectedToken,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedTryStatementBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_BODY',
        problemMessage:
            "A try statement must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_TRY_STATEMENT_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments expectedTypeName =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPECTED_TYPE_NAME',
        problemMessage: "Expected a type name.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPECTED_TYPE_NAME',
        expectedTypes: [],
      );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  experimentNotEnabled = DiagnosticWithArguments(
    name: 'EXPERIMENT_NOT_ENABLED',
    problemMessage: "This requires the '{0}' language feature to be enabled.",
    correctionMessage:
        "Try updating your pubspec.yaml to set the minimum SDK constraint to "
        "{1} or higher, and running 'pub get'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.EXPERIMENT_NOT_ENABLED',
    withArguments: _withArgumentsExperimentNotEnabled,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String string: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String string})
  >
  experimentNotEnabledOffByDefault = DiagnosticWithArguments(
    name: 'EXPERIMENT_NOT_ENABLED_OFF_BY_DEFAULT',
    problemMessage:
        "This requires the experimental '{0}' language feature to be enabled.",
    correctionMessage:
        "Try passing the '--enable-experiment={0}' command line option.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.EXPERIMENT_NOT_ENABLED_OFF_BY_DEFAULT',
    withArguments: _withArgumentsExperimentNotEnabledOffByDefault,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments exportDirectiveAfterPartDirective =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
        problemMessage: "Export directives must precede part directives.",
        correctionMessage:
            "Try moving the export directives before the part directives.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments extensionAugmentationHasOnClause =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTENSION_AUGMENTATION_HAS_ON_CLAUSE',
        problemMessage: "Extension augmentations can't have 'on' clauses.",
        correctionMessage: "Try removing the 'on' clause.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTENSION_AUGMENTATION_HAS_ON_CLAUSE',
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments extensionDeclaresAbstractMember =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTENSION_DECLARES_ABSTRACT_MEMBER',
        problemMessage: "Extensions can't declare abstract members.",
        correctionMessage: "Try providing an implementation for the member.",
        hasPublishedDocs: true,
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTENSION_DECLARES_ABSTRACT_MEMBER',
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments extensionDeclaresConstructor =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTENSION_DECLARES_CONSTRUCTOR',
        problemMessage: "Extensions can't declare constructors.",
        correctionMessage: "Try removing the constructor declaration.",
        hasPublishedDocs: true,
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments extensionTypeExtends =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTENSION_TYPE_EXTENDS',
        problemMessage:
            "An extension type declaration can't have an 'extends' clause.",
        correctionMessage:
            "Try removing the 'extends' clause or replacing the 'extends' with "
            "'implements'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTENSION_TYPE_EXTENDS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments extensionTypeWith =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTENSION_TYPE_WITH',
        problemMessage:
            "An extension type declaration can't have a 'with' clause.",
        correctionMessage:
            "Try removing the 'with' clause or replacing the 'with' with "
            "'implements'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTENSION_TYPE_WITH',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments externalClass =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_CLASS',
        problemMessage: "Classes can't be declared to be 'external'.",
        correctionMessage: "Try removing the keyword 'external'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  externalConstructorWithFieldInitializers = DiagnosticWithoutArgumentsImpl(
    name: 'EXTERNAL_CONSTRUCTOR_WITH_FIELD_INITIALIZERS',
    problemMessage: "An external constructor can't initialize fields.",
    correctionMessage:
        "Try removing the field initializers, or removing the keyword "
        "'external'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_FIELD_INITIALIZERS',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments externalConstructorWithInitializer =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER',
        problemMessage: "An external constructor can't have any initializers.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments externalEnum =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_ENUM',
        problemMessage: "Enums can't be declared to be 'external'.",
        correctionMessage: "Try removing the keyword 'external'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_ENUM',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments externalFactoryRedirection =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_FACTORY_REDIRECTION',
        problemMessage: "A redirecting factory can't be external.",
        correctionMessage: "Try removing the 'external' modifier.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_FACTORY_REDIRECTION',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments externalFactoryWithBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_FACTORY_WITH_BODY',
        problemMessage: "External factories can't have a body.",
        correctionMessage:
            "Try removing the body of the factory, or removing the keyword "
            "'external'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_FACTORY_WITH_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments externalGetterWithBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_GETTER_WITH_BODY',
        problemMessage: "External getters can't have a body.",
        correctionMessage:
            "Try removing the body of the getter, or removing the keyword "
            "'external'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_GETTER_WITH_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments externalLateField =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_LATE_FIELD',
        problemMessage: "External fields cannot be late.",
        correctionMessage: "Try removing the 'external' or 'late' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_LATE_FIELD',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments externalMethodWithBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_METHOD_WITH_BODY',
        problemMessage: "An external or native method can't have a body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_METHOD_WITH_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments externalOperatorWithBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_OPERATOR_WITH_BODY',
        problemMessage: "External operators can't have a body.",
        correctionMessage:
            "Try removing the body of the operator, or removing the keyword "
            "'external'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments externalSetterWithBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_SETTER_WITH_BODY',
        problemMessage: "External setters can't have a body.",
        correctionMessage:
            "Try removing the body of the setter, or removing the keyword "
            "'external'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_SETTER_WITH_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments externalTypedef =
      DiagnosticWithoutArgumentsImpl(
        name: 'EXTERNAL_TYPEDEF',
        problemMessage: "Typedefs can't be declared to be 'external'.",
        correctionMessage: "Try removing the keyword 'external'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTERNAL_TYPEDEF',
        expectedTypes: [],
      );

  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode extraneousModifier =
      DiagnosticCodeWithExpectedTypes(
        name: 'EXTRANEOUS_MODIFIER',
        problemMessage: "Can't have modifier '{0}' here.",
        correctionMessage: "Try removing '{0}'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTRANEOUS_MODIFIER',
        expectedTypes: [ExpectedType.token],
      );

  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode extraneousModifierInExtensionType =
      DiagnosticCodeWithExpectedTypes(
        name: 'EXTRANEOUS_MODIFIER_IN_EXTENSION_TYPE',
        problemMessage: "Can't have modifier '{0}' in an extension type.",
        correctionMessage: "Try removing '{0}'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.EXTRANEOUS_MODIFIER_IN_EXTENSION_TYPE',
        expectedTypes: [ExpectedType.token],
      );

  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode extraneousModifierInPrimaryConstructor =
      DiagnosticCodeWithExpectedTypes(
        name: 'EXTRANEOUS_MODIFIER_IN_PRIMARY_CONSTRUCTOR',
        problemMessage: "Can't have modifier '{0}' in a primary constructor.",
        correctionMessage: "Try removing '{0}'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName:
            'ParserErrorCode.EXTRANEOUS_MODIFIER_IN_PRIMARY_CONSTRUCTOR',
        expectedTypes: [ExpectedType.token],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments factoryTopLevelDeclaration =
      DiagnosticWithoutArgumentsImpl(
        name: 'FACTORY_TOP_LEVEL_DECLARATION',
        problemMessage:
            "Top-level declarations can't be declared to be 'factory'.",
        correctionMessage: "Try removing the keyword 'factory'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments factoryWithInitializers =
      DiagnosticWithoutArgumentsImpl(
        name: 'FACTORY_WITH_INITIALIZERS',
        problemMessage: "A 'factory' constructor can't have initializers.",
        correctionMessage:
            "Try removing the 'factory' keyword to make this a generative "
            "constructor, or removing the initializers.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.FACTORY_WITH_INITIALIZERS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments factoryWithoutBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'FACTORY_WITHOUT_BODY',
        problemMessage:
            "A non-redirecting 'factory' constructor must have a body.",
        correctionMessage: "Try adding a body to the constructor.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.FACTORY_WITHOUT_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  fieldInitializedOutsideDeclaringClass = DiagnosticWithoutArgumentsImpl(
    name: 'FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS',
    problemMessage: "A field can only be initialized in its declaring class",
    correctionMessage:
        "Try passing a value into the superclass constructor, or moving the "
        "initialization into the constructor body.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments finalAndCovariant =
      DiagnosticWithoutArgumentsImpl(
        name: 'FINAL_AND_COVARIANT',
        problemMessage:
            "Members can't be declared to be both 'final' and 'covariant'.",
        correctionMessage:
            "Try removing either the 'final' or 'covariant' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.FINAL_AND_COVARIANT',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  finalAndCovariantLateWithInitializer = DiagnosticWithoutArgumentsImpl(
    name: 'FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER',
    problemMessage:
        "Members marked 'late' with an initializer can't be declared to be both "
        "'final' and 'covariant'.",
    correctionMessage:
        "Try removing either the 'final' or 'covariant' keyword, or removing "
        "the initializer.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments finalAndVar =
      DiagnosticWithoutArgumentsImpl(
        name: 'FINAL_AND_VAR',
        problemMessage:
            "Members can't be declared to be both 'final' and 'var'.",
        correctionMessage: "Try removing the keyword 'var'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.FINAL_AND_VAR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments finalConstructor =
      DiagnosticWithoutArgumentsImpl(
        name: 'FINAL_CONSTRUCTOR',
        problemMessage: "A constructor can't be declared to be 'final'.",
        correctionMessage: "Try removing the keyword 'final'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.FINAL_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments finalEnum =
      DiagnosticWithoutArgumentsImpl(
        name: 'FINAL_ENUM',
        problemMessage: "Enums can't be declared to be 'final'.",
        correctionMessage: "Try removing the keyword 'final'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.FINAL_ENUM',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments finalMethod =
      DiagnosticWithoutArgumentsImpl(
        name: 'FINAL_METHOD',
        problemMessage:
            "Getters, setters and methods can't be declared to be 'final'.",
        correctionMessage: "Try removing the keyword 'final'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.FINAL_METHOD',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments finalMixin =
      DiagnosticWithoutArgumentsImpl(
        name: 'FINAL_MIXIN',
        problemMessage: "A mixin can't be declared 'final'.",
        correctionMessage: "Try removing the 'final' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.FINAL_MIXIN',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments finalMixinClass =
      DiagnosticWithoutArgumentsImpl(
        name: 'FINAL_MIXIN_CLASS',
        problemMessage: "A mixin class can't be declared 'final'.",
        correctionMessage: "Try removing the 'final' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.FINAL_MIXIN_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  functionTypedParameterVar = DiagnosticWithoutArgumentsImpl(
    name: 'FUNCTION_TYPED_PARAMETER_VAR',
    problemMessage:
        "Function-typed parameters can't specify 'const', 'final' or 'var' in "
        "place of a return type.",
    correctionMessage: "Try replacing the keyword with a return type.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments getterConstructor =
      DiagnosticWithoutArgumentsImpl(
        name: 'GETTER_CONSTRUCTOR',
        problemMessage: "Constructors can't be a getter.",
        correctionMessage: "Try removing 'get'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.GETTER_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  getterInFunction = DiagnosticWithoutArgumentsImpl(
    name: 'GETTER_IN_FUNCTION',
    problemMessage: "Getters can't be defined within methods or functions.",
    correctionMessage:
        "Try moving the getter outside the method or function, or converting "
        "the getter to a function.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.GETTER_IN_FUNCTION',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments getterWithParameters =
      DiagnosticWithoutArgumentsImpl(
        name: 'GETTER_WITH_PARAMETERS',
        problemMessage: "Getters must be declared without a parameter list.",
        correctionMessage:
            "Try removing the parameter list, or removing the keyword 'get' to "
            "define a method rather than a getter.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.GETTER_WITH_PARAMETERS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments illegalAssignmentToNonAssignable =
      DiagnosticWithoutArgumentsImpl(
        name: 'ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE',
        problemMessage: "Illegal assignment to non-assignable expression.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE',
        expectedTypes: [],
      );

  /// Parameters:
  /// 0: the illegal name
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode illegalPatternAssignmentVariableName =
      DiagnosticCodeWithExpectedTypes(
        name: 'ILLEGAL_PATTERN_ASSIGNMENT_VARIABLE_NAME',
        problemMessage:
            "A variable assigned by a pattern assignment can't be named '{0}'.",
        correctionMessage: "Choose a different name.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ILLEGAL_PATTERN_ASSIGNMENT_VARIABLE_NAME',
        expectedTypes: [ExpectedType.token],
      );

  /// Parameters:
  /// 0: the illegal name
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode illegalPatternIdentifierName =
      DiagnosticCodeWithExpectedTypes(
        name: 'ILLEGAL_PATTERN_IDENTIFIER_NAME',
        problemMessage: "A pattern can't refer to an identifier named '{0}'.",
        correctionMessage: "Match the identifier using '==",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ILLEGAL_PATTERN_IDENTIFIER_NAME',
        expectedTypes: [ExpectedType.token],
      );

  /// Parameters:
  /// 0: the illegal name
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode illegalPatternVariableName =
      DiagnosticCodeWithExpectedTypes(
        name: 'ILLEGAL_PATTERN_VARIABLE_NAME',
        problemMessage:
            "The variable declared by a variable pattern can't be named '{0}'.",
        correctionMessage: "Choose a different name.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.ILLEGAL_PATTERN_VARIABLE_NAME',
        expectedTypes: [ExpectedType.token],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments implementsBeforeExtends =
      DiagnosticWithoutArgumentsImpl(
        name: 'IMPLEMENTS_BEFORE_EXTENDS',
        problemMessage:
            "The extends clause must be before the implements clause.",
        correctionMessage:
            "Try moving the extends clause before the implements clause.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments implementsBeforeOn =
      DiagnosticWithoutArgumentsImpl(
        name: 'IMPLEMENTS_BEFORE_ON',
        problemMessage: "The on clause must be before the implements clause.",
        correctionMessage:
            "Try moving the on clause before the implements clause.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.IMPLEMENTS_BEFORE_ON',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments implementsBeforeWith =
      DiagnosticWithoutArgumentsImpl(
        name: 'IMPLEMENTS_BEFORE_WITH',
        problemMessage: "The with clause must be before the implements clause.",
        correctionMessage:
            "Try moving the with clause before the implements clause.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.IMPLEMENTS_BEFORE_WITH',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments importDirectiveAfterPartDirective =
      DiagnosticWithoutArgumentsImpl(
        name: 'IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
        problemMessage: "Import directives must precede part directives.",
        correctionMessage:
            "Try moving the import directives before the part directives.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments initializedVariableInForEach =
      DiagnosticWithoutArgumentsImpl(
        name: 'INITIALIZED_VARIABLE_IN_FOR_EACH',
        problemMessage:
            "The loop variable in a for-each loop can't be initialized.",
        correctionMessage:
            "Try removing the initializer, or using a different kind of loop.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments interfaceEnum =
      DiagnosticWithoutArgumentsImpl(
        name: 'INTERFACE_ENUM',
        problemMessage: "Enums can't be declared to be 'interface'.",
        correctionMessage: "Try removing the keyword 'interface'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INTERFACE_ENUM',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments interfaceMixin =
      DiagnosticWithoutArgumentsImpl(
        name: 'INTERFACE_MIXIN',
        problemMessage: "A mixin can't be declared 'interface'.",
        correctionMessage: "Try removing the 'interface' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INTERFACE_MIXIN',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments interfaceMixinClass =
      DiagnosticWithoutArgumentsImpl(
        name: 'INTERFACE_MIXIN_CLASS',
        problemMessage: "A mixin class can't be declared 'interface'.",
        correctionMessage: "Try removing the 'interface' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INTERFACE_MIXIN_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments invalidAwaitInFor =
      DiagnosticWithoutArgumentsImpl(
        name: 'INVALID_AWAIT_IN_FOR',
        problemMessage:
            "The keyword 'await' isn't allowed for a normal 'for' statement.",
        correctionMessage:
            "Try removing the keyword, or use a for-each statement.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INVALID_AWAIT_IN_FOR',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the invalid escape sequence
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidCodePoint = DiagnosticWithArguments(
    name: 'INVALID_CODE_POINT',
    problemMessage: "The escape sequence '{0}' isn't a valid code point.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_CODE_POINT',
    withArguments: _withArgumentsInvalidCodePoint,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidCommentReference = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_COMMENT_REFERENCE',
    problemMessage:
        "Comment references should contain a possibly prefixed identifier and can "
        "start with 'new', but shouldn't contain anything else.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_COMMENT_REFERENCE',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidConstantConstPrefix = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_CONSTANT_CONST_PREFIX',
    problemMessage:
        "The expression can't be prefixed by 'const' to form a constant pattern.",
    correctionMessage:
        "Try wrapping the expression in 'const ( ... )' instead.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_CONSTANT_CONST_PREFIX',
    expectedTypes: [],
  );

  /// Parameters:
  /// Name name: undocumented
  static const DiagnosticCode invalidConstantPatternBinary =
      DiagnosticCodeWithExpectedTypes(
        name: 'INVALID_CONSTANT_PATTERN_BINARY',
        problemMessage:
            "The binary operator {0} is not supported as a constant pattern.",
        correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_BINARY',
        expectedTypes: [ExpectedType.name],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments invalidConstantPatternDuplicateConst =
      DiagnosticWithoutArgumentsImpl(
        name: 'INVALID_CONSTANT_PATTERN_DUPLICATE_CONST',
        problemMessage: "Duplicate 'const' keyword in constant expression.",
        correctionMessage: "Try removing one of the 'const' keywords.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidConstantPatternEmptyRecordLiteral = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_CONSTANT_PATTERN_EMPTY_RECORD_LITERAL',
    problemMessage:
        "The empty record literal is not supported as a constant pattern.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_EMPTY_RECORD_LITERAL',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments invalidConstantPatternGeneric =
      DiagnosticWithoutArgumentsImpl(
        name: 'INVALID_CONSTANT_PATTERN_GENERIC',
        problemMessage:
            "This expression is not supported as a constant pattern.",
        correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_GENERIC',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidConstantPatternNegation = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_CONSTANT_PATTERN_NEGATION',
    problemMessage:
        "Only negation of a numeric literal is supported as a constant pattern.",
    correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_NEGATION',
    expectedTypes: [],
  );

  /// Parameters:
  /// Name name: undocumented
  static const DiagnosticCode invalidConstantPatternUnary =
      DiagnosticCodeWithExpectedTypes(
        name: 'INVALID_CONSTANT_PATTERN_UNARY',
        problemMessage:
            "The unary operator {0} is not supported as a constant pattern.",
        correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_UNARY',
        expectedTypes: [ExpectedType.name],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidConstructorName = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_CONSTRUCTOR_NAME',
    problemMessage:
        "The name of a constructor must match the name of the enclosing class.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_CONSTRUCTOR_NAME',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidGenericFunctionType = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_GENERIC_FUNCTION_TYPE',
    problemMessage: "Invalid generic function type.",
    correctionMessage:
        "Try using a generic function type (returnType 'Function(' parameters "
        "')').",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidHexEscape = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_HEX_ESCAPE',
    problemMessage:
        "An escape sequence starting with '\\x' must be followed by 2 hexadecimal "
        "digits.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_HEX_ESCAPE',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments invalidInitializer =
      DiagnosticWithoutArgumentsImpl(
        name: 'INVALID_INITIALIZER',
        problemMessage: "Not a valid initializer.",
        correctionMessage:
            "To initialize a field, use the syntax 'name = value'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INVALID_INITIALIZER',
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidInsideUnaryPattern = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_INSIDE_UNARY_PATTERN',
    problemMessage:
        "This pattern cannot appear inside a unary pattern (cast pattern, null "
        "check pattern, or null assert pattern) without parentheses.",
    correctionMessage:
        "Try combining into a single pattern if possible, or enclose the inner "
        "pattern in parentheses.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments invalidLiteralInConfiguration =
      DiagnosticWithoutArgumentsImpl(
        name: 'INVALID_LITERAL_IN_CONFIGURATION',
        problemMessage:
            "The literal in a configuration can't contain interpolation.",
        correctionMessage: "Try removing the interpolation expressions.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INVALID_LITERAL_IN_CONFIGURATION',
        expectedTypes: [],
      );

  /// Parameters:
  /// 0: the operator that is invalid
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode invalidOperator = DiagnosticCodeWithExpectedTypes(
    name: 'INVALID_OPERATOR',
    problemMessage: "The string '{0}' isn't a user-definable operator.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_OPERATOR',
    expectedTypes: [ExpectedType.token],
  );

  /// Only generated by the old parser.
  /// Replaced by INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER.
  ///
  /// Parameters:
  /// Object p0: the operator being applied to 'super'
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidOperatorForSuper = DiagnosticWithArguments(
    name: 'INVALID_OPERATOR_FOR_SUPER',
    problemMessage: "The operator '{0}' can't be used with 'super'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_OPERATOR_FOR_SUPER',
    withArguments: _withArgumentsInvalidOperatorForSuper,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidOperatorQuestionmarkPeriodForSuper = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER',
    problemMessage:
        "The operator '?.' cannot be used with 'super' because 'super' cannot be "
        "null.",
    correctionMessage: "Try replacing '?.' with '.'",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName:
        'ParserErrorCode.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidStarAfterAsync = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_STAR_AFTER_ASYNC',
    problemMessage:
        "The modifier 'async*' isn't allowed for an expression function body.",
    correctionMessage: "Try converting the body to a block.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_STAR_AFTER_ASYNC',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments invalidSuperInInitializer =
      DiagnosticWithoutArgumentsImpl(
        name: 'INVALID_SUPER_IN_INITIALIZER',
        problemMessage:
            "Can only use 'super' in an initializer for calling the superclass "
            "constructor (e.g. 'super()' or 'super.namedConstructor()')",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INVALID_SUPER_IN_INITIALIZER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidSync = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_SYNC',
    problemMessage:
        "The modifier 'sync' isn't allowed for an expression function body.",
    correctionMessage: "Try converting the body to a block.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_SYNC',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidThisInInitializer = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_THIS_IN_INITIALIZER',
    problemMessage:
        "Can only use 'this' in an initializer for field initialization (e.g. "
        "'this.x = something') and constructor redirection (e.g. 'this()' or "
        "'this.namedConstructor())",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_THIS_IN_INITIALIZER',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments invalidUnicodeEscapeStarted =
      DiagnosticWithoutArgumentsImpl(
        name: 'INVALID_UNICODE_ESCAPE_STARTED',
        problemMessage: "The string '\\' can't stand alone.",
        correctionMessage:
            "Try adding another backslash (\\) to escape the '\\'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INVALID_UNICODE_ESCAPE_STARTED',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidUnicodeEscapeUBracket = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_UNICODE_ESCAPE_U_BRACKET',
    problemMessage:
        "An escape sequence starting with '\\u{' must be followed by 1 to 6 "
        "hexadecimal digits followed by a '}'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_UNICODE_ESCAPE_U_BRACKET',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidUnicodeEscapeUNoBracket = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_UNICODE_ESCAPE_U_NO_BRACKET',
    problemMessage:
        "An escape sequence starting with '\\u' must be followed by 4 hexadecimal "
        "digits.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_UNICODE_ESCAPE_U_NO_BRACKET',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidUnicodeEscapeUStarted = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_UNICODE_ESCAPE_U_STARTED',
    problemMessage:
        "An escape sequence starting with '\\u' must be followed by 4 hexadecimal "
        "digits or from 1 to 6 digits between '{' and '}'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_UNICODE_ESCAPE_U_STARTED',
    expectedTypes: [],
  );

  /// No parameters.
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const DiagnosticCode invalidUseOfCovariantInExtension =
      DiagnosticCodeWithExpectedTypes(
        name: 'INVALID_USE_OF_COVARIANT_IN_EXTENSION',
        problemMessage: "Can't have modifier '{0}' in an extension.",
        correctionMessage: "Try removing '{0}'.",
        hasPublishedDocs: true,
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.INVALID_USE_OF_COVARIANT_IN_EXTENSION',
        expectedTypes: [ExpectedType.token],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidUseOfIdentifierAugmented = DiagnosticWithoutArgumentsImpl(
    name: 'INVALID_USE_OF_IDENTIFIER_AUGMENTED',
    problemMessage:
        "The identifier 'augmented' can only be used to reference the augmented "
        "declaration inside an augmentation.",
    correctionMessage: "Try using a different identifier.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.INVALID_USE_OF_IDENTIFIER_AUGMENTED',
    expectedTypes: [],
  );

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments latePatternVariableDeclaration =
      DiagnosticWithoutArgumentsImpl(
        name: 'LATE_PATTERN_VARIABLE_DECLARATION',
        problemMessage:
            "A pattern variable declaration may not use the `late` keyword.",
        correctionMessage: "Try removing the keyword `late`.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.LATE_PATTERN_VARIABLE_DECLARATION',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments libraryDirectiveNotFirst =
      DiagnosticWithoutArgumentsImpl(
        name: 'LIBRARY_DIRECTIVE_NOT_FIRST',
        problemMessage:
            "The library directive must appear before all other directives.",
        correctionMessage:
            "Try moving the library directive before any other directives.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST',
        expectedTypes: [],
      );

  /// Parameters:
  /// String string: undocumented
  /// Token lexeme: undocumented
  static const DiagnosticCode literalWithClass =
      DiagnosticCodeWithExpectedTypes(
        name: 'LITERAL_WITH_CLASS',
        problemMessage: "A {0} literal can't be prefixed by '{1}'.",
        correctionMessage: "Try removing '{1}'",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.LITERAL_WITH_CLASS',
        expectedTypes: [ExpectedType.string, ExpectedType.token],
      );

  /// Parameters:
  /// String string: undocumented
  /// Token lexeme: undocumented
  static const DiagnosticCode literalWithClassAndNew =
      DiagnosticCodeWithExpectedTypes(
        name: 'LITERAL_WITH_CLASS_AND_NEW',
        problemMessage: "A {0} literal can't be prefixed by 'new {1}'.",
        correctionMessage: "Try removing 'new' and '{1}'",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.LITERAL_WITH_CLASS_AND_NEW',
        expectedTypes: [ExpectedType.string, ExpectedType.token],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments literalWithNew =
      DiagnosticWithoutArgumentsImpl(
        name: 'LITERAL_WITH_NEW',
        problemMessage: "A literal can't be prefixed by 'new'.",
        correctionMessage: "Try removing 'new'",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.LITERAL_WITH_NEW',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments localFunctionDeclarationModifier =
      DiagnosticWithoutArgumentsImpl(
        name: 'LOCAL_FUNCTION_DECLARATION_MODIFIER',
        problemMessage:
            "Local function declarations can't specify any modifiers.",
        correctionMessage: "Try removing the modifier.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments memberWithClassName =
      DiagnosticWithoutArgumentsImpl(
        name: 'MEMBER_WITH_CLASS_NAME',
        problemMessage:
            "A class member can't have the same name as the enclosing class.",
        correctionMessage: "Try renaming the member.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MEMBER_WITH_CLASS_NAME',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingAssignableSelector =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_ASSIGNABLE_SELECTOR',
        problemMessage: "Missing selector such as '.identifier' or '[0]'.",
        correctionMessage: "Try adding a selector.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingAssignmentInInitializer =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_ASSIGNMENT_IN_INITIALIZER',
        problemMessage: "Expected an assignment after the field name.",
        correctionMessage:
            "To initialize a field, use the syntax 'name = value'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingCatchOrFinally = DiagnosticWithoutArgumentsImpl(
    name: 'MISSING_CATCH_OR_FINALLY',
    problemMessage:
        "A try block must be followed by an 'on', 'catch', or 'finally' clause.",
    correctionMessage:
        "Try adding either a catch or finally clause, or remove the try "
        "statement.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MISSING_CATCH_OR_FINALLY',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments missingClosingParenthesis =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_CLOSING_PARENTHESIS',
        problemMessage: "The closing parenthesis is missing.",
        correctionMessage: "Try adding the closing parenthesis.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_CLOSING_PARENTHESIS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingConstFinalVarOrType = DiagnosticWithoutArgumentsImpl(
    name: 'MISSING_CONST_FINAL_VAR_OR_TYPE',
    problemMessage:
        "Variables must be declared using the keywords 'const', 'final', 'var' or "
        "a type name.",
    correctionMessage:
        "Try adding the name of the type of the variable or the keyword 'var'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingEnumBody = DiagnosticWithoutArgumentsImpl(
    name: 'MISSING_ENUM_BODY',
    problemMessage:
        "An enum definition must have a body with at least one constant name.",
    correctionMessage: "Try adding a body and defining at least one constant.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MISSING_ENUM_BODY',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments missingExpressionInInitializer =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_EXPRESSION_IN_INITIALIZER',
        problemMessage: "Expected an expression after the assignment operator.",
        correctionMessage:
            "Try adding the value to be assigned, or remove the assignment "
            "operator.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_EXPRESSION_IN_INITIALIZER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingExpressionInThrow = DiagnosticWithoutArgumentsImpl(
    name: 'MISSING_EXPRESSION_IN_THROW',
    problemMessage: "Missing expression after 'throw'.",
    correctionMessage:
        "Add an expression after 'throw' or use 'rethrow' to throw a caught "
        "exception",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MISSING_EXPRESSION_IN_THROW',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments missingFunctionBody =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_FUNCTION_BODY',
        problemMessage: "A function body must be provided.",
        correctionMessage: "Try adding a function body.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_FUNCTION_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingFunctionKeyword = DiagnosticWithoutArgumentsImpl(
    name: 'MISSING_FUNCTION_KEYWORD',
    problemMessage:
        "Function types must have the keyword 'Function' before the parameter "
        "list.",
    correctionMessage: "Try adding the keyword 'Function'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MISSING_FUNCTION_KEYWORD',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments missingFunctionParameters =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_FUNCTION_PARAMETERS',
        problemMessage: "Functions must have an explicit list of parameters.",
        correctionMessage: "Try adding a parameter list.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_FUNCTION_PARAMETERS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingGet =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_GET',
        problemMessage:
            "Getters must have the keyword 'get' before the getter name.",
        correctionMessage: "Try adding the keyword 'get'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_GET',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingIdentifier =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_IDENTIFIER',
        problemMessage: "Expected an identifier.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_IDENTIFIER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingInitializer =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_INITIALIZER',
        problemMessage: "Expected an initializer.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_INITIALIZER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingKeywordOperator =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_KEYWORD_OPERATOR',
        problemMessage:
            "Operator declarations must be preceded by the keyword 'operator'.",
        correctionMessage: "Try adding the keyword 'operator'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_KEYWORD_OPERATOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingMethodParameters =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_METHOD_PARAMETERS',
        problemMessage: "Methods must have an explicit list of parameters.",
        correctionMessage: "Try adding a parameter list.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_METHOD_PARAMETERS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingNameForNamedParameter = DiagnosticWithoutArgumentsImpl(
    name: 'MISSING_NAME_FOR_NAMED_PARAMETER',
    problemMessage: "Named parameters in a function type must have a name",
    correctionMessage:
        "Try providing a name for the parameter or removing the curly braces.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingNameInLibraryDirective = DiagnosticWithoutArgumentsImpl(
    name: 'MISSING_NAME_IN_LIBRARY_DIRECTIVE',
    problemMessage: "Library directives must include a library name.",
    correctionMessage:
        "Try adding a library name after the keyword 'library', or remove the "
        "library directive if the library doesn't have any parts.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments missingNameInPartOfDirective =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_NAME_IN_PART_OF_DIRECTIVE',
        problemMessage: "Part-of directives must include a library name.",
        correctionMessage: "Try adding a library name after the 'of'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingPrefixInDeferredImport =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_PREFIX_IN_DEFERRED_IMPORT',
        problemMessage: "Deferred imports should have a prefix.",
        correctionMessage:
            "Try adding a prefix to the import by adding an 'as' clause.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingPrimaryConstructor = DiagnosticWithoutArgumentsImpl(
    name: 'MISSING_PRIMARY_CONSTRUCTOR',
    problemMessage:
        "An extension type declaration must have a primary constructor "
        "declaration.",
    correctionMessage:
        "Try adding a primary constructor to the extension type declaration.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MISSING_PRIMARY_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments missingPrimaryConstructorParameters =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_PRIMARY_CONSTRUCTOR_PARAMETERS',
        problemMessage:
            "A primary constructor declaration must have formal parameters.",
        correctionMessage:
            "Try adding formal parameters after the primary constructor name.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_PRIMARY_CONSTRUCTOR_PARAMETERS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingStarAfterSync =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_STAR_AFTER_SYNC',
        problemMessage: "The modifier 'sync' must be followed by a star ('*').",
        correctionMessage: "Try removing the modifier, or add a star.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_STAR_AFTER_SYNC',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingStatement =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_STATEMENT',
        problemMessage: "Expected a statement.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_STATEMENT',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the terminator that is missing
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  missingTerminatorForParameterGroup = DiagnosticWithArguments(
    name: 'MISSING_TERMINATOR_FOR_PARAMETER_GROUP',
    problemMessage: "There is no '{0}' to close the parameter group.",
    correctionMessage: "Try inserting a '{0}' at the end of the group.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP',
    withArguments: _withArgumentsMissingTerminatorForParameterGroup,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments missingTypedefParameters =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_TYPEDEF_PARAMETERS',
        problemMessage: "Typedefs must have an explicit list of parameters.",
        correctionMessage: "Try adding a parameter list.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MISSING_TYPEDEF_PARAMETERS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingVariableInForEach = DiagnosticWithoutArgumentsImpl(
    name: 'MISSING_VARIABLE_IN_FOR_EACH',
    problemMessage:
        "A loop variable must be declared in a for-each loop before the 'in', but "
        "none was found.",
    correctionMessage: "Try declaring a loop variable.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  mixedParameterGroups = DiagnosticWithoutArgumentsImpl(
    name: 'MIXED_PARAMETER_GROUPS',
    problemMessage:
        "Can't have both positional and named parameters in a single parameter "
        "list.",
    correctionMessage: "Try choosing a single style of optional parameters.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MIXED_PARAMETER_GROUPS',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments mixinDeclaresConstructor =
      DiagnosticWithoutArgumentsImpl(
        name: 'MIXIN_DECLARES_CONSTRUCTOR',
        problemMessage: "Mixins can't declare constructors.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments mixinWithClause =
      DiagnosticWithoutArgumentsImpl(
        name: 'MIXIN_WITH_CLAUSE',
        problemMessage: "A mixin can't have a with clause.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MIXIN_WITH_CLAUSE',
        expectedTypes: [],
      );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  modifierOutOfOrder = DiagnosticWithArguments(
    name: 'MODIFIER_OUT_OF_ORDER',
    problemMessage: "The modifier '{0}' should be before the modifier '{1}'.",
    correctionMessage: "Try re-ordering the modifiers.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MODIFIER_OUT_OF_ORDER',
    withArguments: _withArgumentsModifierOutOfOrder,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  multipleClauses = DiagnosticWithArguments(
    name: 'MULTIPLE_CLAUSES',
    problemMessage: "Each '{0}' definition can have at most one '{1}' clause.",
    correctionMessage:
        "Try combining all of the '{1}' clauses into a single clause.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MULTIPLE_CLAUSES',
    withArguments: _withArgumentsMultipleClauses,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  multipleExtendsClauses = DiagnosticWithoutArgumentsImpl(
    name: 'MULTIPLE_EXTENDS_CLAUSES',
    problemMessage:
        "Each class definition can have at most one extends clause.",
    correctionMessage:
        "Try choosing one superclass and define your class to implement (or "
        "mix in) the others.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  multipleImplementsClauses = DiagnosticWithoutArgumentsImpl(
    name: 'MULTIPLE_IMPLEMENTS_CLAUSES',
    problemMessage:
        "Each class or mixin definition can have at most one implements clause.",
    correctionMessage:
        "Try combining all of the implements clauses into a single clause.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments multipleLibraryDirectives =
      DiagnosticWithoutArgumentsImpl(
        name: 'MULTIPLE_LIBRARY_DIRECTIVES',
        problemMessage: "Only one library directive may be declared in a file.",
        correctionMessage:
            "Try removing all but one of the library directives.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  multipleNamedParameterGroups = DiagnosticWithoutArgumentsImpl(
    name: 'MULTIPLE_NAMED_PARAMETER_GROUPS',
    problemMessage:
        "Can't have multiple groups of named parameters in a single parameter "
        "list.",
    correctionMessage: "Try combining all of the groups into a single group.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments multipleOnClauses =
      DiagnosticWithoutArgumentsImpl(
        name: 'MULTIPLE_ON_CLAUSES',
        problemMessage: "Each mixin definition can have at most one on clause.",
        correctionMessage:
            "Try combining all of the on clauses into a single clause.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MULTIPLE_ON_CLAUSES',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments multiplePartOfDirectives =
      DiagnosticWithoutArgumentsImpl(
        name: 'MULTIPLE_PART_OF_DIRECTIVES',
        problemMessage: "Only one part-of directive may be declared in a file.",
        correctionMessage:
            "Try removing all but one of the part-of directives.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  multiplePositionalParameterGroups = DiagnosticWithoutArgumentsImpl(
    name: 'MULTIPLE_POSITIONAL_PARAMETER_GROUPS',
    problemMessage:
        "Can't have multiple groups of positional parameters in a single parameter "
        "list.",
    correctionMessage: "Try combining all of the groups into a single group.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments multipleRepresentationFields =
      DiagnosticWithoutArgumentsImpl(
        name: 'MULTIPLE_REPRESENTATION_FIELDS',
        problemMessage:
            "Each extension type should have exactly one representation field.",
        correctionMessage:
            "Try combining fields into a record, or removing extra fields.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MULTIPLE_REPRESENTATION_FIELDS',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the number of variables being declared
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  multipleVariablesInForEach = DiagnosticWithArguments(
    name: 'MULTIPLE_VARIABLES_IN_FOR_EACH',
    problemMessage:
        "A single loop variable must be declared in a for-each loop before the "
        "'in', but {0} were found.",
    correctionMessage:
        "Try moving all but one of the declarations inside the loop body.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH',
    withArguments: _withArgumentsMultipleVariablesInForEach,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments multipleVarianceModifiers =
      DiagnosticWithoutArgumentsImpl(
        name: 'MULTIPLE_VARIANCE_MODIFIERS',
        problemMessage:
            "Each type parameter can have at most one variance modifier.",
        correctionMessage:
            "Use at most one of the 'in', 'out', or 'inout' modifiers.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MULTIPLE_VARIANCE_MODIFIERS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments multipleWithClauses =
      DiagnosticWithoutArgumentsImpl(
        name: 'MULTIPLE_WITH_CLAUSES',
        problemMessage:
            "Each class definition can have at most one with clause.",
        correctionMessage:
            "Try combining all of the with clauses into a single clause.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.MULTIPLE_WITH_CLAUSES',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments namedFunctionExpression =
      DiagnosticWithoutArgumentsImpl(
        name: 'NAMED_FUNCTION_EXPRESSION',
        problemMessage: "Function expressions can't be named.",
        correctionMessage:
            "Try removing the name, or moving the function expression to a "
            "function declaration statement.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.NAMED_FUNCTION_EXPRESSION',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments namedFunctionType =
      DiagnosticWithoutArgumentsImpl(
        name: 'NAMED_FUNCTION_TYPE',
        problemMessage: "Function types can't be named.",
        correctionMessage:
            "Try replacing the name with the keyword 'Function'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.NAMED_FUNCTION_TYPE',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments namedParameterOutsideGroup =
      DiagnosticWithoutArgumentsImpl(
        name: 'NAMED_PARAMETER_OUTSIDE_GROUP',
        problemMessage:
            "Named parameters must be enclosed in curly braces ('{' and '}').",
        correctionMessage:
            "Try surrounding the named parameters in curly braces.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  nativeClauseInNonSdkCode = DiagnosticWithoutArgumentsImpl(
    name: 'NATIVE_CLAUSE_IN_NON_SDK_CODE',
    problemMessage:
        "Native clause can only be used in the SDK and code that is loaded through "
        "native extensions.",
    correctionMessage: "Try removing the native clause.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments nativeClauseShouldBeAnnotation =
      DiagnosticWithoutArgumentsImpl(
        name: 'NATIVE_CLAUSE_SHOULD_BE_ANNOTATION',
        problemMessage: "Native clause in this form is deprecated.",
        correctionMessage:
            "Try removing this native clause and adding @native() or "
            "@native('native-name') before the declaration.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  nativeFunctionBodyInNonSdkCode = DiagnosticWithoutArgumentsImpl(
    name: 'NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE',
    problemMessage:
        "Native functions can only be declared in the SDK and code that is loaded "
        "through native extensions.",
    correctionMessage: "Try removing the word 'native'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments nonConstructorFactory =
      DiagnosticWithoutArgumentsImpl(
        name: 'NON_CONSTRUCTOR_FACTORY',
        problemMessage: "Only a constructor can be declared to be a factory.",
        correctionMessage: "Try removing the keyword 'factory'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.NON_CONSTRUCTOR_FACTORY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments nonIdentifierLibraryName =
      DiagnosticWithoutArgumentsImpl(
        name: 'NON_IDENTIFIER_LIBRARY_NAME',
        problemMessage: "The name of a library must be an identifier.",
        correctionMessage:
            "Try using an identifier as the name of the library.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  nonPartOfDirectiveInPart = DiagnosticWithoutArgumentsImpl(
    name: 'NON_PART_OF_DIRECTIVE_IN_PART',
    problemMessage:
        "The part-of directive must be the only directive in a part.",
    correctionMessage:
        "Try removing the other directives, or moving them to the library for "
        "which this is a part.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments nonStringLiteralAsUri =
      DiagnosticWithoutArgumentsImpl(
        name: 'NON_STRING_LITERAL_AS_URI',
        problemMessage: "The URI must be a string literal.",
        correctionMessage:
            "Try enclosing the URI in either single or double quotes.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.NON_STRING_LITERAL_AS_URI',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the operator that the user is trying to define
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  nonUserDefinableOperator = DiagnosticWithArguments(
    name: 'NON_USER_DEFINABLE_OPERATOR',
    problemMessage: "The operator '{0}' isn't user definable.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.NON_USER_DEFINABLE_OPERATOR',
    withArguments: _withArgumentsNonUserDefinableOperator,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments normalBeforeOptionalParameters =
      DiagnosticWithoutArgumentsImpl(
        name: 'NORMAL_BEFORE_OPTIONAL_PARAMETERS',
        problemMessage:
            "Normal parameters must occur before optional parameters.",
        correctionMessage:
            "Try moving all of the normal parameters before the optional "
            "parameters.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  nullAwareCascadeOutOfOrder = DiagnosticWithoutArgumentsImpl(
    name: 'NULL_AWARE_CASCADE_OUT_OF_ORDER',
    problemMessage:
        "The '?..' cascade operator must be first in the cascade sequence.",
    correctionMessage:
        "Try moving the '?..' operator to be the first cascade operator in the "
        "sequence.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.NULL_AWARE_CASCADE_OUT_OF_ORDER',
    expectedTypes: [],
  );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  outOfOrderClauses = DiagnosticWithArguments(
    name: 'OUT_OF_ORDER_CLAUSES',
    problemMessage: "The '{0}' clause must come before the '{1}' clause.",
    correctionMessage: "Try moving the '{0}' clause before the '{1}' clause.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.OUT_OF_ORDER_CLAUSES',
    withArguments: _withArgumentsOutOfOrderClauses,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  partOfName = DiagnosticWithoutArgumentsImpl(
    name: 'PART_OF_NAME',
    problemMessage:
        "The 'part of' directive can't use a name with the enhanced-parts feature.",
    correctionMessage: "Try using 'part of' with a URI instead.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.PART_OF_NAME',
    expectedTypes: [],
  );

  /// Parameters:
  /// Name name: undocumented
  static const DiagnosticCode patternAssignmentDeclaresVariable =
      DiagnosticCodeWithExpectedTypes(
        name: 'PATTERN_ASSIGNMENT_DECLARES_VARIABLE',
        problemMessage:
            "Variable '{0}' can't be declared in a pattern assignment.",
        correctionMessage:
            "Try using a preexisting variable or changing the assignment to a "
            "pattern variable declaration.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE',
        expectedTypes: [ExpectedType.name],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments
  patternVariableDeclarationOutsideFunctionOrMethod = DiagnosticWithoutArgumentsImpl(
    name: 'PATTERN_VARIABLE_DECLARATION_OUTSIDE_FUNCTION_OR_METHOD',
    problemMessage:
        "A pattern variable declaration may not appear outside a function or "
        "method.",
    correctionMessage:
        "Try declaring ordinary variables and assigning from within a function "
        "or method.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName:
        'ParserErrorCode.PATTERN_VARIABLE_DECLARATION_OUTSIDE_FUNCTION_OR_METHOD',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments positionalAfterNamedArgument =
      DiagnosticWithoutArgumentsImpl(
        name: 'POSITIONAL_AFTER_NAMED_ARGUMENT',
        problemMessage:
            "Positional arguments must occur before named arguments.",
        correctionMessage:
            "Try moving all of the positional arguments before the named "
            "arguments.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  positionalParameterOutsideGroup = DiagnosticWithoutArgumentsImpl(
    name: 'POSITIONAL_PARAMETER_OUTSIDE_GROUP',
    problemMessage:
        "Positional parameters must be enclosed in square brackets ('[' and ']').",
    correctionMessage:
        "Try surrounding the positional parameters in square brackets.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  prefixAfterCombinator = DiagnosticWithoutArgumentsImpl(
    name: 'PREFIX_AFTER_COMBINATOR',
    problemMessage:
        "The prefix ('as' clause) should come before any show/hide combinators.",
    correctionMessage: "Try moving the prefix before the combinators.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.PREFIX_AFTER_COMBINATOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  privateNamedNonFieldParameter = DiagnosticWithoutArgumentsImpl(
    name: 'PRIVATE_NAMED_NON_FIELD_PARAMETER',
    problemMessage:
        "Named parameters that don't refer to instance variables can't start with "
        "underscore.",
    hasPublishedDocs: true,
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.PRIVATE_NAMED_NON_FIELD_PARAMETER',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments privateOptionalParameter =
      DiagnosticWithoutArgumentsImpl(
        name: 'PRIVATE_OPTIONAL_PARAMETER',
        problemMessage: "Named parameters can't start with an underscore.",
        hasPublishedDocs: true,
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.PRIVATE_OPTIONAL_PARAMETER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  recordLiteralOnePositionalNoTrailingComma = DiagnosticWithoutArgumentsImpl(
    name: 'RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA',
    problemMessage:
        "A record literal with exactly one positional field requires a trailing "
        "comma.",
    correctionMessage: "Try adding a trailing comma.",
    hasPublishedDocs: true,
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName:
        'ParserErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  recordTypeOnePositionalNoTrailingComma = DiagnosticWithoutArgumentsImpl(
    name: 'RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA',
    problemMessage:
        "A record type with exactly one positional field requires a trailing "
        "comma.",
    correctionMessage: "Try adding a trailing comma.",
    hasPublishedDocs: true,
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  redirectingConstructorWithBody = DiagnosticWithoutArgumentsImpl(
    name: 'REDIRECTING_CONSTRUCTOR_WITH_BODY',
    problemMessage: "Redirecting constructors can't have a body.",
    correctionMessage:
        "Try removing the body, or not making this a redirecting constructor.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments redirectionInNonFactoryConstructor =
      DiagnosticWithoutArgumentsImpl(
        name: 'REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR',
        problemMessage: "Only factory constructor can specify '=' redirection.",
        correctionMessage:
            "Try making this a factory constructor, or remove the redirection.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments representationFieldModifier =
      DiagnosticWithoutArgumentsImpl(
        name: 'REPRESENTATION_FIELD_MODIFIER',
        problemMessage: "Representation fields can't have modifiers.",
        correctionMessage: "Try removing the modifier.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.REPRESENTATION_FIELD_MODIFIER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments representationFieldTrailingComma =
      DiagnosticWithoutArgumentsImpl(
        name: 'REPRESENTATION_FIELD_TRAILING_COMMA',
        problemMessage: "The representation field can't have a trailing comma.",
        correctionMessage: "Try removing the trailing comma.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.REPRESENTATION_FIELD_TRAILING_COMMA',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments sealedEnum =
      DiagnosticWithoutArgumentsImpl(
        name: 'SEALED_ENUM',
        problemMessage: "Enums can't be declared to be 'sealed'.",
        correctionMessage: "Try removing the keyword 'sealed'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.SEALED_ENUM',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments sealedMixin =
      DiagnosticWithoutArgumentsImpl(
        name: 'SEALED_MIXIN',
        problemMessage: "A mixin can't be declared 'sealed'.",
        correctionMessage: "Try removing the 'sealed' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.SEALED_MIXIN',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments sealedMixinClass =
      DiagnosticWithoutArgumentsImpl(
        name: 'SEALED_MIXIN_CLASS',
        problemMessage: "A mixin class can't be declared 'sealed'.",
        correctionMessage: "Try removing the 'sealed' keyword.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.SEALED_MIXIN_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments setterConstructor =
      DiagnosticWithoutArgumentsImpl(
        name: 'SETTER_CONSTRUCTOR',
        problemMessage: "Constructors can't be a setter.",
        correctionMessage: "Try removing 'set'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.SETTER_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments setterInFunction =
      DiagnosticWithoutArgumentsImpl(
        name: 'SETTER_IN_FUNCTION',
        problemMessage: "Setters can't be defined within methods or functions.",
        correctionMessage:
            "Try moving the setter outside the method or function.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.SETTER_IN_FUNCTION',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments stackOverflow =
      DiagnosticWithoutArgumentsImpl(
        name: 'STACK_OVERFLOW',
        problemMessage:
            "The file has too many nested expressions or statements.",
        correctionMessage: "Try simplifying the code.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.STACK_OVERFLOW',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments staticConstructor =
      DiagnosticWithoutArgumentsImpl(
        name: 'STATIC_CONSTRUCTOR',
        problemMessage: "Constructors can't be static.",
        correctionMessage: "Try removing the keyword 'static'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.STATIC_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  staticGetterWithoutBody = DiagnosticWithoutArgumentsImpl(
    name: 'STATIC_GETTER_WITHOUT_BODY',
    problemMessage: "A 'static' getter must have a body.",
    correctionMessage:
        "Try adding a body to the getter, or removing the keyword 'static'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.STATIC_GETTER_WITHOUT_BODY',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments staticOperator =
      DiagnosticWithoutArgumentsImpl(
        name: 'STATIC_OPERATOR',
        problemMessage: "Operators can't be static.",
        correctionMessage: "Try removing the keyword 'static'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.STATIC_OPERATOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  staticSetterWithoutBody = DiagnosticWithoutArgumentsImpl(
    name: 'STATIC_SETTER_WITHOUT_BODY',
    problemMessage: "A 'static' setter must have a body.",
    correctionMessage:
        "Try adding a body to the setter, or removing the keyword 'static'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.STATIC_SETTER_WITHOUT_BODY',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments switchHasCaseAfterDefaultCase =
      DiagnosticWithoutArgumentsImpl(
        name: 'SWITCH_HAS_CASE_AFTER_DEFAULT_CASE',
        problemMessage:
            "The default case should be the last case in a switch statement.",
        correctionMessage:
            "Try moving the default case after the other case clauses.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments switchHasMultipleDefaultCases =
      DiagnosticWithoutArgumentsImpl(
        name: 'SWITCH_HAS_MULTIPLE_DEFAULT_CASES',
        problemMessage: "The 'default' case can only be declared once.",
        correctionMessage: "Try removing all but one default case.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  topLevelOperator = DiagnosticWithoutArgumentsImpl(
    name: 'TOP_LEVEL_OPERATOR',
    problemMessage: "Operators must be declared within a class.",
    correctionMessage:
        "Try removing the operator, moving it to a class, or converting it to "
        "be a function.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.TOP_LEVEL_OPERATOR',
    expectedTypes: [],
  );

  /// Parameters:
  /// Name name: undocumented
  static const DiagnosticCode typeArgumentsOnTypeVariable =
      DiagnosticCodeWithExpectedTypes(
        name: 'TYPE_ARGUMENTS_ON_TYPE_VARIABLE',
        problemMessage: "Can't use type arguments with type variable '{0}'.",
        correctionMessage: "Try removing the type arguments.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.TYPE_ARGUMENTS_ON_TYPE_VARIABLE',
        expectedTypes: [ExpectedType.name],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments typeBeforeFactory =
      DiagnosticWithoutArgumentsImpl(
        name: 'TYPE_BEFORE_FACTORY',
        problemMessage: "Factory constructors cannot have a return type.",
        correctionMessage: "Try removing the type appearing before 'factory'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.TYPE_BEFORE_FACTORY',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments typedefInClass =
      DiagnosticWithoutArgumentsImpl(
        name: 'TYPEDEF_IN_CLASS',
        problemMessage: "Typedefs can't be declared inside classes.",
        correctionMessage: "Try moving the typedef to the top-level.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.TYPEDEF_IN_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments typeParameterOnConstructor =
      DiagnosticWithoutArgumentsImpl(
        name: 'TYPE_PARAMETER_ON_CONSTRUCTOR',
        problemMessage: "Constructors can't have type parameters.",
        correctionMessage: "Try removing the type parameters.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.TYPE_PARAMETER_ON_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// 7.1.1 Operators: Type parameters are not syntactically supported on an
  /// operator.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments typeParameterOnOperator =
      DiagnosticWithoutArgumentsImpl(
        name: 'TYPE_PARAMETER_ON_OPERATOR',
        problemMessage:
            "Types parameters aren't allowed when defining an operator.",
        correctionMessage: "Try removing the type parameters.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.TYPE_PARAMETER_ON_OPERATOR',
        expectedTypes: [],
      );

  @Deprecated("Please use unexpectedToken")
  static const DiagnosticCode UNEXPECTED_TOKEN = unexpectedToken;

  /// Parameters:
  /// Object p0: the starting character that was missing
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unexpectedTerminatorForParameterGroup = DiagnosticWithArguments(
    name: 'UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP',
    problemMessage: "There is no '{0}' to open a parameter group.",
    correctionMessage: "Try inserting the '{0}' at the appropriate location.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP',
    withArguments: _withArgumentsUnexpectedTerminatorForParameterGroup,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the unexpected text that was found
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unexpectedToken = DiagnosticWithArguments(
    name: 'UNEXPECTED_TOKEN',
    problemMessage: "Unexpected text '{0}'.",
    correctionMessage: "Try removing the text.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.UNEXPECTED_TOKEN',
    withArguments: _withArgumentsUnexpectedToken,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments unexpectedTokens =
      DiagnosticWithoutArgumentsImpl(
        name: 'UNEXPECTED_TOKENS',
        problemMessage: "Unexpected tokens.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.UNEXPECTED_TOKENS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments varAndType =
      DiagnosticWithoutArgumentsImpl(
        name: 'VAR_AND_TYPE',
        problemMessage:
            "Variables can't be declared using both 'var' and a type name.",
        correctionMessage: "Try removing 'var.'",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.VAR_AND_TYPE',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments varAsTypeName =
      DiagnosticWithoutArgumentsImpl(
        name: 'VAR_AS_TYPE_NAME',
        problemMessage: "The keyword 'var' can't be used as a type name.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.VAR_AS_TYPE_NAME',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments varClass =
      DiagnosticWithoutArgumentsImpl(
        name: 'VAR_CLASS',
        problemMessage: "Classes can't be declared to be 'var'.",
        correctionMessage: "Try removing the keyword 'var'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.VAR_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments varEnum =
      DiagnosticWithoutArgumentsImpl(
        name: 'VAR_ENUM',
        problemMessage: "Enums can't be declared to be 'var'.",
        correctionMessage: "Try removing the keyword 'var'.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.VAR_ENUM',
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments
  variablePatternKeywordInDeclarationContext = DiagnosticWithoutArgumentsImpl(
    name: 'VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT',
    problemMessage:
        "Variable patterns in declaration context can't specify 'var' or 'final' "
        "keyword.",
    correctionMessage: "Try removing the keyword.",
    hasPublishedDocs: true,
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName:
        'ParserErrorCode.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  varReturnType = DiagnosticWithoutArgumentsImpl(
    name: 'VAR_RETURN_TYPE',
    problemMessage: "The return type can't be 'var'.",
    correctionMessage:
        "Try removing the keyword 'var', or replacing it with the name of the "
        "return type.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.VAR_RETURN_TYPE',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  varTypedef = DiagnosticWithoutArgumentsImpl(
    name: 'VAR_TYPEDEF',
    problemMessage: "Typedefs can't be declared to be 'var'.",
    correctionMessage:
        "Try removing the keyword 'var', or replacing it with the name of the "
        "return type.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.VAR_TYPEDEF',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments voidWithTypeArguments =
      DiagnosticWithoutArgumentsImpl(
        name: 'VOID_WITH_TYPE_ARGUMENTS',
        problemMessage: "Type 'void' can't have type arguments.",
        correctionMessage: "Try removing the type arguments.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.VOID_WITH_TYPE_ARGUMENTS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments withBeforeExtends =
      DiagnosticWithoutArgumentsImpl(
        name: 'WITH_BEFORE_EXTENDS',
        problemMessage: "The extends clause must be before the with clause.",
        correctionMessage:
            "Try moving the extends clause before the with clause.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.WITH_BEFORE_EXTENDS',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments wrongNumberOfParametersForSetter =
      DiagnosticWithoutArgumentsImpl(
        name: 'WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER',
        problemMessage:
            "Setters must declare exactly one required positional parameter.",
        hasPublishedDocs: true,
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ParserErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  wrongSeparatorForPositionalParameter = DiagnosticWithoutArgumentsImpl(
    name: 'WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER',
    problemMessage:
        "The default value of a positional parameter should be preceded by '='.",
    correctionMessage: "Try replacing the ':' with '='.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the terminator that was expected
  /// Object p1: the terminator that was found
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  wrongTerminatorForParameterGroup = DiagnosticWithArguments(
    name: 'WRONG_TERMINATOR_FOR_PARAMETER_GROUP',
    problemMessage: "Expected '{0}' to close parameter group.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP',
    withArguments: _withArgumentsWrongTerminatorForParameterGroup,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Initialize a newly created error code to have the given [name].
  const ParserErrorCode({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.uniqueName,
    required super.expectedTypes,
  }) : super(type: DiagnosticType.SYNTACTIC_ERROR);

  static LocatableDiagnostic _withArgumentsBinaryOperatorWrittenOut({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.binaryOperatorWrittenOut, [
      string,
      string2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsConflictingModifiers({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.conflictingModifiers, [
      string,
      string2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsExpectedInstead({
    required String string,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.expectedInstead, [string]);
  }

  static LocatableDiagnostic _withArgumentsExpectedToken({required String p0}) {
    return LocatableDiagnosticImpl(ParserErrorCode.expectedToken, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExperimentNotEnabled({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.experimentNotEnabled, [
      string,
      string2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsExperimentNotEnabledOffByDefault({
    required String string,
  }) {
    return LocatableDiagnosticImpl(
      ParserErrorCode.experimentNotEnabledOffByDefault,
      [string],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidCodePoint({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.invalidCodePoint, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidOperatorForSuper({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.invalidOperatorForSuper, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMissingTerminatorForParameterGroup({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      ParserErrorCode.missingTerminatorForParameterGroup,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsModifierOutOfOrder({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.modifierOutOfOrder, [
      string,
      string2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMultipleClauses({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.multipleClauses, [
      string,
      string2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMultipleVariablesInForEach({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.multipleVariablesInForEach, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsNonUserDefinableOperator({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.nonUserDefinableOperator, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsOutOfOrderClauses({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.outOfOrderClauses, [
      string,
      string2,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsUnexpectedTerminatorForParameterGroup({required Object p0}) {
    return LocatableDiagnosticImpl(
      ParserErrorCode.unexpectedTerminatorForParameterGroup,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsUnexpectedToken({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(ParserErrorCode.unexpectedToken, [p0]);
  }

  static LocatableDiagnostic _withArgumentsWrongTerminatorForParameterGroup({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      ParserErrorCode.wrongTerminatorForParameterGroup,
      [p0, p1],
    );
  }
}

class ScannerErrorCode extends DiagnosticCodeWithExpectedTypes {
  /// No parameters.
  static const DiagnosticWithoutArguments encoding =
      DiagnosticWithoutArgumentsImpl(
        name: 'ENCODING',
        problemMessage: "Unable to decode bytes as UTF-8.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ScannerErrorCode.ENCODING',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the illegal character
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  illegalCharacter = DiagnosticWithArguments(
    name: 'ILLEGAL_CHARACTER',
    problemMessage: "Illegal character '{0}'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ScannerErrorCode.ILLEGAL_CHARACTER',
    withArguments: _withArgumentsIllegalCharacter,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments missingDigit =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_DIGIT',
        problemMessage: "Decimal digit expected.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ScannerErrorCode.MISSING_DIGIT',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingHexDigit =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_HEX_DIGIT',
        problemMessage: "Hexadecimal digit expected.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ScannerErrorCode.MISSING_HEX_DIGIT',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments missingQuote =
      DiagnosticWithoutArgumentsImpl(
        name: 'MISSING_QUOTE',
        problemMessage: "Expected quote (' or \").",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ScannerErrorCode.MISSING_QUOTE',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the path of the file that cannot be read
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unableGetContent = DiagnosticWithArguments(
    name: 'UNABLE_GET_CONTENT',
    problemMessage: "Unable to get content of '{0}'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ScannerErrorCode.UNABLE_GET_CONTENT',
    withArguments: _withArgumentsUnableGetContent,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  unexpectedDollarInString = DiagnosticWithoutArgumentsImpl(
    name: 'UNEXPECTED_DOLLAR_IN_STRING',
    problemMessage:
        "A '\$' has special meaning inside a string, and must be followed by an "
        "identifier or an expression in curly braces ({}).",
    correctionMessage: "Try adding a backslash (\\) to escape the '\$'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ScannerErrorCode.UNEXPECTED_DOLLAR_IN_STRING',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  unexpectedSeparatorInNumber = DiagnosticWithoutArgumentsImpl(
    name: 'UNEXPECTED_SEPARATOR_IN_NUMBER',
    problemMessage:
        "Digit separators ('_') in a number literal can only be placed between two "
        "digits.",
    correctionMessage: "Try removing the '_'.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ScannerErrorCode.UNEXPECTED_SEPARATOR_IN_NUMBER',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the unsupported operator
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unsupportedOperator = DiagnosticWithArguments(
    name: 'UNSUPPORTED_OPERATOR',
    problemMessage: "The '{0}' operator is not supported.",
    type: DiagnosticType.SYNTACTIC_ERROR,
    uniqueName: 'ScannerErrorCode.UNSUPPORTED_OPERATOR',
    withArguments: _withArgumentsUnsupportedOperator,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments unterminatedMultiLineComment =
      DiagnosticWithoutArgumentsImpl(
        name: 'UNTERMINATED_MULTI_LINE_COMMENT',
        problemMessage: "Unterminated multi-line comment.",
        correctionMessage:
            "Try terminating the comment with '*/', or removing any unbalanced "
            "occurrences of '/*' (because comments nest in Dart).",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unterminatedStringLiteral =
      DiagnosticWithoutArgumentsImpl(
        name: 'UNTERMINATED_STRING_LITERAL',
        problemMessage: "Unterminated string literal.",
        type: DiagnosticType.SYNTACTIC_ERROR,
        uniqueName: 'ScannerErrorCode.UNTERMINATED_STRING_LITERAL',
        expectedTypes: [],
      );

  /// Initialize a newly created error code to have the given [name].
  const ScannerErrorCode({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.uniqueName,
    required super.expectedTypes,
  }) : super(type: DiagnosticType.SYNTACTIC_ERROR);

  static LocatableDiagnostic _withArgumentsIllegalCharacter({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(ScannerErrorCode.illegalCharacter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnableGetContent({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(ScannerErrorCode.unableGetContent, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnsupportedOperator({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(ScannerErrorCode.unsupportedOperator, [p0]);
  }
}
