// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The errors produced during sytactic analysis (scanning and parsing).
 */
library analyzer.src.dart.error.syntactic_errors;

import 'package:analyzer/error/error.dart';

/**
 * The error codes used for errors detected by the parser. The convention for
 * this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what
 * is wrong and, when appropriate, how the problem can be corrected.
 */
class ParserErrorCode extends ErrorCode {
  static const ParserErrorCode ABSTRACT_CLASS_MEMBER = const ParserErrorCode(
      'ABSTRACT_CLASS_MEMBER',
      "Members of classes cannot be declared to be 'abstract'");

  static const ParserErrorCode ABSTRACT_ENUM = const ParserErrorCode(
      'ABSTRACT_ENUM', "Enums cannot be declared to be 'abstract'");

  static const ParserErrorCode ABSTRACT_STATIC_METHOD = const ParserErrorCode(
      'ABSTRACT_STATIC_METHOD',
      "Static methods cannot be declared to be 'abstract'");

  static const ParserErrorCode ABSTRACT_TOP_LEVEL_FUNCTION =
      const ParserErrorCode('ABSTRACT_TOP_LEVEL_FUNCTION',
          "Top-level functions cannot be declared to be 'abstract'");

  static const ParserErrorCode ABSTRACT_TOP_LEVEL_VARIABLE =
      const ParserErrorCode('ABSTRACT_TOP_LEVEL_VARIABLE',
          "Top-level variables cannot be declared to be 'abstract'");

  static const ParserErrorCode ABSTRACT_TYPEDEF = const ParserErrorCode(
      'ABSTRACT_TYPEDEF', "Type aliases cannot be declared to be 'abstract'");

  static const ParserErrorCode ANNOTATION_ON_ENUM_CONSTANT =
      const ParserErrorCode('ANNOTATION_ON_ENUM_CONSTANT',
          "Enum constants cannot have annotations");

  /**
   * 16.32 Identifier Reference: It is a compile-time error if any of the
   * identifiers async, await, or yield is used as an identifier in a function
   * body marked with either async, async*, or sync*.
   */
  static const ParserErrorCode ASYNC_KEYWORD_USED_AS_IDENTIFIER =
      const ParserErrorCode('ASYNC_KEYWORD_USED_AS_IDENTIFIER',
          "The keywords 'async', 'await', and 'yield' may not be used as identifiers in an asynchronous or generator function.");

  /**
   * Some environments, such as Fletch, do not support async.
   */
  static const ParserErrorCode ASYNC_NOT_SUPPORTED = const ParserErrorCode(
      'ASYNC_NOT_SUPPORTED',
      "Async and sync are not supported in this environment.");

  static const ParserErrorCode BREAK_OUTSIDE_OF_LOOP = const ParserErrorCode(
      'BREAK_OUTSIDE_OF_LOOP',
      "A break statement cannot be used outside of a loop or switch statement");

  static const ParserErrorCode CLASS_IN_CLASS = const ParserErrorCode(
      'CLASS_IN_CLASS',
      "Classes can't be declared inside other classes.",
      "Try moving the class to the top-level.");

  static const ParserErrorCode COLON_IN_PLACE_OF_IN = const ParserErrorCode(
      'COLON_IN_PLACE_OF_IN', "For-in loops use 'in' rather than a colon");

  static const ParserErrorCode CONST_AND_FINAL = const ParserErrorCode(
      'CONST_AND_FINAL',
      "Members can't be declared to be both 'const' and 'final'.",
      "Try removing either the 'const' or 'final' keyword.");

  static const ParserErrorCode CONST_AND_VAR = const ParserErrorCode(
      'CONST_AND_VAR',
      "Members can't be declared to be both 'const' and 'var'.",
      "Try removing either the 'const' or 'var' keyword.");

  static const ParserErrorCode CONST_CLASS = const ParserErrorCode(
      'CONST_CLASS',
      "Classes can't be declared to be 'const'.",
      "Try removing the 'const' keyword or moving to the class' constructor(s).");

  static const ParserErrorCode CONST_CONSTRUCTOR_WITH_BODY =
      const ParserErrorCode(
          'CONST_CONSTRUCTOR_WITH_BODY',
          "Const constructor can't have a body.",
          "Try removing the 'const' keyword or the body.");

  static const ParserErrorCode CONST_ENUM = const ParserErrorCode(
      'CONST_ENUM',
      "Enums can't be declared to be 'const'.",
      "Try removing the 'const' keyword.");

  static const ParserErrorCode CONST_FACTORY = const ParserErrorCode(
      'CONST_FACTORY',
      "Only redirecting factory constructors can be declared to be 'const'.",
      "Try removing the 'const' keyword or replacing the body with '=' followed by a valid target.");

  static const ParserErrorCode CONST_METHOD = const ParserErrorCode(
      'CONST_METHOD',
      "Getters, setters and methods can't be declared to be 'const'.",
      "Try removing the 'const' keyword.");

  static const ParserErrorCode CONST_TYPEDEF = const ParserErrorCode(
      'CONST_TYPEDEF',
      "Type aliases can't be declared to be 'const'.",
      "Try removing the 'const' keyword.");

  static const ParserErrorCode CONSTRUCTOR_WITH_RETURN_TYPE =
      const ParserErrorCode(
          'CONSTRUCTOR_WITH_RETURN_TYPE',
          "Constructors can't have a return type.",
          "Try removing the return type.");

  static const ParserErrorCode CONTINUE_OUTSIDE_OF_LOOP = const ParserErrorCode(
      'CONTINUE_OUTSIDE_OF_LOOP',
      "A continue statement cannot be used outside of a loop or switch statement");

  static const ParserErrorCode CONTINUE_WITHOUT_LABEL_IN_CASE =
      const ParserErrorCode('CONTINUE_WITHOUT_LABEL_IN_CASE',
          "A continue statement in a switch statement must have a label as a target");

  static const ParserErrorCode DEPRECATED_CLASS_TYPE_ALIAS =
      const ParserErrorCode('DEPRECATED_CLASS_TYPE_ALIAS',
          "The 'typedef' mixin application was replaced with 'class'");

  static const ParserErrorCode DIRECTIVE_AFTER_DECLARATION =
      const ParserErrorCode('DIRECTIVE_AFTER_DECLARATION',
          "Directives must appear before any declarations");

  static const ParserErrorCode DUPLICATE_LABEL_IN_SWITCH_STATEMENT =
      const ParserErrorCode('DUPLICATE_LABEL_IN_SWITCH_STATEMENT',
          "The label {0} was already used in this switch statement");

  static const ParserErrorCode DUPLICATED_MODIFIER = const ParserErrorCode(
      'DUPLICATED_MODIFIER', "The modifier '{0}' was already specified.");

  static const ParserErrorCode EMPTY_ENUM_BODY = const ParserErrorCode(
      'EMPTY_ENUM_BODY', "An enum must declare at least one constant name");

  static const ParserErrorCode ENUM_IN_CLASS = const ParserErrorCode(
      'ENUM_IN_CLASS', "Enums cannot be declared inside classes");

  static const ParserErrorCode EQUALITY_CANNOT_BE_EQUALITY_OPERAND =
      const ParserErrorCode('EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
          "Equality expression cannot be operand of another equality expression.");

  static const ParserErrorCode EXPECTED_CASE_OR_DEFAULT = const ParserErrorCode(
      'EXPECTED_CASE_OR_DEFAULT', "Expected 'case' or 'default'");

  static const ParserErrorCode EXPECTED_CLASS_MEMBER =
      const ParserErrorCode('EXPECTED_CLASS_MEMBER', "Expected a class member");

  static const ParserErrorCode EXPECTED_EXECUTABLE = const ParserErrorCode(
      'EXPECTED_EXECUTABLE',
      "Expected a method, getter, setter or operator declaration");

  static const ParserErrorCode EXPECTED_LIST_OR_MAP_LITERAL =
      const ParserErrorCode(
          'EXPECTED_LIST_OR_MAP_LITERAL', "Expected a list or map literal");

  static const ParserErrorCode EXPECTED_STRING_LITERAL = const ParserErrorCode(
      'EXPECTED_STRING_LITERAL', "Expected a string literal");

  static const ParserErrorCode EXPECTED_TOKEN =
      const ParserErrorCode('EXPECTED_TOKEN', "Expected to find '{0}'");

  static const ParserErrorCode EXPECTED_TYPE_NAME =
      const ParserErrorCode('EXPECTED_TYPE_NAME', "Expected a type name");

  static const ParserErrorCode EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE =
      const ParserErrorCode('EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
          "Export directives must preceed part directives");

  static const ParserErrorCode EXTERNAL_AFTER_CONST = const ParserErrorCode(
      'EXTERNAL_AFTER_CONST',
      "The modifier 'external' should be before the modifier 'const'");

  static const ParserErrorCode EXTERNAL_AFTER_FACTORY = const ParserErrorCode(
      'EXTERNAL_AFTER_FACTORY',
      "The modifier 'external' should be before the modifier 'factory'");

  static const ParserErrorCode EXTERNAL_AFTER_STATIC = const ParserErrorCode(
      'EXTERNAL_AFTER_STATIC',
      "The modifier 'external' should be before the modifier 'static'");

  static const ParserErrorCode EXTERNAL_CLASS = const ParserErrorCode(
      'EXTERNAL_CLASS', "Classes cannot be declared to be 'external'");

  static const ParserErrorCode EXTERNAL_CONSTRUCTOR_WITH_BODY =
      const ParserErrorCode('EXTERNAL_CONSTRUCTOR_WITH_BODY',
          "External constructors cannot have a body");

  static const ParserErrorCode EXTERNAL_ENUM = const ParserErrorCode(
      'EXTERNAL_ENUM', "Enums cannot be declared to be 'external'");

  static const ParserErrorCode EXTERNAL_FIELD = const ParserErrorCode(
      'EXTERNAL_FIELD', "Fields cannot be declared to be 'external'");

  static const ParserErrorCode EXTERNAL_GETTER_WITH_BODY =
      const ParserErrorCode(
          'EXTERNAL_GETTER_WITH_BODY', "External getters cannot have a body");

  static const ParserErrorCode EXTERNAL_METHOD_WITH_BODY =
      const ParserErrorCode(
          'EXTERNAL_METHOD_WITH_BODY', "External methods cannot have a body");

  static const ParserErrorCode EXTERNAL_OPERATOR_WITH_BODY =
      const ParserErrorCode('EXTERNAL_OPERATOR_WITH_BODY',
          "External operators cannot have a body");

  static const ParserErrorCode EXTERNAL_SETTER_WITH_BODY =
      const ParserErrorCode(
          'EXTERNAL_SETTER_WITH_BODY', "External setters cannot have a body");

  static const ParserErrorCode EXTERNAL_TYPEDEF = const ParserErrorCode(
      'EXTERNAL_TYPEDEF', "Type aliases cannot be declared to be 'external'");

  static const ParserErrorCode FACTORY_TOP_LEVEL_DECLARATION =
      const ParserErrorCode('FACTORY_TOP_LEVEL_DECLARATION',
          "Top-level declarations cannot be declared to be 'factory'");

  static const ParserErrorCode FACTORY_WITH_INITIALIZERS =
      const ParserErrorCode(
          'FACTORY_WITH_INITIALIZERS',
          "A 'factory' constructor cannot have initializers",
          "Either remove the 'factory' keyword to make this a generative "
          "constructor or remove the initializers.");

  static const ParserErrorCode FACTORY_WITHOUT_BODY = const ParserErrorCode(
      'FACTORY_WITHOUT_BODY',
      "A non-redirecting 'factory' constructor must have a body");

  static const ParserErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR =
      const ParserErrorCode('FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
          "Field initializers can only be used in a constructor");

  static const ParserErrorCode FINAL_AND_VAR = const ParserErrorCode(
      'FINAL_AND_VAR',
      "Members cannot be declared to be both 'final' and 'var'");

  static const ParserErrorCode FINAL_CLASS = const ParserErrorCode(
      'FINAL_CLASS', "Classes cannot be declared to be 'final'");

  static const ParserErrorCode FINAL_CONSTRUCTOR = const ParserErrorCode(
      'FINAL_CONSTRUCTOR', "A constructor cannot be declared to be 'final'");

  static const ParserErrorCode FINAL_ENUM = const ParserErrorCode(
      'FINAL_ENUM', "Enums cannot be declared to be 'final'");

  static const ParserErrorCode FINAL_METHOD = const ParserErrorCode(
      'FINAL_METHOD',
      "Getters, setters and methods cannot be declared to be 'final'");

  static const ParserErrorCode FINAL_TYPEDEF = const ParserErrorCode(
      'FINAL_TYPEDEF', "Type aliases cannot be declared to be 'final'");

  static const ParserErrorCode FUNCTION_TYPED_PARAMETER_VAR = const ParserErrorCode(
      'FUNCTION_TYPED_PARAMETER_VAR',
      "Function typed parameters cannot specify 'const', 'final' or 'var' instead of return type");

  static const ParserErrorCode GETTER_IN_FUNCTION = const ParserErrorCode(
      'GETTER_IN_FUNCTION',
      "Getters cannot be defined within methods or functions");

  static const ParserErrorCode GETTER_WITH_PARAMETERS = const ParserErrorCode(
      'GETTER_WITH_PARAMETERS',
      "Getter should be declared without a parameter list");

  static const ParserErrorCode ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE =
      const ParserErrorCode('ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE',
          "Illegal assignment to non-assignable expression");

  static const ParserErrorCode IMPLEMENTS_BEFORE_EXTENDS =
      const ParserErrorCode('IMPLEMENTS_BEFORE_EXTENDS',
          "The extends clause must be before the implements clause");

  static const ParserErrorCode IMPLEMENTS_BEFORE_WITH = const ParserErrorCode(
      'IMPLEMENTS_BEFORE_WITH',
      "The with clause must be before the implements clause");

  static const ParserErrorCode IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE =
      const ParserErrorCode('IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
          "Import directives must preceed part directives");

  static const ParserErrorCode INITIALIZED_VARIABLE_IN_FOR_EACH =
      const ParserErrorCode('INITIALIZED_VARIABLE_IN_FOR_EACH',
          "The loop variable in a for-each loop cannot be initialized");

  static const ParserErrorCode INVALID_AWAIT_IN_FOR = const ParserErrorCode(
      'INVALID_AWAIT_IN_FOR',
      "The modifier 'await' is not allowed for a normal 'for' statement",
      "Remove the keyword or use a for-each statement.");

  static const ParserErrorCode INVALID_CODE_POINT = const ParserErrorCode(
      'INVALID_CODE_POINT',
      "The escape sequence '{0}' is not a valid code point");

  static const ParserErrorCode INVALID_COMMENT_REFERENCE = const ParserErrorCode(
      'INVALID_COMMENT_REFERENCE',
      "Comment references should contain a possibly prefixed identifier and can start with 'new', but should not contain anything else");

  static const ParserErrorCode INVALID_HEX_ESCAPE = const ParserErrorCode(
      'INVALID_HEX_ESCAPE',
      "An escape sequence starting with '\\x' must be followed by 2 hexidecimal digits");

  static const ParserErrorCode INVALID_LITERAL_IN_CONFIGURATION =
      const ParserErrorCode('INVALID_LITERAL_IN_CONFIGURATION',
          "The literal in a configuration cannot contain interpolation");

  static const ParserErrorCode INVALID_OPERATOR = const ParserErrorCode(
      'INVALID_OPERATOR', "The string '{0}' is not a valid operator");

  static const ParserErrorCode INVALID_OPERATOR_FOR_SUPER =
      const ParserErrorCode('INVALID_OPERATOR_FOR_SUPER',
          "The operator '{0}' cannot be used with 'super'");

  static const ParserErrorCode INVALID_STAR_AFTER_ASYNC = const ParserErrorCode(
      'INVALID_STAR_AFTER_ASYNC',
      "The modifier 'async*' is not allowed for an expression function body",
      "Convert the body to a block.");

  static const ParserErrorCode INVALID_SYNC = const ParserErrorCode(
      'INVALID_SYNC',
      "The modifier 'sync' is not allowed for an exrpression function body",
      "Convert the body to a block.");

  static const ParserErrorCode INVALID_UNICODE_ESCAPE = const ParserErrorCode(
      'INVALID_UNICODE_ESCAPE',
      "An escape sequence starting with '\\u' must be followed by 4 hexidecimal digits or from 1 to 6 digits between '{' and '}'");

  static const ParserErrorCode LIBRARY_DIRECTIVE_NOT_FIRST =
      const ParserErrorCode('LIBRARY_DIRECTIVE_NOT_FIRST',
          "The library directive must appear before all other directives");

  static const ParserErrorCode LOCAL_FUNCTION_DECLARATION_MODIFIER =
      const ParserErrorCode('LOCAL_FUNCTION_DECLARATION_MODIFIER',
          "Local function declarations cannot specify any modifier");

  static const ParserErrorCode MISSING_ASSIGNABLE_SELECTOR =
      const ParserErrorCode('MISSING_ASSIGNABLE_SELECTOR',
          "Missing selector such as \".<identifier>\" or \"[0]\"");

  static const ParserErrorCode MISSING_ASSIGNMENT_IN_INITIALIZER =
      const ParserErrorCode('MISSING_ASSIGNMENT_IN_INITIALIZER',
          "Expected an assignment after the field name");

  static const ParserErrorCode MISSING_CATCH_OR_FINALLY = const ParserErrorCode(
      'MISSING_CATCH_OR_FINALLY',
      "A try statement must have either a catch or finally clause");

  static const ParserErrorCode MISSING_CLASS_BODY = const ParserErrorCode(
      'MISSING_CLASS_BODY',
      "A class definition must have a body, even if it is empty");

  static const ParserErrorCode MISSING_CLOSING_PARENTHESIS =
      const ParserErrorCode(
          'MISSING_CLOSING_PARENTHESIS', "The closing parenthesis is missing");

  static const ParserErrorCode MISSING_CONST_FINAL_VAR_OR_TYPE =
      const ParserErrorCode('MISSING_CONST_FINAL_VAR_OR_TYPE',
          "Variables must be declared using the keywords 'const', 'final', 'var' or a type name");

  static const ParserErrorCode MISSING_ENUM_BODY = const ParserErrorCode(
      'MISSING_ENUM_BODY',
      "An enum definition must have a body with at least one constant name");

  static const ParserErrorCode MISSING_EXPRESSION_IN_INITIALIZER =
      const ParserErrorCode('MISSING_EXPRESSION_IN_INITIALIZER',
          "Expected an expression after the assignment operator");

  static const ParserErrorCode MISSING_EXPRESSION_IN_THROW =
      const ParserErrorCode('MISSING_EXPRESSION_IN_THROW',
          "Missing expression after 'throw'.", "Did you mean 'rethrow'?");

  static const ParserErrorCode MISSING_FUNCTION_BODY = const ParserErrorCode(
      'MISSING_FUNCTION_BODY', "A function body must be provided");

  static const ParserErrorCode MISSING_FUNCTION_PARAMETERS =
      const ParserErrorCode('MISSING_FUNCTION_PARAMETERS',
          "Functions must have an explicit list of parameters");

  static const ParserErrorCode MISSING_METHOD_PARAMETERS =
      const ParserErrorCode('MISSING_METHOD_PARAMETERS',
          "Methods must have an explicit list of parameters");

  static const ParserErrorCode MISSING_GET = const ParserErrorCode(
      'MISSING_GET',
      "Getters must have the keyword 'get' before the getter name");

  static const ParserErrorCode MISSING_IDENTIFIER =
      const ParserErrorCode('MISSING_IDENTIFIER', "Expected an identifier");

  static const ParserErrorCode MISSING_INITIALIZER =
      const ParserErrorCode('MISSING_INITIALIZER', "Expected an initializer");

  static const ParserErrorCode MISSING_KEYWORD_OPERATOR = const ParserErrorCode(
      'MISSING_KEYWORD_OPERATOR',
      "Operator declarations must be preceeded by the keyword 'operator'");

  static const ParserErrorCode MISSING_NAME_IN_LIBRARY_DIRECTIVE =
      const ParserErrorCode('MISSING_NAME_IN_LIBRARY_DIRECTIVE',
          "Library directives must include a library name");

  static const ParserErrorCode MISSING_NAME_IN_PART_OF_DIRECTIVE =
      const ParserErrorCode('MISSING_NAME_IN_PART_OF_DIRECTIVE',
          "Library directives must include a library name");

  static const ParserErrorCode MISSING_PREFIX_IN_DEFERRED_IMPORT =
      const ParserErrorCode('MISSING_PREFIX_IN_DEFERRED_IMPORT',
          "Deferred imports must have a prefix");

  static const ParserErrorCode MISSING_STAR_AFTER_SYNC = const ParserErrorCode(
      'MISSING_STAR_AFTER_SYNC',
      "The modifier 'sync' must be followed by a star ('*')",
      "Remove the modifier or add a star.");

  static const ParserErrorCode MISSING_STATEMENT =
      const ParserErrorCode('MISSING_STATEMENT', "Expected a statement");

  static const ParserErrorCode MISSING_TERMINATOR_FOR_PARAMETER_GROUP =
      const ParserErrorCode('MISSING_TERMINATOR_FOR_PARAMETER_GROUP',
          "There is no '{0}' to close the parameter group");

  static const ParserErrorCode MISSING_TYPEDEF_PARAMETERS =
      const ParserErrorCode('MISSING_TYPEDEF_PARAMETERS',
          "Type aliases for functions must have an explicit list of parameters");

  static const ParserErrorCode MISSING_VARIABLE_IN_FOR_EACH = const ParserErrorCode(
      'MISSING_VARIABLE_IN_FOR_EACH',
      "A loop variable must be declared in a for-each loop before the 'in', but none were found");

  static const ParserErrorCode MIXED_PARAMETER_GROUPS = const ParserErrorCode(
      'MIXED_PARAMETER_GROUPS',
      "Cannot have both positional and named parameters in a single parameter list");

  static const ParserErrorCode MULTIPLE_EXTENDS_CLAUSES = const ParserErrorCode(
      'MULTIPLE_EXTENDS_CLAUSES',
      "Each class definition can have at most one extends clause");

  static const ParserErrorCode MULTIPLE_IMPLEMENTS_CLAUSES =
      const ParserErrorCode('MULTIPLE_IMPLEMENTS_CLAUSES',
          "Each class definition can have at most one implements clause");

  static const ParserErrorCode MULTIPLE_LIBRARY_DIRECTIVES =
      const ParserErrorCode('MULTIPLE_LIBRARY_DIRECTIVES',
          "Only one library directive may be declared in a file");

  static const ParserErrorCode MULTIPLE_NAMED_PARAMETER_GROUPS =
      const ParserErrorCode('MULTIPLE_NAMED_PARAMETER_GROUPS',
          "Cannot have multiple groups of named parameters in a single parameter list");

  static const ParserErrorCode MULTIPLE_PART_OF_DIRECTIVES =
      const ParserErrorCode('MULTIPLE_PART_OF_DIRECTIVES',
          "Only one part-of directive may be declared in a file");

  static const ParserErrorCode MULTIPLE_POSITIONAL_PARAMETER_GROUPS =
      const ParserErrorCode('MULTIPLE_POSITIONAL_PARAMETER_GROUPS',
          "Cannot have multiple groups of positional parameters in a single parameter list");

  static const ParserErrorCode MULTIPLE_VARIABLES_IN_FOR_EACH =
      const ParserErrorCode('MULTIPLE_VARIABLES_IN_FOR_EACH',
          "A single loop variable must be declared in a for-each loop before the 'in', but {0} were found");

  static const ParserErrorCode MULTIPLE_WITH_CLAUSES = const ParserErrorCode(
      'MULTIPLE_WITH_CLAUSES',
      "Each class definition can have at most one with clause");

  static const ParserErrorCode NAMED_FUNCTION_EXPRESSION =
      const ParserErrorCode(
          'NAMED_FUNCTION_EXPRESSION', "Function expressions cannot be named");

  static const ParserErrorCode NAMED_PARAMETER_OUTSIDE_GROUP =
      const ParserErrorCode('NAMED_PARAMETER_OUTSIDE_GROUP',
          "Named parameters must be enclosed in curly braces ('{' and '}')");

  static const ParserErrorCode NATIVE_CLAUSE_IN_NON_SDK_CODE =
      const ParserErrorCode('NATIVE_CLAUSE_IN_NON_SDK_CODE',
          "Native clause can only be used in the SDK and code that is loaded through native extensions");

  static const ParserErrorCode NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE =
      const ParserErrorCode('NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE',
          "Native functions can only be declared in the SDK and code that is loaded through native extensions");

  static const ParserErrorCode NON_CONSTRUCTOR_FACTORY = const ParserErrorCode(
      'NON_CONSTRUCTOR_FACTORY',
      "Only constructors can be declared to be a 'factory'");

  static const ParserErrorCode NON_IDENTIFIER_LIBRARY_NAME =
      const ParserErrorCode('NON_IDENTIFIER_LIBRARY_NAME',
          "The name of a library must be an identifier");

  static const ParserErrorCode NON_PART_OF_DIRECTIVE_IN_PART =
      const ParserErrorCode('NON_PART_OF_DIRECTIVE_IN_PART',
          "The part-of directive must be the only directive in a part");

  static const ParserErrorCode NON_STRING_LITERAL_AS_URI =
      const ParserErrorCode(
          'NON_STRING_LITERAL_AS_URI',
          "The URI must be a string literal",
          "Enclose the URI in either single or double quotes.");

  static const ParserErrorCode NON_USER_DEFINABLE_OPERATOR =
      const ParserErrorCode('NON_USER_DEFINABLE_OPERATOR',
          "The operator '{0}' is not user definable");

  static const ParserErrorCode NORMAL_BEFORE_OPTIONAL_PARAMETERS =
      const ParserErrorCode('NORMAL_BEFORE_OPTIONAL_PARAMETERS',
          "Normal parameters must occur before optional parameters");

  static const ParserErrorCode NULLABLE_TYPE_IN_EXTENDS = const ParserErrorCode(
      'NULLABLE_TYPE_IN_EXTENDS',
      "A nullable type cannot be used in an extends clause",
      "Remove the '?' from the type name");

  static const ParserErrorCode NULLABLE_TYPE_IN_IMPLEMENTS =
      const ParserErrorCode(
          'NULLABLE_TYPE_IN_IMPLEMENTS',
          "A nullable type cannot be used in an implements clause",
          "Remove the '?' from the type name");

  static const ParserErrorCode NULLABLE_TYPE_IN_WITH = const ParserErrorCode(
      'NULLABLE_TYPE_IN_WITH',
      "A nullable type cannot be used in a with clause",
      "Remove the '?' from the type name");

  static const ParserErrorCode NULLABLE_TYPE_PARAMETER = const ParserErrorCode(
      'NULLABLE_TYPE_PARAMETER',
      "Type parameters cannot be nullable",
      "Remove the '?' from the type name");

  static const ParserErrorCode POSITIONAL_AFTER_NAMED_ARGUMENT =
      const ParserErrorCode('POSITIONAL_AFTER_NAMED_ARGUMENT',
          "Positional arguments must occur before named arguments");

  static const ParserErrorCode POSITIONAL_PARAMETER_OUTSIDE_GROUP =
      const ParserErrorCode('POSITIONAL_PARAMETER_OUTSIDE_GROUP',
          "Positional parameters must be enclosed in square brackets ('[' and ']')");

  static const ParserErrorCode REDIRECTING_CONSTRUCTOR_WITH_BODY =
      const ParserErrorCode('REDIRECTING_CONSTRUCTOR_WITH_BODY',
          "Redirecting constructors cannot have a body");

  static const ParserErrorCode REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR =
      const ParserErrorCode('REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR',
          "Only factory constructor can specify '=' redirection.");

  static const ParserErrorCode SETTER_IN_FUNCTION = const ParserErrorCode(
      'SETTER_IN_FUNCTION',
      "Setters cannot be defined within methods or functions");

  static const ParserErrorCode STATIC_AFTER_CONST = const ParserErrorCode(
      'STATIC_AFTER_CONST',
      "The modifier 'static' should be before the modifier 'const'");

  static const ParserErrorCode STATIC_AFTER_FINAL = const ParserErrorCode(
      'STATIC_AFTER_FINAL',
      "The modifier 'static' should be before the modifier 'final'");

  static const ParserErrorCode STATIC_AFTER_VAR = const ParserErrorCode(
      'STATIC_AFTER_VAR',
      "The modifier 'static' should be before the modifier 'var'");

  static const ParserErrorCode STATIC_CONSTRUCTOR = const ParserErrorCode(
      'STATIC_CONSTRUCTOR', "Constructors cannot be static");

  static const ParserErrorCode STATIC_GETTER_WITHOUT_BODY =
      const ParserErrorCode(
          'STATIC_GETTER_WITHOUT_BODY', "A 'static' getter must have a body");

  static const ParserErrorCode STATIC_OPERATOR =
      const ParserErrorCode('STATIC_OPERATOR', "Operators cannot be static");

  static const ParserErrorCode STATIC_SETTER_WITHOUT_BODY =
      const ParserErrorCode(
          'STATIC_SETTER_WITHOUT_BODY', "A 'static' setter must have a body");

  static const ParserErrorCode STATIC_TOP_LEVEL_DECLARATION =
      const ParserErrorCode('STATIC_TOP_LEVEL_DECLARATION',
          "Top-level declarations cannot be declared to be 'static'");

  static const ParserErrorCode SWITCH_HAS_CASE_AFTER_DEFAULT_CASE =
      const ParserErrorCode('SWITCH_HAS_CASE_AFTER_DEFAULT_CASE',
          "The 'default' case should be the last case in a switch statement");

  static const ParserErrorCode SWITCH_HAS_MULTIPLE_DEFAULT_CASES =
      const ParserErrorCode('SWITCH_HAS_MULTIPLE_DEFAULT_CASES',
          "The 'default' case can only be declared once");

  static const ParserErrorCode TOP_LEVEL_OPERATOR = const ParserErrorCode(
      'TOP_LEVEL_OPERATOR', "Operators must be declared within a class");

  static const ParserErrorCode TYPEDEF_IN_CLASS = const ParserErrorCode(
      'TYPEDEF_IN_CLASS',
      "Function type aliases cannot be declared inside classes");

  static const ParserErrorCode UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP =
      const ParserErrorCode('UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP',
          "There is no '{0}' to open a parameter group");

  static const ParserErrorCode UNEXPECTED_TOKEN =
      const ParserErrorCode('UNEXPECTED_TOKEN', "Unexpected token '{0}'");

  static const ParserErrorCode WITH_BEFORE_EXTENDS = const ParserErrorCode(
      'WITH_BEFORE_EXTENDS',
      "The extends clause must be before the with clause");

  static const ParserErrorCode WITH_WITHOUT_EXTENDS = const ParserErrorCode(
      'WITH_WITHOUT_EXTENDS',
      "The with clause cannot be used without an extends clause");

  static const ParserErrorCode WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER =
      const ParserErrorCode('WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER',
          "The default value of a positional parameter should be preceeded by '='");

  static const ParserErrorCode WRONG_TERMINATOR_FOR_PARAMETER_GROUP =
      const ParserErrorCode('WRONG_TERMINATOR_FOR_PARAMETER_GROUP',
          "Expected '{0}' to close parameter group");

  static const ParserErrorCode VAR_AND_TYPE = const ParserErrorCode(
      'VAR_AND_TYPE',
      "Variables cannot be declared using both 'var' and a type name; remove the 'var'");

  static const ParserErrorCode VAR_AS_TYPE_NAME = const ParserErrorCode(
      'VAR_AS_TYPE_NAME', "The keyword 'var' cannot be used as a type name");

  static const ParserErrorCode VAR_CLASS = const ParserErrorCode(
      'VAR_CLASS', "Classes cannot be declared to be 'var'");

  static const ParserErrorCode VAR_ENUM =
      const ParserErrorCode('VAR_ENUM', "Enums cannot be declared to be 'var'");

  static const ParserErrorCode VAR_RETURN_TYPE = const ParserErrorCode(
      'VAR_RETURN_TYPE', "The return type cannot be 'var'");

  static const ParserErrorCode VAR_TYPEDEF = const ParserErrorCode(
      'VAR_TYPEDEF', "Type aliases cannot be declared to be 'var'");

  static const ParserErrorCode VOID_PARAMETER = const ParserErrorCode(
      'VOID_PARAMETER', "Parameters cannot have a type of 'void'");

  static const ParserErrorCode VOID_VARIABLE = const ParserErrorCode(
      'VOID_VARIABLE', "Variables cannot have a type of 'void'");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const ParserErrorCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.SYNTACTIC_ERROR;
}

/**
 * The error codes used for errors detected by the scanner.
 */
class ScannerErrorCode extends ErrorCode {
  static const ScannerErrorCode ILLEGAL_CHARACTER =
      const ScannerErrorCode('ILLEGAL_CHARACTER', "Illegal character {0}");

  static const ScannerErrorCode MISSING_DIGIT =
      const ScannerErrorCode('MISSING_DIGIT', "Decimal digit expected");

  static const ScannerErrorCode MISSING_HEX_DIGIT =
      const ScannerErrorCode('MISSING_HEX_DIGIT', "Hexidecimal digit expected");

  static const ScannerErrorCode MISSING_QUOTE =
      const ScannerErrorCode('MISSING_QUOTE', "Expected quote (' or \")");

  static const ScannerErrorCode UNABLE_GET_CONTENT = const ScannerErrorCode(
      'UNABLE_GET_CONTENT', "Unable to get content: {0}");

  static const ScannerErrorCode UNTERMINATED_MULTI_LINE_COMMENT =
      const ScannerErrorCode(
          'UNTERMINATED_MULTI_LINE_COMMENT', "Unterminated multi-line comment");

  static const ScannerErrorCode UNTERMINATED_STRING_LITERAL =
      const ScannerErrorCode(
          'UNTERMINATED_STRING_LITERAL', "Unterminated string literal");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const ScannerErrorCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.SYNTACTIC_ERROR;
}
