// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is hard to visually separate each code's _doc comment_ from its published
// _documentation comment_ when each is written as an end-of-line comment.
// ignore_for_file: slash_for_doc_comments

/**
 * The errors produced during syntactic analysis (scanning and parsing).
 */
import 'package:analyzer/error/error.dart';

export 'package:_fe_analyzer_shared/src/scanner/errors.dart'
    show ScannerErrorCode;

part 'syntactic_errors.g.dart';

/**
 * The error codes used for errors detected by the parser. The convention for
 * this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what
 * is wrong and, when appropriate, how the problem can be corrected.
 */
class ParserErrorCode extends ErrorCode {
  static const ParserErrorCode ABSTRACT_CLASS_MEMBER = _ABSTRACT_CLASS_MEMBER;

  static const ParserErrorCode ABSTRACT_ENUM = ParserErrorCode(
      'ABSTRACT_ENUM', "Enums can't be declared to be 'abstract'.",
      correction: "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ABSTRACT_EXTERNAL_FIELD =
      _ABSTRACT_EXTERNAL_FIELD;

  static const ParserErrorCode ABSTRACT_LATE_FIELD = _ABSTRACT_LATE_FIELD;

  static const ParserErrorCode ABSTRACT_STATIC_FIELD = _ABSTRACT_STATIC_FIELD;

  static const ParserErrorCode ABSTRACT_STATIC_METHOD = ParserErrorCode(
      'ABSTRACT_STATIC_METHOD',
      "Static methods can't be declared to be 'abstract'.",
      correction: "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ABSTRACT_TOP_LEVEL_FUNCTION = ParserErrorCode(
      'ABSTRACT_TOP_LEVEL_FUNCTION',
      "Top-level functions can't be declared to be 'abstract'.",
      correction: "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ABSTRACT_TOP_LEVEL_VARIABLE = ParserErrorCode(
      'ABSTRACT_TOP_LEVEL_VARIABLE',
      "Top-level variables can't be declared to be 'abstract'.",
      correction: "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ABSTRACT_TYPEDEF = ParserErrorCode(
      'ABSTRACT_TYPEDEF', "Typedefs can't be declared to be 'abstract'.",
      correction: "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ANNOTATION_ON_TYPE_ARGUMENT =
      _ANNOTATION_ON_TYPE_ARGUMENT;

  static const ParserErrorCode ANNOTATION_WITH_TYPE_ARGUMENTS =
      _ANNOTATION_WITH_TYPE_ARGUMENTS;

  /**
   * 16.32 Identifier Reference: It is a compile-time error if any of the
   * identifiers async, await, or yield is used as an identifier in a function
   * body marked with either async, async*, or sync*.
   */
  static const ParserErrorCode ASYNC_KEYWORD_USED_AS_IDENTIFIER =
      ParserErrorCode(
          'ASYNC_KEYWORD_USED_AS_IDENTIFIER',
          "The keywords 'await' and 'yield' can't be used as "
              "identifiers in an asynchronous or generator function.");

  static const ParserErrorCode BINARY_OPERATOR_WRITTEN_OUT =
      _BINARY_OPERATOR_WRITTEN_OUT;

  static const ParserErrorCode BREAK_OUTSIDE_OF_LOOP = _BREAK_OUTSIDE_OF_LOOP;

  static const ParserErrorCode CATCH_SYNTAX = _CATCH_SYNTAX;

  static const ParserErrorCode CATCH_SYNTAX_EXTRA_PARAMETERS =
      _CATCH_SYNTAX_EXTRA_PARAMETERS;

  static const ParserErrorCode CLASS_IN_CLASS = _CLASS_IN_CLASS;

  static const ParserErrorCode COLON_IN_PLACE_OF_IN = _COLON_IN_PLACE_OF_IN;

  static const ParserErrorCode CONFLICTING_MODIFIERS = _CONFLICTING_MODIFIERS;

  static const ParserErrorCode CONST_AND_FINAL = _CONST_AND_FINAL;

  static const ParserErrorCode CONST_CLASS = _CONST_CLASS;

  static const ParserErrorCode CONST_CONSTRUCTOR_WITH_BODY = ParserErrorCode(
      'CONST_CONSTRUCTOR_WITH_BODY', "Const constructors can't have a body.",
      correction: "Try removing either the 'const' keyword or the body.");

  static const ParserErrorCode CONST_ENUM = ParserErrorCode(
      'CONST_ENUM', "Enums can't be declared to be 'const'.",
      correction: "Try removing the 'const' keyword.");

  static const ParserErrorCode CONST_FACTORY = _CONST_FACTORY;

  static const ParserErrorCode CONST_METHOD = _CONST_METHOD;

  static const ParserErrorCode CONST_TYPEDEF = ParserErrorCode(
      'CONST_TYPEDEF', "Type aliases can't be declared to be 'const'.",
      correction: "Try removing the 'const' keyword.");

  static const ParserErrorCode CONSTRUCTOR_WITH_RETURN_TYPE =
      _CONSTRUCTOR_WITH_RETURN_TYPE;

  static const ParserErrorCode CONTINUE_OUTSIDE_OF_LOOP =
      _CONTINUE_OUTSIDE_OF_LOOP;

  static const ParserErrorCode CONTINUE_WITHOUT_LABEL_IN_CASE =
      _CONTINUE_WITHOUT_LABEL_IN_CASE;

  static const ParserErrorCode COVARIANT_AND_STATIC = _COVARIANT_AND_STATIC;

  static const ParserErrorCode COVARIANT_CONSTRUCTOR = ParserErrorCode(
      'COVARIANT_CONSTRUCTOR',
      "A constructor can't be declared to be 'covariant'.",
      correction: "Try removing the keyword 'covariant'.");

  static const ParserErrorCode COVARIANT_MEMBER = _COVARIANT_MEMBER;

  static const ParserErrorCode COVARIANT_TOP_LEVEL_DECLARATION =
      ParserErrorCode('COVARIANT_TOP_LEVEL_DECLARATION',
          "Top-level declarations can't be declared to be covariant.",
          correction: "Try removing the keyword 'covariant'.");

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a function type associated with
  // a parameter includes optional parameters that have a default value. This
  // isn't allowed because the default values of parameters aren't part of the
  // function's type, and therefore including them doesn't provide any value.
  //
  // #### Example
  //
  // The following code produces this diagnostic because the parameter `p` has a
  // default value even though it's part of the type of the parameter `g`:
  //
  // ```dart
  // void f(void Function([int p [!=!] 0]) g) {
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the default value from the function-type's parameter:
  //
  // ```dart
  // void f(void Function([int p]) g) {
  // }
  // ```
  static const ParserErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPE = ParserErrorCode(
      'DEFAULT_VALUE_IN_FUNCTION_TYPE',
      "Parameters in a function type can't have default values.",
      correction: "Try removing the default value.",
      hasPublishedDocs: true);

  static const ParserErrorCode DEFERRED_AFTER_PREFIX = _DEFERRED_AFTER_PREFIX;

  static const ParserErrorCode DIRECTIVE_AFTER_DECLARATION =
      _DIRECTIVE_AFTER_DECLARATION;

  static const ParserErrorCode DUPLICATE_DEFERRED = _DUPLICATE_DEFERRED;

  /**
   * Parameters:
   * 0: the label that was duplicated
   */
  static const ParserErrorCode DUPLICATE_LABEL_IN_SWITCH_STATEMENT =
      _DUPLICATE_LABEL_IN_SWITCH_STATEMENT;

  static const ParserErrorCode DUPLICATE_PREFIX = _DUPLICATE_PREFIX;

  /**
   * Parameters:
   * 0: the modifier that was duplicated
   */
  static const ParserErrorCode DUPLICATED_MODIFIER = _DUPLICATED_MODIFIER;

  static const ParserErrorCode EMPTY_ENUM_BODY = ParserErrorCode(
      'EMPTY_ENUM_BODY', "An enum must declare at least one constant name.",
      correction: "Try declaring a constant.");

  static const ParserErrorCode ENUM_IN_CLASS = _ENUM_IN_CLASS;

  static const ParserErrorCode EQUALITY_CANNOT_BE_EQUALITY_OPERAND =
      _EQUALITY_CANNOT_BE_EQUALITY_OPERAND;

  static const ParserErrorCode EXPECTED_BODY = _EXPECTED_BODY;

  static const ParserErrorCode EXPECTED_CASE_OR_DEFAULT = ParserErrorCode(
      'EXPECTED_CASE_OR_DEFAULT', "Expected 'case' or 'default'.",
      correction: "Try placing this code inside a case clause.");

  static const ParserErrorCode EXPECTED_CLASS_MEMBER = ParserErrorCode(
      'EXPECTED_CLASS_MEMBER', "Expected a class member.",
      correction: "Try placing this code inside a class member.");

  static const ParserErrorCode EXPECTED_ELSE_OR_COMMA = _EXPECTED_ELSE_OR_COMMA;

  static const ParserErrorCode EXPECTED_EXECUTABLE = ParserErrorCode(
      'EXPECTED_EXECUTABLE',
      "Expected a method, getter, setter or operator declaration.",
      correction:
          "This appears to be incomplete code. Try removing it or completing it.");

  static const ParserErrorCode EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD =
      _EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD;

  static const ParserErrorCode EXPECTED_INSTEAD = _EXPECTED_INSTEAD;

  static const ParserErrorCode EXPECTED_LIST_OR_MAP_LITERAL = ParserErrorCode(
      'EXPECTED_LIST_OR_MAP_LITERAL', "Expected a list or map literal.",
      correction:
          "Try inserting a list or map literal, or remove the type arguments.");

  static const ParserErrorCode EXPECTED_STRING_LITERAL =
      ParserErrorCode('EXPECTED_STRING_LITERAL', "Expected a string literal.");

  /**
   * Parameters:
   * 0: the token that was expected but not found
   */
  static const ParserErrorCode EXPECTED_TOKEN =
      ParserErrorCode('EXPECTED_TOKEN', "Expected to find '{0}'.");

  static const ParserErrorCode EXPECTED_TYPE_NAME =
      ParserErrorCode('EXPECTED_TYPE_NAME', "Expected a type name.");

  static const ParserErrorCode EXPERIMENT_NOT_ENABLED = _EXPERIMENT_NOT_ENABLED;

  static const ParserErrorCode EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE =
      _EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE;

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an abstract declaration is
  // declared in an extension. Extensions can declare only concrete members.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because the method `a` doesn't
  // have a body:
  //
  // ```dart
  // extension E on String {
  //   int [!a!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Either provide an implementation for the member or remove it.
  static const ParserErrorCode EXTENSION_DECLARES_ABSTRACT_MEMBER =
      _EXTENSION_DECLARES_ABSTRACT_MEMBER;

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor declaration is
  // found in an extension. It isn't valid to define a constructor because
  // extensions aren't classes, and it isn't possible to create an instance of
  // an extension.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because there is a constructor
  // declaration in `E`:
  //
  // ```dart
  // extension E on String {
  //   [!E!]() : super();
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the constructor or replace it with a static method.
  static const ParserErrorCode EXTENSION_DECLARES_CONSTRUCTOR =
      _EXTENSION_DECLARES_CONSTRUCTOR;

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an instance field declaration is
  // found in an extension. It isn't valid to define an instance field because
  // extensions can only add behavior, not state.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `s` is an instance
  // field:
  //
  // ```dart
  // %language=2.9
  // extension E on String {
  //   String [!s!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the field, make it a static field, or convert it to be a getter,
  // setter, or method.
  static const ParserErrorCode EXTENSION_DECLARES_INSTANCE_FIELD =
      _EXTENSION_DECLARES_INSTANCE_FIELD;

  static const ParserErrorCode EXTERNAL_CLASS = _EXTERNAL_CLASS;

  static const ParserErrorCode EXTERNAL_CONSTRUCTOR_WITH_BODY =
      _EXTERNAL_CONSTRUCTOR_WITH_BODY;

  static const ParserErrorCode EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER =
      _EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER;

  static const ParserErrorCode EXTERNAL_ENUM = _EXTERNAL_ENUM;

  static const ParserErrorCode EXTERNAL_FACTORY_REDIRECTION =
      _EXTERNAL_FACTORY_REDIRECTION;

  static const ParserErrorCode EXTERNAL_FACTORY_WITH_BODY =
      _EXTERNAL_FACTORY_WITH_BODY;

  static const ParserErrorCode EXTERNAL_FIELD = _EXTERNAL_FIELD;

  static const ParserErrorCode EXTERNAL_GETTER_WITH_BODY = ParserErrorCode(
      'EXTERNAL_GETTER_WITH_BODY', "External getters can't have a body.",
      correction: "Try removing the body of the getter, or "
          "removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_LATE_FIELD = _EXTERNAL_LATE_FIELD;

  static const ParserErrorCode EXTERNAL_METHOD_WITH_BODY =
      _EXTERNAL_METHOD_WITH_BODY;

  static const ParserErrorCode EXTERNAL_OPERATOR_WITH_BODY = ParserErrorCode(
      'EXTERNAL_OPERATOR_WITH_BODY', "External operators can't have a body.",
      correction: "Try removing the body of the operator, or "
          "removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_SETTER_WITH_BODY = ParserErrorCode(
      'EXTERNAL_SETTER_WITH_BODY', "External setters can't have a body.",
      correction: "Try removing the body of the setter, or "
          "removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_TYPEDEF = _EXTERNAL_TYPEDEF;

  static const ParserErrorCode EXTRANEOUS_MODIFIER = _EXTRANEOUS_MODIFIER;

  static const ParserErrorCode FACTORY_TOP_LEVEL_DECLARATION =
      _FACTORY_TOP_LEVEL_DECLARATION;

  static const ParserErrorCode FACTORY_WITH_INITIALIZERS = ParserErrorCode(
      'FACTORY_WITH_INITIALIZERS',
      "A 'factory' constructor can't have initializers.",
      correction:
          "Try removing the 'factory' keyword to make this a generative constructor, or "
          "removing the initializers.");

  static const ParserErrorCode FACTORY_WITHOUT_BODY = ParserErrorCode(
      'FACTORY_WITHOUT_BODY',
      "A non-redirecting 'factory' constructor must have a body.",
      correction: "Try adding a body to the constructor.");

  static const ParserErrorCode FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS =
      _FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS;

  static const ParserErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR =
      _FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR;

  static const ParserErrorCode FINAL_AND_COVARIANT = _FINAL_AND_COVARIANT;

  static const ParserErrorCode FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER =
      _FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER;

  static const ParserErrorCode FINAL_AND_VAR = _FINAL_AND_VAR;

  static const ParserErrorCode FINAL_CLASS = ParserErrorCode(
      'FINAL_CLASS', "Classes can't be declared to be 'final'.",
      correction: "Try removing the keyword 'final'.");

  static const ParserErrorCode FINAL_CONSTRUCTOR = ParserErrorCode(
      'FINAL_CONSTRUCTOR', "A constructor can't be declared to be 'final'.",
      correction: "Try removing the keyword 'final'.");

  static const ParserErrorCode FINAL_ENUM = ParserErrorCode(
      'FINAL_ENUM', "Enums can't be declared to be 'final'.",
      correction: "Try removing the keyword 'final'.");

  static const ParserErrorCode FINAL_METHOD = ParserErrorCode('FINAL_METHOD',
      "Getters, setters and methods can't be declared to be 'final'.",
      correction: "Try removing the keyword 'final'.");

  static const ParserErrorCode FINAL_TYPEDEF = ParserErrorCode(
      'FINAL_TYPEDEF', "Typedefs can't be declared to be 'final'.",
      correction: "Try removing the keyword 'final'.");

  static const ParserErrorCode FUNCTION_TYPED_PARAMETER_VAR = ParserErrorCode(
      'FUNCTION_TYPED_PARAMETER_VAR',
      "Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.",
      correction: "Try replacing the keyword with a return type.");

  static const ParserErrorCode GETTER_CONSTRUCTOR = _GETTER_CONSTRUCTOR;

  static const ParserErrorCode GETTER_IN_FUNCTION = ParserErrorCode(
      'GETTER_IN_FUNCTION',
      "Getters can't be defined within methods or functions.",
      correction: "Try moving the getter outside the method or function, or "
          "converting the getter to a function.");

  static const ParserErrorCode GETTER_WITH_PARAMETERS = ParserErrorCode(
      'GETTER_WITH_PARAMETERS',
      "Getters must be declared without a parameter list.",
      correction: "Try removing the parameter list, or "
          "removing the keyword 'get' to define a method rather than a getter.");

  static const ParserErrorCode ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE =
      _ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE;

  static const ParserErrorCode IMPLEMENTS_BEFORE_EXTENDS =
      _IMPLEMENTS_BEFORE_EXTENDS;

  static const ParserErrorCode IMPLEMENTS_BEFORE_ON = _IMPLEMENTS_BEFORE_ON;

  static const ParserErrorCode IMPLEMENTS_BEFORE_WITH = _IMPLEMENTS_BEFORE_WITH;

  static const ParserErrorCode IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE =
      _IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE;

  static const ParserErrorCode INITIALIZED_VARIABLE_IN_FOR_EACH =
      _INITIALIZED_VARIABLE_IN_FOR_EACH;

  static const ParserErrorCode INVALID_AWAIT_IN_FOR = _INVALID_AWAIT_IN_FOR;

  /**
   * Parameters:
   * 0: the invalid escape sequence
   */
  static const ParserErrorCode INVALID_CODE_POINT = ParserErrorCode(
      'INVALID_CODE_POINT',
      "The escape sequence '{0}' isn't a valid code point.");

  static const ParserErrorCode INVALID_COMMENT_REFERENCE = ParserErrorCode(
      'INVALID_COMMENT_REFERENCE',
      "Comment references should contain a possibly prefixed identifier and "
          "can start with 'new', but shouldn't contain anything else.");

  static const ParserErrorCode INVALID_CONSTRUCTOR_NAME =
      _INVALID_CONSTRUCTOR_NAME;

  static const ParserErrorCode INVALID_GENERIC_FUNCTION_TYPE = ParserErrorCode(
      'INVALID_GENERIC_FUNCTION_TYPE', "Invalid generic function type.",
      correction:
          "Try using a generic function type (returnType 'Function(' parameters ')').");

  static const ParserErrorCode INVALID_HEX_ESCAPE = _INVALID_HEX_ESCAPE;

  static const ParserErrorCode INVALID_INITIALIZER = _INVALID_INITIALIZER;

  static const ParserErrorCode INVALID_LITERAL_IN_CONFIGURATION =
      ParserErrorCode('INVALID_LITERAL_IN_CONFIGURATION',
          "The literal in a configuration can't contain interpolation.",
          correction: "Try removing the interpolation expressions.");

  /**
   * Parameters:
   * 0: the operator that is invalid
   */
  static const ParserErrorCode INVALID_OPERATOR = _INVALID_OPERATOR;

  /**
   * Parameters:
   * 0: the operator being applied to 'super'
   *
   * Only generated by the old parser.
   * Replaced by INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER.
   */
  static const ParserErrorCode INVALID_OPERATOR_FOR_SUPER = ParserErrorCode(
      'INVALID_OPERATOR_FOR_SUPER',
      "The operator '{0}' can't be used with 'super'.");

  static const ParserErrorCode INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER =
      _INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER;

  static const ParserErrorCode INVALID_STAR_AFTER_ASYNC = ParserErrorCode(
      'INVALID_STAR_AFTER_ASYNC',
      "The modifier 'async*' isn't allowed for an expression function body.",
      correction: "Try converting the body to a block.");

  static const ParserErrorCode INVALID_SUPER_IN_INITIALIZER =
      _INVALID_SUPER_IN_INITIALIZER;

  static const ParserErrorCode INVALID_SYNC = ParserErrorCode('INVALID_SYNC',
      "The modifier 'sync' isn't allowed for an expression function body.",
      correction: "Try converting the body to a block.");

  static const ParserErrorCode INVALID_THIS_IN_INITIALIZER =
      _INVALID_THIS_IN_INITIALIZER;

  static const ParserErrorCode INVALID_UNICODE_ESCAPE = _INVALID_UNICODE_ESCAPE;

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a member declared inside an
  // extension uses the keyword `covariant` in the declaration of a parameter.
  // Extensions aren't classes and don't have subclasses, so the keyword serves
  // no purpose.
  //
  // #### Examples
  //
  // The following code produces this diagnostic because `i` is marked as being
  // covariant:
  //
  // ```dart
  // extension E on String {
  //   void a([!covariant!] int i) {}
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the `covariant` keyword:
  //
  // ```dart
  // extension E on String {
  //   void a(int i) {}
  // }
  // ```
  static const ParserErrorCode INVALID_USE_OF_COVARIANT_IN_EXTENSION =
      _INVALID_USE_OF_COVARIANT_IN_EXTENSION;

  static const ParserErrorCode LIBRARY_DIRECTIVE_NOT_FIRST =
      _LIBRARY_DIRECTIVE_NOT_FIRST;

  static const ParserErrorCode LOCAL_FUNCTION_DECLARATION_MODIFIER =
      ParserErrorCode('LOCAL_FUNCTION_DECLARATION_MODIFIER',
          "Local function declarations can't specify any modifiers.",
          correction: "Try removing the modifier.");

  static const ParserErrorCode MEMBER_WITH_CLASS_NAME = _MEMBER_WITH_CLASS_NAME;

  static const ParserErrorCode MISSING_ASSIGNABLE_SELECTOR =
      _MISSING_ASSIGNABLE_SELECTOR;

  static const ParserErrorCode MISSING_ASSIGNMENT_IN_INITIALIZER =
      _MISSING_ASSIGNMENT_IN_INITIALIZER;

  static const ParserErrorCode MISSING_CATCH_OR_FINALLY =
      _MISSING_CATCH_OR_FINALLY;

  static const ParserErrorCode MISSING_CLOSING_PARENTHESIS = ParserErrorCode(
      'MISSING_CLOSING_PARENTHESIS', "The closing parenthesis is missing.",
      correction: "Try adding the closing parenthesis.");

  static const ParserErrorCode MISSING_CONST_FINAL_VAR_OR_TYPE =
      _MISSING_CONST_FINAL_VAR_OR_TYPE;

  static const ParserErrorCode MISSING_ENUM_BODY = ParserErrorCode(
      'MISSING_ENUM_BODY',
      "An enum definition must have a body with at least one constant name.",
      correction: "Try adding a body and defining at least one constant.");

  static const ParserErrorCode MISSING_EXPRESSION_IN_INITIALIZER =
      ParserErrorCode('MISSING_EXPRESSION_IN_INITIALIZER',
          "Expected an expression after the assignment operator.",
          correction: "Try adding the value to be assigned, or "
              "remove the assignment operator.");

  static const ParserErrorCode MISSING_EXPRESSION_IN_THROW =
      _MISSING_EXPRESSION_IN_THROW;

  static const ParserErrorCode MISSING_FUNCTION_BODY = ParserErrorCode(
      'MISSING_FUNCTION_BODY', "A function body must be provided.",
      correction: "Try adding a function body.");

  static const ParserErrorCode MISSING_FUNCTION_KEYWORD = ParserErrorCode(
      'MISSING_FUNCTION_KEYWORD',
      "Function types must have the keyword 'Function' before the parameter list.",
      correction: "Try adding the keyword 'Function'.");

  static const ParserErrorCode MISSING_FUNCTION_PARAMETERS = ParserErrorCode(
      'MISSING_FUNCTION_PARAMETERS',
      "Functions must have an explicit list of parameters.",
      correction: "Try adding a parameter list.");

  static const ParserErrorCode MISSING_GET = ParserErrorCode('MISSING_GET',
      "Getters must have the keyword 'get' before the getter name.",
      correction: "Try adding the keyword 'get'.");

  static const ParserErrorCode MISSING_IDENTIFIER =
      ParserErrorCode('MISSING_IDENTIFIER', "Expected an identifier.");

  static const ParserErrorCode MISSING_INITIALIZER = _MISSING_INITIALIZER;

  static const ParserErrorCode MISSING_KEYWORD_OPERATOR =
      _MISSING_KEYWORD_OPERATOR;

  static const ParserErrorCode MISSING_METHOD_PARAMETERS = ParserErrorCode(
      'MISSING_METHOD_PARAMETERS',
      "Methods must have an explicit list of parameters.",
      correction: "Try adding a parameter list.");

  static const ParserErrorCode MISSING_NAME_FOR_NAMED_PARAMETER = ParserErrorCode(
      'MISSING_NAME_FOR_NAMED_PARAMETER',
      "Named parameters in a function type must have a name",
      correction:
          "Try providing a name for the parameter or removing the curly braces.");

  static const ParserErrorCode MISSING_NAME_IN_LIBRARY_DIRECTIVE = ParserErrorCode(
      'MISSING_NAME_IN_LIBRARY_DIRECTIVE',
      "Library directives must include a library name.",
      correction: "Try adding a library name after the keyword 'library', or "
          "remove the library directive if the library doesn't have any parts.");

  static const ParserErrorCode MISSING_NAME_IN_PART_OF_DIRECTIVE =
      ParserErrorCode('MISSING_NAME_IN_PART_OF_DIRECTIVE',
          "Part-of directives must include a library name.",
          correction: "Try adding a library name after the 'of'.");

  static const ParserErrorCode MISSING_PREFIX_IN_DEFERRED_IMPORT =
      _MISSING_PREFIX_IN_DEFERRED_IMPORT;

  static const ParserErrorCode MISSING_STAR_AFTER_SYNC = ParserErrorCode(
      'MISSING_STAR_AFTER_SYNC',
      "The modifier 'sync' must be followed by a star ('*').",
      correction: "Try removing the modifier, or add a star.");

  static const ParserErrorCode MISSING_STATEMENT = _MISSING_STATEMENT;

  /**
   * Parameters:
   * 0: the terminator that is missing
   */
  static const ParserErrorCode MISSING_TERMINATOR_FOR_PARAMETER_GROUP =
      ParserErrorCode('MISSING_TERMINATOR_FOR_PARAMETER_GROUP',
          "There is no '{0}' to close the parameter group.",
          correction: "Try inserting a '{0}' at the end of the group.");

  static const ParserErrorCode MISSING_TYPEDEF_PARAMETERS = ParserErrorCode(
      'MISSING_TYPEDEF_PARAMETERS',
      "Typedefs must have an explicit list of parameters.",
      correction: "Try adding a parameter list.");

  static const ParserErrorCode MISSING_VARIABLE_IN_FOR_EACH = ParserErrorCode(
      'MISSING_VARIABLE_IN_FOR_EACH',
      "A loop variable must be declared in a for-each loop before the 'in', but none was found.",
      correction: "Try declaring a loop variable.");

  static const ParserErrorCode MIXED_PARAMETER_GROUPS = ParserErrorCode(
      'MIXED_PARAMETER_GROUPS',
      "Can't have both positional and named parameters in a single parameter list.",
      correction: "Try choosing a single style of optional parameters.");

  static const ParserErrorCode MIXIN_DECLARES_CONSTRUCTOR =
      _MIXIN_DECLARES_CONSTRUCTOR;

  static const ParserErrorCode MODIFIER_OUT_OF_ORDER = _MODIFIER_OUT_OF_ORDER;

  static const ParserErrorCode MULTIPLE_EXTENDS_CLAUSES =
      _MULTIPLE_EXTENDS_CLAUSES;

  static const ParserErrorCode MULTIPLE_IMPLEMENTS_CLAUSES = ParserErrorCode(
      'MULTIPLE_IMPLEMENTS_CLAUSES',
      "Each class or mixin definition can have at most one implements clause.",
      correction:
          "Try combining all of the implements clauses into a single clause.");

  static const ParserErrorCode MULTIPLE_LIBRARY_DIRECTIVES =
      _MULTIPLE_LIBRARY_DIRECTIVES;

  static const ParserErrorCode MULTIPLE_NAMED_PARAMETER_GROUPS = ParserErrorCode(
      'MULTIPLE_NAMED_PARAMETER_GROUPS',
      "Can't have multiple groups of named parameters in a single parameter list.",
      correction: "Try combining all of the groups into a single group.");

  static const ParserErrorCode MULTIPLE_ON_CLAUSES = _MULTIPLE_ON_CLAUSES;

  static const ParserErrorCode MULTIPLE_PART_OF_DIRECTIVES =
      _MULTIPLE_PART_OF_DIRECTIVES;

  static const ParserErrorCode MULTIPLE_POSITIONAL_PARAMETER_GROUPS =
      ParserErrorCode('MULTIPLE_POSITIONAL_PARAMETER_GROUPS',
          "Can't have multiple groups of positional parameters in a single parameter list.",
          correction: "Try combining all of the groups into a single group.");

  /**
   * Parameters:
   * 0: the number of variables being declared
   */
  static const ParserErrorCode MULTIPLE_VARIABLES_IN_FOR_EACH = ParserErrorCode(
      'MULTIPLE_VARIABLES_IN_FOR_EACH',
      "A single loop variable must be declared in a for-each loop before "
          "the 'in', but {0} were found.",
      correction:
          "Try moving all but one of the declarations inside the loop body.");

  static const ParserErrorCode MULTIPLE_VARIANCE_MODIFIERS =
      _MULTIPLE_VARIANCE_MODIFIERS;

  static const ParserErrorCode MULTIPLE_WITH_CLAUSES = _MULTIPLE_WITH_CLAUSES;

  static const ParserErrorCode NAMED_FUNCTION_EXPRESSION = ParserErrorCode(
      'NAMED_FUNCTION_EXPRESSION', "Function expressions can't be named.",
      correction: "Try removing the name, or "
          "moving the function expression to a function declaration statement.");

  static const ParserErrorCode NAMED_FUNCTION_TYPE = ParserErrorCode(
      'NAMED_FUNCTION_TYPE', "Function types can't be named.",
      correction: "Try replacing the name with the keyword 'Function'.");

  static const ParserErrorCode NAMED_PARAMETER_OUTSIDE_GROUP = ParserErrorCode(
      'NAMED_PARAMETER_OUTSIDE_GROUP',
      "Named parameters must be enclosed in curly braces ('{' and '}').",
      correction: "Try surrounding the named parameters in curly braces.");

  static const ParserErrorCode NATIVE_CLAUSE_IN_NON_SDK_CODE = ParserErrorCode(
      'NATIVE_CLAUSE_IN_NON_SDK_CODE',
      "Native clause can only be used in the SDK and code that is loaded "
          "through native extensions.",
      correction: "Try removing the native clause.");

  static const ParserErrorCode NATIVE_CLAUSE_SHOULD_BE_ANNOTATION =
      _NATIVE_CLAUSE_SHOULD_BE_ANNOTATION;

  static const ParserErrorCode NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE =
      ParserErrorCode(
          'NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE',
          "Native functions can only be declared in the SDK and code that is "
              "loaded through native extensions.",
          correction: "Try removing the word 'native'.");

  static const ParserErrorCode NON_CONSTRUCTOR_FACTORY = ParserErrorCode(
      'NON_CONSTRUCTOR_FACTORY',
      "Only a constructor can be declared to be a factory.",
      correction: "Try removing the keyword 'factory'.");

  static const ParserErrorCode NON_IDENTIFIER_LIBRARY_NAME = ParserErrorCode(
      'NON_IDENTIFIER_LIBRARY_NAME',
      "The name of a library must be an identifier.",
      correction: "Try using an identifier as the name of the library.");

  static const ParserErrorCode NON_PART_OF_DIRECTIVE_IN_PART = ParserErrorCode(
      'NON_PART_OF_DIRECTIVE_IN_PART',
      "The part-of directive must be the only directive in a part.",
      correction: "Try removing the other directives, or "
          "moving them to the library for which this is a part.");

  static const ParserErrorCode NON_STRING_LITERAL_AS_URI = ParserErrorCode(
      'NON_STRING_LITERAL_AS_URI', "The URI must be a string literal.",
      correction: "Try enclosing the URI in either single or double quotes.");

  /**
   * Parameters:
   * 0: the operator that the user is trying to define
   */
  static const ParserErrorCode NON_USER_DEFINABLE_OPERATOR = ParserErrorCode(
      'NON_USER_DEFINABLE_OPERATOR',
      "The operator '{0}' isn't user definable.");

  static const ParserErrorCode NORMAL_BEFORE_OPTIONAL_PARAMETERS = ParserErrorCode(
      'NORMAL_BEFORE_OPTIONAL_PARAMETERS',
      "Normal parameters must occur before optional parameters.",
      correction:
          "Try moving all of the normal parameters before the optional parameters.");

  static const ErrorCode NULL_AWARE_CASCADE_OUT_OF_ORDER =
      _NULL_AWARE_CASCADE_OUT_OF_ORDER;

  static const ParserErrorCode POSITIONAL_AFTER_NAMED_ARGUMENT = ParserErrorCode(
      'POSITIONAL_AFTER_NAMED_ARGUMENT',
      "Positional arguments must occur before named arguments.",
      correction:
          "Try moving all of the positional arguments before the named arguments.");

  static const ParserErrorCode POSITIONAL_PARAMETER_OUTSIDE_GROUP = ParserErrorCode(
      'POSITIONAL_PARAMETER_OUTSIDE_GROUP',
      "Positional parameters must be enclosed in square brackets ('[' and ']').",
      correction:
          "Try surrounding the positional parameters in square brackets.");

  static const ParserErrorCode PREFIX_AFTER_COMBINATOR =
      _PREFIX_AFTER_COMBINATOR;

  static const ParserErrorCode REDIRECTING_CONSTRUCTOR_WITH_BODY =
      _REDIRECTING_CONSTRUCTOR_WITH_BODY;

  static const ParserErrorCode REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR =
      _REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR;

  static const ParserErrorCode SETTER_CONSTRUCTOR = _SETTER_CONSTRUCTOR;

  static const ParserErrorCode SETTER_IN_FUNCTION = ParserErrorCode(
      'SETTER_IN_FUNCTION',
      "Setters can't be defined within methods or functions.",
      correction: "Try moving the setter outside the method or function.");

  static const ParserErrorCode STACK_OVERFLOW = _STACK_OVERFLOW;

  static const ParserErrorCode STATIC_CONSTRUCTOR = _STATIC_CONSTRUCTOR;

  static const ParserErrorCode STATIC_GETTER_WITHOUT_BODY = ParserErrorCode(
      'STATIC_GETTER_WITHOUT_BODY', "A 'static' getter must have a body.",
      correction:
          "Try adding a body to the getter, or removing the keyword 'static'.");

  static const ParserErrorCode STATIC_OPERATOR = _STATIC_OPERATOR;

  static const ParserErrorCode STATIC_SETTER_WITHOUT_BODY = ParserErrorCode(
      'STATIC_SETTER_WITHOUT_BODY', "A 'static' setter must have a body.",
      correction:
          "Try adding a body to the setter, or removing the keyword 'static'.");

  static const ParserErrorCode STATIC_TOP_LEVEL_DECLARATION = ParserErrorCode(
      'STATIC_TOP_LEVEL_DECLARATION',
      "Top-level declarations can't be declared to be static.",
      correction: "Try removing the keyword 'static'.");

  static const ParserErrorCode SWITCH_HAS_CASE_AFTER_DEFAULT_CASE =
      _SWITCH_HAS_CASE_AFTER_DEFAULT_CASE;

  static const ParserErrorCode SWITCH_HAS_MULTIPLE_DEFAULT_CASES =
      _SWITCH_HAS_MULTIPLE_DEFAULT_CASES;

  static const ParserErrorCode TOP_LEVEL_OPERATOR = _TOP_LEVEL_OPERATOR;

  static const ParserErrorCode TYPE_ARGUMENTS_ON_TYPE_VARIABLE =
      _TYPE_ARGUMENTS_ON_TYPE_VARIABLE;

  static const ParserErrorCode TYPE_BEFORE_FACTORY = _TYPE_BEFORE_FACTORY;

  static const ParserErrorCode TYPE_PARAMETER_ON_CONSTRUCTOR =
      _TYPE_PARAMETER_ON_CONSTRUCTOR;

  /**
   * 7.1.1 Operators: Type parameters are not syntactically supported on an
   * operator.
   */
  static const ParserErrorCode TYPE_PARAMETER_ON_OPERATOR = ParserErrorCode(
      'TYPE_PARAMETERS_ON_OPERATOR',
      "Types parameters aren't allowed when defining an operator.",
      correction: "Try removing the type parameters.");

  static const ParserErrorCode TYPEDEF_IN_CLASS = _TYPEDEF_IN_CLASS;

  /**
   * Parameters:
   * 0: the starting character that was missing
   */
  static const ParserErrorCode UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP =
      ParserErrorCode('UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP',
          "There is no '{0}' to open a parameter group.",
          correction: "Try inserting the '{0}' at the appropriate location.");

  /**
   * Parameters:
   * 0: the unexpected text that was found
   */
  static const ParserErrorCode UNEXPECTED_TOKEN = ParserErrorCode(
      'UNEXPECTED_TOKEN', "Unexpected text '{0}'.",
      correction: "Try removing the text.");

  static const ParserErrorCode VAR_AND_TYPE = _VAR_AND_TYPE;

  static const ParserErrorCode VAR_AS_TYPE_NAME = _VAR_AS_TYPE_NAME;

  static const ParserErrorCode VAR_CLASS = ParserErrorCode(
      'VAR_CLASS', "Classes can't be declared to be 'var'.",
      correction: "Try removing the keyword 'var'.");

  static const ParserErrorCode VAR_ENUM = ParserErrorCode(
      'VAR_ENUM', "Enums can't be declared to be 'var'.",
      correction: "Try removing the keyword 'var'.");

  static const ParserErrorCode VAR_RETURN_TYPE = _VAR_RETURN_TYPE;

  static const ParserErrorCode VAR_TYPEDEF =
      ParserErrorCode('VAR_TYPEDEF', "Typedefs can't be declared to be 'var'.",
          correction: "Try removing the keyword 'var', or "
              "replacing it with the name of the return type.");

  static const ParserErrorCode VOID_WITH_TYPE_ARGUMENTS =
      _VOID_WITH_TYPE_ARGUMENTS;

  static const ParserErrorCode WITH_BEFORE_EXTENDS = _WITH_BEFORE_EXTENDS;

  static const ParserErrorCode WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER =
      ParserErrorCode('WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER',
          "The default value of a positional parameter should be preceded by '='.",
          correction: "Try replacing the ':' with '='.");

  /**
   * Parameters:
   * 0: the terminator that was expected
   * 1: the terminator that was found
   */
  static const ParserErrorCode WRONG_TERMINATOR_FOR_PARAMETER_GROUP =
      ParserErrorCode('WRONG_TERMINATOR_FOR_PARAMETER_GROUP',
          "Expected '{0}' to close parameter group.",
          correction: "Try replacing '{0}' with '{1}'.");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const ParserErrorCode(
    String name,
    String message, {
    String correction,
    bool hasPublishedDocs = false,
    String uniqueName,
  }) : super(
          correction: correction,
          hasPublishedDocs: hasPublishedDocs,
          message: message,
          name: name,
          uniqueName: uniqueName ?? 'ParserErrorCode.$name',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.SYNTACTIC_ERROR;
}
