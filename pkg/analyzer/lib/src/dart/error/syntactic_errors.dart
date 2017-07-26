// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The errors produced during syntactic analysis (scanning and parsing).
 */
library analyzer.src.dart.error.syntactic_errors;

import 'package:analyzer/error/error.dart';

export 'package:front_end/src/scanner/errors.dart' show ScannerErrorCode;

/**
 * The error codes used for errors detected by the parser. The convention for
 * this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what
 * is wrong and, when appropriate, how the problem can be corrected.
 */
class ParserErrorCode extends ErrorCode {
  static const ParserErrorCode ABSTRACT_CLASS_MEMBER = const ParserErrorCode(
      'ABSTRACT_CLASS_MEMBER',
      "Members of classes can't be declared to be 'abstract'.",
      "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ABSTRACT_ENUM = const ParserErrorCode(
      'ABSTRACT_ENUM',
      "Enums can't be declared to be 'abstract'.",
      "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ABSTRACT_STATIC_METHOD = const ParserErrorCode(
      'ABSTRACT_STATIC_METHOD',
      "Static methods can't be declared to be 'abstract'.",
      "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ABSTRACT_TOP_LEVEL_FUNCTION =
      const ParserErrorCode(
          'ABSTRACT_TOP_LEVEL_FUNCTION',
          "Top-level functions can't be declared to be 'abstract'.",
          "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ABSTRACT_TOP_LEVEL_VARIABLE =
      const ParserErrorCode(
          'ABSTRACT_TOP_LEVEL_VARIABLE',
          "Top-level variables can't be declared to be 'abstract'.",
          "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ABSTRACT_TYPEDEF = const ParserErrorCode(
      'ABSTRACT_TYPEDEF',
      "Typedefs can't be declared to be 'abstract'.",
      "Try removing the keyword 'abstract'.");

  static const ParserErrorCode ANNOTATION_ON_ENUM_CONSTANT =
      const ParserErrorCode(
          'ANNOTATION_ON_ENUM_CONSTANT',
          "Enum constants can't have annotations.",
          "Try removing the annotation.");

  /**
   * 16.32 Identifier Reference: It is a compile-time error if any of the
   * identifiers async, await, or yield is used as an identifier in a function
   * body marked with either async, async*, or sync*.
   */
  static const ParserErrorCode ASYNC_KEYWORD_USED_AS_IDENTIFIER =
      const ParserErrorCode(
          'ASYNC_KEYWORD_USED_AS_IDENTIFIER',
          "The keywords 'async', 'await', and 'yield' can't be used as "
          "identifiers in an asynchronous or generator function.");

  static const ParserErrorCode BREAK_OUTSIDE_OF_LOOP = const ParserErrorCode(
      'BREAK_OUTSIDE_OF_LOOP',
      "A break statement can't be used outside of a loop or switch statement.",
      "Try removing the break statement.");

  static const ParserErrorCode CLASS_IN_CLASS = const ParserErrorCode(
      'CLASS_IN_CLASS',
      "Classes can't be declared inside other classes.",
      "Try moving the class to the top-level.");

  static const ParserErrorCode COLON_IN_PLACE_OF_IN = const ParserErrorCode(
      'COLON_IN_PLACE_OF_IN',
      "For-in loops use 'in' rather than a colon.",
      "Try replacing the colon with the keyword 'in'.");

  static const ParserErrorCode CONST_AND_COVARIANT = const ParserErrorCode(
      'CONST_AND_COVARIANT',
      "Members can't be declared to be both 'const' and 'covariant'.",
      "Try removing either the 'const' or 'covariant' keyword.");

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
      "Try removing the 'const' keyword. If you're trying to indicate that "
      "instances of the class can be constants, place the 'const' keyword on "
      "the class' constructor(s).");

  static const ParserErrorCode CONST_CONSTRUCTOR_WITH_BODY =
      const ParserErrorCode(
          'CONST_CONSTRUCTOR_WITH_BODY',
          "Const constructors can't have a body.",
          "Try removing either the 'const' keyword or the body.");

  static const ParserErrorCode CONST_ENUM = const ParserErrorCode(
      'CONST_ENUM',
      "Enums can't be declared to be 'const'.",
      "Try removing the 'const' keyword.");

  static const ParserErrorCode CONST_FACTORY = const ParserErrorCode(
      'CONST_FACTORY',
      "Only redirecting factory constructors can be declared to be 'const'.",
      "Try removing the 'const' keyword, or "
      "replacing the body with '=' followed by a valid target.");

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
      "A continue statement can't be used outside of a loop or switch statement.",
      "Try removing the continue statement.");

  static const ParserErrorCode CONTINUE_WITHOUT_LABEL_IN_CASE = const ParserErrorCode(
      'CONTINUE_WITHOUT_LABEL_IN_CASE',
      "A continue statement in a switch statement must have a label as a target.",
      "Try adding a label associated with one of the case clauses to the continue statement.");

  static const ParserErrorCode COVARIANT_AFTER_VAR = const ParserErrorCode(
      'COVARIANT_AFTER_VAR',
      "The modifier 'covariant' should be before the modifier 'var'.",
      "Try re-ordering the modifiers.");

  static const ParserErrorCode COVARIANT_AND_STATIC = const ParserErrorCode(
      'COVARIANT_AND_STATIC',
      "Members can't be declared to be both 'covariant' and 'static'.",
      "Try removing either the 'covariant' or 'static' keyword.");

  static const ParserErrorCode COVARIANT_MEMBER = const ParserErrorCode(
      'COVARIANT_MEMBER',
      "Getters, setters and methods can't be declared to be 'covariant'.",
      "Try removing the 'covariant' keyword.");

  static const ParserErrorCode COVARIANT_TOP_LEVEL_DECLARATION =
      const ParserErrorCode(
          'COVARIANT_TOP_LEVEL_DECLARATION',
          "Top-level declarations can't be declared to be covariant.",
          "Try removing the keyword 'covariant'.");

  static const ParserErrorCode COVARIANT_CONSTRUCTOR = const ParserErrorCode(
      'COVARIANT_CONSTRUCTOR',
      "A constructor can't be declared to be 'covariant'.",
      "Try removing the keyword 'covariant'.");

  static const ParserErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPE =
      const ParserErrorCode(
          'DEFAULT_VALUE_IN_FUNCTION_TYPE',
          "Parameters in a function type cannot have default values",
          "Try removing the default value.");

  static const ParserErrorCode DIRECTIVE_AFTER_DECLARATION =
      const ParserErrorCode(
          'DIRECTIVE_AFTER_DECLARATION',
          "Directives must appear before any declarations.",
          "Try moving the directive before any declarations.");

  /**
   * Parameters:
   * 0: the label that was duplicated
   */
  static const ParserErrorCode DUPLICATE_LABEL_IN_SWITCH_STATEMENT =
      const ParserErrorCode(
          'DUPLICATE_LABEL_IN_SWITCH_STATEMENT',
          "The label '{0}' was already used in this switch statement.",
          "Try choosing a different name for this label.");

  /**
   * Parameters:
   * 0: the modifier that was duplicated
   */
  static const ParserErrorCode DUPLICATED_MODIFIER = const ParserErrorCode(
      'DUPLICATED_MODIFIER',
      "The modifier '{0}' was already specified.",
      "Try removing all but one occurance of the modifier.");

  static const ParserErrorCode EMPTY_ENUM_BODY = const ParserErrorCode(
      'EMPTY_ENUM_BODY',
      "An enum must declare at least one constant name.",
      "Try declaring a constant.");

  static const ParserErrorCode ENUM_IN_CLASS = const ParserErrorCode(
      'ENUM_IN_CLASS',
      "Enums can't be declared inside classes.",
      "Try moving the enum to the top-level.");

  static const ParserErrorCode EQUALITY_CANNOT_BE_EQUALITY_OPERAND =
      const ParserErrorCode(
          'EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
          "An equality expression can't be an operand of another equality expression.",
          "Try re-writing the expression.");

  static const ParserErrorCode EXPECTED_CASE_OR_DEFAULT = const ParserErrorCode(
      'EXPECTED_CASE_OR_DEFAULT',
      "Expected 'case' or 'default'.",
      "Try placing this code inside a case clause.");

  static const ParserErrorCode EXPECTED_CLASS_MEMBER = const ParserErrorCode(
      'EXPECTED_CLASS_MEMBER',
      "Expected a class member.",
      "Try placing this code inside a class member.");

  static const ParserErrorCode EXPECTED_EXECUTABLE = const ParserErrorCode(
      'EXPECTED_EXECUTABLE',
      "Expected a method, getter, setter or operator declaration.",
      "This appears to be incomplete code. Try removing it or completing it.");

  static const ParserErrorCode EXPECTED_LIST_OR_MAP_LITERAL =
      const ParserErrorCode(
          'EXPECTED_LIST_OR_MAP_LITERAL',
          "Expected a list or map literal.",
          "Try inserting a list or map literal, or remove the type arguments.");

  static const ParserErrorCode EXPECTED_STRING_LITERAL = const ParserErrorCode(
      'EXPECTED_STRING_LITERAL', "Expected a string literal.");

  /**
   * Parameters:
   * 0: the token that was expected but not found
   */
  static const ParserErrorCode EXPECTED_TOKEN =
      const ParserErrorCode('EXPECTED_TOKEN', "Expected to find '{0}'.");

  static const ParserErrorCode EXPECTED_TYPE_NAME =
      const ParserErrorCode('EXPECTED_TYPE_NAME', "Expected a type name.");

  static const ParserErrorCode EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE =
      const ParserErrorCode(
          'EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
          "Export directives must preceed part directives.",
          "Try moving the export directives before the part directives.");

  static const ParserErrorCode EXTERNAL_AFTER_CONST = const ParserErrorCode(
      'EXTERNAL_AFTER_CONST',
      "The modifier 'external' should be before the modifier 'const'.",
      "Try re-ordering the modifiers.");

  static const ParserErrorCode EXTERNAL_AFTER_FACTORY = const ParserErrorCode(
      'EXTERNAL_AFTER_FACTORY',
      "The modifier 'external' should be before the modifier 'factory'.",
      "Try re-ordering the modifiers.");

  static const ParserErrorCode EXTERNAL_AFTER_STATIC = const ParserErrorCode(
      'EXTERNAL_AFTER_STATIC',
      "The modifier 'external' should be before the modifier 'static'.",
      "Try re-ordering the modifiers.");

  static const ParserErrorCode EXTERNAL_CLASS = const ParserErrorCode(
      'EXTERNAL_CLASS',
      "Classes can't be declared to be 'external'.",
      "Try removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_CONSTRUCTOR_WITH_BODY =
      const ParserErrorCode(
          'EXTERNAL_CONSTRUCTOR_WITH_BODY',
          "External constructors can't have a body.",
          "Try removing the body of the constructor, or "
          "removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_ENUM = const ParserErrorCode(
      'EXTERNAL_ENUM',
      "Enums can't be declared to be 'external'.",
      "Try removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_FIELD = const ParserErrorCode(
      'EXTERNAL_FIELD',
      "Fields can't be declared to be 'external'.",
      "Try removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_GETTER_WITH_BODY =
      const ParserErrorCode(
          'EXTERNAL_GETTER_WITH_BODY',
          "External getters can't have a body.",
          "Try removing the body of the getter, or "
          "removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_METHOD_WITH_BODY =
      const ParserErrorCode(
          'EXTERNAL_METHOD_WITH_BODY',
          "External methods can't have a body.",
          "Try removing the body of the method, or "
          "removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_OPERATOR_WITH_BODY =
      const ParserErrorCode(
          'EXTERNAL_OPERATOR_WITH_BODY',
          "External operators can't have a body.",
          "Try removing the body of the operator, or "
          "removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_SETTER_WITH_BODY =
      const ParserErrorCode(
          'EXTERNAL_SETTER_WITH_BODY',
          "External setters can't have a body.",
          "Try removing the body of the setter, or "
          "removing the keyword 'external'.");

  static const ParserErrorCode EXTERNAL_TYPEDEF = const ParserErrorCode(
      'EXTERNAL_TYPEDEF',
      "Typedefs can't be declared to be 'external'.",
      "Try removing the keyword 'external'.");

  static const ParserErrorCode FACTORY_TOP_LEVEL_DECLARATION =
      const ParserErrorCode(
          'FACTORY_TOP_LEVEL_DECLARATION',
          "Top-level declarations can't be declared to be 'factory'.",
          "Try removing the keyword 'factory'.");

  static const ParserErrorCode FACTORY_WITH_INITIALIZERS = const ParserErrorCode(
      'FACTORY_WITH_INITIALIZERS',
      "A 'factory' constructor can't have initializers.",
      "Try removing the 'factory' keyword to make this a generative constructor, or "
      "removing the initializers.");

  static const ParserErrorCode FACTORY_WITHOUT_BODY = const ParserErrorCode(
      'FACTORY_WITHOUT_BODY',
      "A non-redirecting 'factory' constructor must have a body.",
      "Try adding a body to the constructor.");

  static const ParserErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR =
      const ParserErrorCode(
          'FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
          "Field formal parameters can only be used in a constructor.",
          "Try replacing the field formal parameter with a normal parameter.");

  static const ParserErrorCode FINAL_AND_COVARIANT = const ParserErrorCode(
      'FINAL_AND_COVARIANT',
      "Members can't be declared to be both 'final' and 'covariant'.",
      "Try removing either the 'final' or 'covariant' keyword.");

  static const ParserErrorCode FINAL_AND_VAR = const ParserErrorCode(
      'FINAL_AND_VAR',
      "Members can't be declared to be both 'final' and 'var'.",
      "Try removing the keyword 'var'.");

  static const ParserErrorCode FINAL_CLASS = const ParserErrorCode(
      'FINAL_CLASS',
      "Classes can't be declared to be 'final'.",
      "Try removing the keyword 'final'.");

  static const ParserErrorCode FINAL_CONSTRUCTOR = const ParserErrorCode(
      'FINAL_CONSTRUCTOR',
      "A constructor can't be declared to be 'final'.",
      "Try removing the keyword 'final'.");

  static const ParserErrorCode FINAL_ENUM = const ParserErrorCode(
      'FINAL_ENUM',
      "Enums can't be declared to be 'final'.",
      "Try removing the keyword 'final'.");

  static const ParserErrorCode FINAL_METHOD = const ParserErrorCode(
      'FINAL_METHOD',
      "Getters, setters and methods can't be declared to be 'final'.",
      "Try removing the keyword 'final'.");

  static const ParserErrorCode FINAL_TYPEDEF = const ParserErrorCode(
      'FINAL_TYPEDEF',
      "Typedefs can't be declared to be 'final'.",
      "Try removing the keyword 'final'.");

  static const ParserErrorCode FUNCTION_TYPED_PARAMETER_VAR = const ParserErrorCode(
      'FUNCTION_TYPED_PARAMETER_VAR',
      "Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.",
      "Try replacing the keyword with a return type.");

  static const ParserErrorCode GETTER_IN_FUNCTION = const ParserErrorCode(
      'GETTER_IN_FUNCTION',
      "Getters can't be defined within methods or functions.",
      "Try moving the getter outside the method or function, or "
      "converting the getter to a function.");

  static const ParserErrorCode GETTER_WITH_PARAMETERS = const ParserErrorCode(
      'GETTER_WITH_PARAMETERS',
      "Getters must be declared without a parameter list.",
      "Try removing the parameter list, or "
      "removing the keyword 'get' to define a method rather than a getter.");

  static const ParserErrorCode ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE =
      const ParserErrorCode('ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE',
          "Illegal assignment to non-assignable expression.");

  static const ParserErrorCode IMPLEMENTS_BEFORE_EXTENDS =
      const ParserErrorCode(
          'IMPLEMENTS_BEFORE_EXTENDS',
          "The extends clause must be before the implements clause.",
          "Try moving the extends clause before the implements clause.");

  static const ParserErrorCode IMPLEMENTS_BEFORE_WITH = const ParserErrorCode(
      'IMPLEMENTS_BEFORE_WITH',
      "The with clause must be before the implements clause.",
      "Try moving the with clause before the implements clause.");

  static const ParserErrorCode IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE =
      const ParserErrorCode(
          'IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
          "Import directives must preceed part directives.",
          "Try moving the import directives before the part directives.");

  static const ParserErrorCode INITIALIZED_VARIABLE_IN_FOR_EACH =
      const ParserErrorCode(
          'INITIALIZED_VARIABLE_IN_FOR_EACH',
          "The loop variable in a for-each loop can't be initialized.",
          "Try removing the initializer, or using a different kind of loop.");

  static const ParserErrorCode INVALID_AWAIT_IN_FOR = const ParserErrorCode(
      'INVALID_AWAIT_IN_FOR',
      "The keyword 'await' isn't allowed for a normal 'for' statement.",
      "Try removing the keyword, or use a for-each statement.");

  /**
   * Parameters:
   * 0: the invalid escape sequence
   */
  static const ParserErrorCode INVALID_CODE_POINT = const ParserErrorCode(
      'INVALID_CODE_POINT',
      "The escape sequence '{0}' isn't a valid code point.");

  static const ParserErrorCode INVALID_COMMENT_REFERENCE = const ParserErrorCode(
      'INVALID_COMMENT_REFERENCE',
      "Comment references should contain a possibly prefixed identifier and "
      "can start with 'new', but shouldn't contain anything else.");

  static const ParserErrorCode INVALID_CONSTRUCTOR_NAME = const ParserErrorCode(
      'INVALID_CONSTRUCTOR_NAME',
      "The keyword '{0}' cannot be used to name a constructor.",
      "Try giving the constructor a different name.");

  static const ParserErrorCode INVALID_GENERIC_FUNCTION_TYPE =
      const ParserErrorCode(
          'INVALID_GENERIC_FUNCTION_TYPE',
          "Invalid generic function type.",
          "Try using a generic function type (returnType 'Function(' parameters ')').");

  static const ParserErrorCode INVALID_HEX_ESCAPE = const ParserErrorCode(
      'INVALID_HEX_ESCAPE',
      "An escape sequence starting with '\\x' must be followed by 2 hexidecimal digits.");

  static const ParserErrorCode INVALID_LITERAL_IN_CONFIGURATION =
      const ParserErrorCode(
          'INVALID_LITERAL_IN_CONFIGURATION',
          "The literal in a configuration can't contain interpolation.",
          "Try removing the interpolation expressions.");

  /**
   * Parameters:
   * 0: the operator that is invalid
   */
  static const ParserErrorCode INVALID_OPERATOR = const ParserErrorCode(
      'INVALID_OPERATOR', "The string '{0}' isn't a user-definable operator.");

  /**
   * Parameters:
   * 0: the operator being applied to 'super'
   */
  static const ParserErrorCode INVALID_OPERATOR_FOR_SUPER =
      const ParserErrorCode('INVALID_OPERATOR_FOR_SUPER',
          "The operator '{0}' can't be used with 'super'.");

  static const ParserErrorCode INVALID_STAR_AFTER_ASYNC = const ParserErrorCode(
      'INVALID_STAR_AFTER_ASYNC',
      "The modifier 'async*' isn't allowed for an expression function body.",
      "Try converting the body to a block.");

  static const ParserErrorCode INVALID_SYNC = const ParserErrorCode(
      'INVALID_SYNC',
      "The modifier 'sync' isn't allowed for an expression function body.",
      "Try converting the body to a block.");

  static const ParserErrorCode INVALID_UNICODE_ESCAPE = const ParserErrorCode(
      'INVALID_UNICODE_ESCAPE',
      "An escape sequence starting with '\\u' must be followed by 4 "
      "hexidecimal digits or from 1 to 6 digits between '{' and '}'.");

  static const ParserErrorCode LIBRARY_DIRECTIVE_NOT_FIRST =
      const ParserErrorCode(
          'LIBRARY_DIRECTIVE_NOT_FIRST',
          "The library directive must appear before all other directives.",
          "Try moving the library directive before any other directives.");

  static const ParserErrorCode LOCAL_FUNCTION_DECLARATION_MODIFIER =
      const ParserErrorCode(
          'LOCAL_FUNCTION_DECLARATION_MODIFIER',
          "Local function declarations can't specify any modifiers.",
          "Try removing the modifier.");

  static const ParserErrorCode MISSING_ASSIGNABLE_SELECTOR =
      const ParserErrorCode(
          'MISSING_ASSIGNABLE_SELECTOR',
          "Missing selector such as '.<identifier>' or '[0]'.",
          "Try adding a selector.");

  static const ParserErrorCode MISSING_ASSIGNMENT_IN_INITIALIZER =
      const ParserErrorCode(
          'MISSING_ASSIGNMENT_IN_INITIALIZER',
          "Expected an assignment after the field name.",
          "Try adding an assignment to initialize the field.");

  static const ParserErrorCode MISSING_CATCH_OR_FINALLY = const ParserErrorCode(
      'MISSING_CATCH_OR_FINALLY',
      "A try statement must have either a catch or finally clause.",
      "Try adding either a catch or finally clause, or "
      "remove the try statement.");

  static const ParserErrorCode MISSING_CLASS_BODY = const ParserErrorCode(
      'MISSING_CLASS_BODY',
      "A class definition must have a body, even if it is empty.",
      "Try adding a class body.");

  static const ParserErrorCode MISSING_CLOSING_PARENTHESIS =
      const ParserErrorCode(
          'MISSING_CLOSING_PARENTHESIS',
          "The closing parenthesis is missing.",
          "Try adding the closing parenthesis.");

  static const ParserErrorCode MISSING_CONST_FINAL_VAR_OR_TYPE = const ParserErrorCode(
      'MISSING_CONST_FINAL_VAR_OR_TYPE',
      "Variables must be declared using the keywords 'const', 'final', 'var' or a type name.",
      "Try adding the name of the type of the variable or the keyword 'var'.");

  static const ParserErrorCode MISSING_ENUM_BODY = const ParserErrorCode(
      'MISSING_ENUM_BODY',
      "An enum definition must have a body with at least one constant name.",
      "Try adding a body and defining at least one constant.");

  static const ParserErrorCode MISSING_EXPRESSION_IN_INITIALIZER =
      const ParserErrorCode(
          'MISSING_EXPRESSION_IN_INITIALIZER',
          "Expected an expression after the assignment operator.",
          "Try adding the value to be assigned, or "
          "remove the assignment operator.");

  static const ParserErrorCode MISSING_EXPRESSION_IN_THROW =
      const ParserErrorCode(
          'MISSING_EXPRESSION_IN_THROW',
          "Missing expression after 'throw'.",
          "Try using 'rethrow' to throw the caught exception.");

  static const ParserErrorCode MISSING_FUNCTION_BODY = const ParserErrorCode(
      'MISSING_FUNCTION_BODY',
      "A function body must be provided.",
      "Try adding a function body.");

  static const ParserErrorCode MISSING_FUNCTION_KEYWORD = const ParserErrorCode(
      'MISSING_FUNCTION_KEYWORD',
      "Function types must have the keyword 'Function' before the parameter list.",
      "Try adding the keyword 'Function'.");

  static const ParserErrorCode MISSING_FUNCTION_PARAMETERS =
      const ParserErrorCode(
          'MISSING_FUNCTION_PARAMETERS',
          "Functions must have an explicit list of parameters.",
          "Try adding a parameter list.");

  static const ParserErrorCode MISSING_GET = const ParserErrorCode(
      'MISSING_GET',
      "Getters must have the keyword 'get' before the getter name.",
      "Try adding the keyword 'get'.");

  static const ParserErrorCode MISSING_IDENTIFIER =
      const ParserErrorCode('MISSING_IDENTIFIER', "Expected an identifier.");

  static const ParserErrorCode MISSING_INITIALIZER =
      const ParserErrorCode('MISSING_INITIALIZER', "Expected an initializer.");

  static const ParserErrorCode MISSING_KEYWORD_OPERATOR = const ParserErrorCode(
      'MISSING_KEYWORD_OPERATOR',
      "Operator declarations must be preceeded by the keyword 'operator'.",
      "Try adding the keyword 'operator'.");

  static const ParserErrorCode MISSING_METHOD_PARAMETERS =
      const ParserErrorCode(
          'MISSING_METHOD_PARAMETERS',
          "Methods must have an explicit list of parameters.",
          "Try adding a parameter list.");

  static const ParserErrorCode MISSING_NAME_FOR_NAMED_PARAMETER =
      const ParserErrorCode(
          'MISSING_NAME_FOR_NAMED_PARAMETER',
          "Named parameters in a function type must have a name",
          "Try providing a name for the parameter or removing the curly braces.");

  static const ParserErrorCode MISSING_NAME_IN_LIBRARY_DIRECTIVE =
      const ParserErrorCode(
          'MISSING_NAME_IN_LIBRARY_DIRECTIVE',
          "Library directives must include a library name.",
          "Try adding a library name after the keyword 'library', or "
          "remove the library directive if the library doesn't have any parts.");

  static const ParserErrorCode MISSING_NAME_IN_PART_OF_DIRECTIVE =
      const ParserErrorCode(
          'MISSING_NAME_IN_PART_OF_DIRECTIVE',
          "Part-of directives must include a library name.",
          "Try adding a library name after the 'of'.");

  static const ParserErrorCode MISSING_PREFIX_IN_DEFERRED_IMPORT =
      const ParserErrorCode(
          'MISSING_PREFIX_IN_DEFERRED_IMPORT',
          "Deferred imports must have a prefix.",
          "Try adding a prefix to the import.");

  static const ParserErrorCode MISSING_STAR_AFTER_SYNC = const ParserErrorCode(
      'MISSING_STAR_AFTER_SYNC',
      "The modifier 'sync' must be followed by a star ('*').",
      "Try removing the modifier, or add a star.");

  static const ParserErrorCode MISSING_STATEMENT =
      const ParserErrorCode('MISSING_STATEMENT', "Expected a statement.");

  /**
   * Parameters:
   * 0: the terminator that is missing
   */
  static const ParserErrorCode MISSING_TERMINATOR_FOR_PARAMETER_GROUP =
      const ParserErrorCode(
          'MISSING_TERMINATOR_FOR_PARAMETER_GROUP',
          "There is no '{0}' to close the parameter group.",
          "Try inserting a '{0}' at the end of the group.");

  static const ParserErrorCode MISSING_TYPEDEF_PARAMETERS =
      const ParserErrorCode(
          'MISSING_TYPEDEF_PARAMETERS',
          "Typedefs must have an explicit list of parameters.",
          "Try adding a parameter list.");

  static const ParserErrorCode MISSING_VARIABLE_IN_FOR_EACH = const ParserErrorCode(
      'MISSING_VARIABLE_IN_FOR_EACH',
      "A loop variable must be declared in a for-each loop before the 'in', but none was found.",
      "Try declaring a loop variable.");

  static const ParserErrorCode MIXED_PARAMETER_GROUPS = const ParserErrorCode(
      'MIXED_PARAMETER_GROUPS',
      "Can't have both positional and named parameters in a single parameter list.",
      "Try choosing a single style of optional parameters.");

  static const ParserErrorCode MULTIPLE_EXTENDS_CLAUSES = const ParserErrorCode(
      'MULTIPLE_EXTENDS_CLAUSES',
      "Each class definition can have at most one extends clause.",
      "Try choosing one superclass and define your class to implement (or mix in) the others.");

  static const ParserErrorCode MULTIPLE_IMPLEMENTS_CLAUSES =
      const ParserErrorCode(
          'MULTIPLE_IMPLEMENTS_CLAUSES',
          "Each class definition can have at most one implements clause.",
          "Try combining all of the implements clauses into a single clause.");

  static const ParserErrorCode MULTIPLE_LIBRARY_DIRECTIVES =
      const ParserErrorCode(
          'MULTIPLE_LIBRARY_DIRECTIVES',
          "Only one library directive may be declared in a file.",
          "Try removing all but one of the library directives.");

  static const ParserErrorCode MULTIPLE_NAMED_PARAMETER_GROUPS =
      const ParserErrorCode(
          'MULTIPLE_NAMED_PARAMETER_GROUPS',
          "Can't have multiple groups of named parameters in a single parameter list.",
          "Try combining all of the groups into a single group.");

  static const ParserErrorCode MULTIPLE_PART_OF_DIRECTIVES =
      const ParserErrorCode(
          'MULTIPLE_PART_OF_DIRECTIVES',
          "Only one part-of directive may be declared in a file.",
          "Try removing all but one of the part-of directives.");

  static const ParserErrorCode MULTIPLE_POSITIONAL_PARAMETER_GROUPS =
      const ParserErrorCode(
          'MULTIPLE_POSITIONAL_PARAMETER_GROUPS',
          "Can't have multiple groups of positional parameters in a single parameter list.",
          "Try combining all of the groups into a single group.");

  /**
   * Parameters:
   * 0: the number of variables being declared
   */
  static const ParserErrorCode MULTIPLE_VARIABLES_IN_FOR_EACH =
      const ParserErrorCode(
          'MULTIPLE_VARIABLES_IN_FOR_EACH',
          "A single loop variable must be declared in a for-each loop before "
          "the 'in', but {0} were found.",
          "Try moving all but one of the declarations inside the loop body.");

  static const ParserErrorCode MULTIPLE_WITH_CLAUSES = const ParserErrorCode(
      'MULTIPLE_WITH_CLAUSES',
      "Each class definition can have at most one with clause.",
      "Try combining all of the with clauses into a single clause.");

  static const ParserErrorCode NAMED_FUNCTION_EXPRESSION = const ParserErrorCode(
      'NAMED_FUNCTION_EXPRESSION',
      "Function expressions can't be named.",
      "Try removing the name, or "
      "moving the function expression to a function declaration statement.");

  static const ParserErrorCode NAMED_FUNCTION_TYPE = const ParserErrorCode(
      'NAMED_FUNCTION_TYPE',
      "Function types can't be named.",
      "Try replacing the name with the keyword 'Function'.");

  static const ParserErrorCode NAMED_PARAMETER_OUTSIDE_GROUP =
      const ParserErrorCode(
          'NAMED_PARAMETER_OUTSIDE_GROUP',
          "Named parameters must be enclosed in curly braces ('{' and '}').",
          "Try surrounding the named parameters in curly braces.");

  static const ParserErrorCode NATIVE_CLAUSE_IN_NON_SDK_CODE =
      const ParserErrorCode(
          'NATIVE_CLAUSE_IN_NON_SDK_CODE',
          "Native clause can only be used in the SDK and code that is loaded "
          "through native extensions.",
          "Try removing the native clause.");

  static const ParserErrorCode NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE =
      const ParserErrorCode(
          'NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE',
          "Native functions can only be declared in the SDK and code that is "
          "loaded through native extensions.",
          "Try removing the word 'native'.");

  static const ParserErrorCode NON_CONSTRUCTOR_FACTORY = const ParserErrorCode(
      'NON_CONSTRUCTOR_FACTORY',
      "Only a constructor can be declared to be a factory.",
      "Try removing the keyword 'factory'.");

  static const ParserErrorCode NON_IDENTIFIER_LIBRARY_NAME =
      const ParserErrorCode(
          'NON_IDENTIFIER_LIBRARY_NAME',
          "The name of a library must be an identifier.",
          "Try using an identifier as the name of the library.");

  static const ParserErrorCode NON_PART_OF_DIRECTIVE_IN_PART =
      const ParserErrorCode(
          'NON_PART_OF_DIRECTIVE_IN_PART',
          "The part-of directive must be the only directive in a part.",
          "Try removing the other directives, or "
          "moving them to the library for which this is a part.");

  static const ParserErrorCode NON_STRING_LITERAL_AS_URI =
      const ParserErrorCode(
          'NON_STRING_LITERAL_AS_URI',
          "The URI must be a string literal.",
          "Try enclosing the URI in either single or double quotes.");

  /**
   * Parameters:
   * 0: the operator that the user is trying to define
   */
  static const ParserErrorCode NON_USER_DEFINABLE_OPERATOR =
      const ParserErrorCode('NON_USER_DEFINABLE_OPERATOR',
          "The operator '{0}' isn't user definable.");

  static const ParserErrorCode NORMAL_BEFORE_OPTIONAL_PARAMETERS =
      const ParserErrorCode(
          'NORMAL_BEFORE_OPTIONAL_PARAMETERS',
          "Normal parameters must occur before optional parameters.",
          "Try moving all of the normal parameters before the optional parameters.");

  static const ParserErrorCode NULLABLE_TYPE_IN_EXTENDS = const ParserErrorCode(
      'NULLABLE_TYPE_IN_EXTENDS',
      "A nullable type can't be used in an extends clause.",
      "Try removing the '?' from the type name.");

  static const ParserErrorCode NULLABLE_TYPE_IN_IMPLEMENTS =
      const ParserErrorCode(
          'NULLABLE_TYPE_IN_IMPLEMENTS',
          "A nullable type can't be used in an implements clause.",
          "Try removing the '?' from the type name.");

  static const ParserErrorCode NULLABLE_TYPE_IN_WITH = const ParserErrorCode(
      'NULLABLE_TYPE_IN_WITH',
      "A nullable type can't be used in a with clause.",
      "Try removing the '?' from the type name.");

  static const ParserErrorCode NULLABLE_TYPE_PARAMETER = const ParserErrorCode(
      'NULLABLE_TYPE_PARAMETER',
      "Type parameters can't be nullable.",
      "Try removing the '?' from the type name.");

  static const ParserErrorCode POSITIONAL_AFTER_NAMED_ARGUMENT =
      const ParserErrorCode(
          'POSITIONAL_AFTER_NAMED_ARGUMENT',
          "Positional arguments must occur before named arguments.",
          "Try moving all of the positional arguments before the named arguments.");

  static const ParserErrorCode POSITIONAL_PARAMETER_OUTSIDE_GROUP =
      const ParserErrorCode(
          'POSITIONAL_PARAMETER_OUTSIDE_GROUP',
          "Positional parameters must be enclosed in square brackets ('[' and ']').",
          "Try surrounding the positional parameters in square brackets.");

  static const ParserErrorCode REDIRECTING_CONSTRUCTOR_WITH_BODY =
      const ParserErrorCode(
          'REDIRECTING_CONSTRUCTOR_WITH_BODY',
          "Redirecting constructors can't have a body.",
          "Try removing the body, or "
          "not making this a redirecting constructor.");

  static const ParserErrorCode REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR =
      const ParserErrorCode(
          'REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR',
          "Only factory constructor can specify '=' redirection.",
          "Try making this a factory constructor, or "
          "not making this a redirecting constructor.");

  static const ParserErrorCode SETTER_IN_FUNCTION = const ParserErrorCode(
      'SETTER_IN_FUNCTION',
      "Setters can't be defined within methods or functions.",
      "Try moving the setter outside the method or function.");

  static const ParserErrorCode STACK_OVERFLOW = const ParserErrorCode(
      'STACK_OVERFLOW',
      "The file has too many nested expressions or statements.",
      "Try simplifying the code.");

  static const ParserErrorCode STATIC_AFTER_CONST = const ParserErrorCode(
      'STATIC_AFTER_CONST',
      "The modifier 'static' should be before the modifier 'const'.",
      "Try re-ordering the modifiers.");

  static const ParserErrorCode STATIC_AFTER_FINAL = const ParserErrorCode(
      'STATIC_AFTER_FINAL',
      "The modifier 'static' should be before the modifier 'final'.",
      "Try re-ordering the modifiers.");

  static const ParserErrorCode STATIC_AFTER_VAR = const ParserErrorCode(
      'STATIC_AFTER_VAR',
      "The modifier 'static' should be before the modifier 'var'.",
      "Try re-ordering the modifiers.");

  static const ParserErrorCode STATIC_CONSTRUCTOR = const ParserErrorCode(
      'STATIC_CONSTRUCTOR',
      "Constructors can't be static.",
      "Try removing the keyword 'static'.");

  static const ParserErrorCode STATIC_GETTER_WITHOUT_BODY =
      const ParserErrorCode(
          'STATIC_GETTER_WITHOUT_BODY',
          "A 'static' getter must have a body.",
          "Try adding a body to the getter, or removing the keyword 'static'.");

  static const ParserErrorCode STATIC_OPERATOR = const ParserErrorCode(
      'STATIC_OPERATOR',
      "Operators can't be static.",
      "Try removing the keyword 'static'.");

  static const ParserErrorCode STATIC_SETTER_WITHOUT_BODY =
      const ParserErrorCode(
          'STATIC_SETTER_WITHOUT_BODY',
          "A 'static' setter must have a body.",
          "Try adding a body to the setter, or removing the keyword 'static'.");

  static const ParserErrorCode STATIC_TOP_LEVEL_DECLARATION =
      const ParserErrorCode(
          'STATIC_TOP_LEVEL_DECLARATION',
          "Top-level declarations can't be declared to be static.",
          "Try removing the keyword 'static'.");

  static const ParserErrorCode SWITCH_HAS_CASE_AFTER_DEFAULT_CASE =
      const ParserErrorCode(
          'SWITCH_HAS_CASE_AFTER_DEFAULT_CASE',
          "The default case should be the last case in a switch statement.",
          "Try moving the default case after the other case clauses.");

  static const ParserErrorCode SWITCH_HAS_MULTIPLE_DEFAULT_CASES =
      const ParserErrorCode(
          'SWITCH_HAS_MULTIPLE_DEFAULT_CASES',
          "The 'default' case can only be declared once.",
          "Try removing all but one default case.");

  static const ParserErrorCode TOP_LEVEL_OPERATOR = const ParserErrorCode(
      'TOP_LEVEL_OPERATOR',
      "Operators must be declared within a class.",
      "Try removing the operator, "
      "moving it to a class, or "
      "converting it to be a function.");

  static const ParserErrorCode TYPEDEF_IN_CLASS = const ParserErrorCode(
      'TYPEDEF_IN_CLASS',
      "Typedefs can't be declared inside classes.",
      "Try moving the typedef to the top-level.");

  /**
   * Parameters:
   * 0: the starting character that was missing
   */
  static const ParserErrorCode UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP =
      const ParserErrorCode(
          'UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP',
          "There is no '{0}' to open a parameter group.",
          "Try inserting the '{0}' at the appropriate location.");

  /**
   * Parameters:
   * 0: the unexpected text that was found
   */
  static const ParserErrorCode UNEXPECTED_TOKEN = const ParserErrorCode(
      'UNEXPECTED_TOKEN', "Unexpected text '{0}'.", "Try removing the text.");

  static const ParserErrorCode WITH_BEFORE_EXTENDS = const ParserErrorCode(
      'WITH_BEFORE_EXTENDS',
      "The extends clause must be before the with clause.",
      "Try moving the extends clause before the with clause.");

  static const ParserErrorCode WITH_WITHOUT_EXTENDS = const ParserErrorCode(
      'WITH_WITHOUT_EXTENDS',
      "The with clause can't be used without an extends clause.",
      "Try adding an extends clause such as 'extends Object'.");

  static const ParserErrorCode WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER =
      const ParserErrorCode(
          'WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER',
          "The default value of a positional parameter should be preceeded by '='.",
          "Try replacing the ':' with '='.");

  /**
   * Parameters:
   * 0: the terminator that was expected
   * 1: the terminator that was found
   */
  static const ParserErrorCode WRONG_TERMINATOR_FOR_PARAMETER_GROUP =
      const ParserErrorCode(
          'WRONG_TERMINATOR_FOR_PARAMETER_GROUP',
          "Expected '{0}' to close parameter group.",
          "Try replacing '{0}' with '{1}'.");

  static const ParserErrorCode VAR_AND_TYPE = const ParserErrorCode(
      'VAR_AND_TYPE',
      "Variables can't be declared using both 'var' and a type name.",
      "Try removing the keyword 'var'.");

  static const ParserErrorCode VAR_AS_TYPE_NAME = const ParserErrorCode(
      'VAR_AS_TYPE_NAME',
      "The keyword 'var' can't be used as a type name.",
      "Try using 'dynamic' instead of 'var'.");

  static const ParserErrorCode VAR_CLASS = const ParserErrorCode(
      'VAR_CLASS',
      "Classes can't be declared to be 'var'.",
      "Try removing the keyword 'var'.");

  static const ParserErrorCode VAR_ENUM = const ParserErrorCode(
      'VAR_ENUM',
      "Enums can't be declared to be 'var'.",
      "Try removing the keyword 'var'.");

  static const ParserErrorCode VAR_RETURN_TYPE = const ParserErrorCode(
      'VAR_RETURN_TYPE',
      "The return type can't be 'var'.",
      "Try removing the keyword 'var', or "
      "replacing it with the name of the return type.");

  static const ParserErrorCode VAR_TYPEDEF = const ParserErrorCode(
      'VAR_TYPEDEF',
      "Typedefs can't be declared to be 'var'.",
      "Try removing the keyword 'var', or "
      "replacing it with the name of the return type.");

  static const ParserErrorCode VOID_PARAMETER = const ParserErrorCode(
      'VOID_PARAMETER',
      "Parameters can't have a type of 'void'.",
      "Try removing the keyword 'var', or "
      "replacing it with the name of the type of the parameter.");

  static const ParserErrorCode VOID_VARIABLE = const ParserErrorCode(
      'VOID_VARIABLE',
      "Variables can't have a type of 'void'.",
      "Try removing the keyword 'void', or "
      "replacing it with the name of the type of the variable.");

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
