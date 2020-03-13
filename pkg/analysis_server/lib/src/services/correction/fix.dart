// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Return true if this [errorCode] is likely to have a fix associated with it.
bool hasFix(ErrorCode errorCode) =>
    errorCode == StaticWarningCode.UNDEFINED_CLASS_BOOLEAN ||
    errorCode == StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER ||
    errorCode == StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR ||
    errorCode ==
        StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE ||
    errorCode ==
        StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO ||
    errorCode ==
        StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE ||
    errorCode ==
        StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR ||
    errorCode ==
        StaticWarningCode
            .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS ||
    errorCode == StaticWarningCode.CAST_TO_NON_TYPE ||
    errorCode == StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME ||
    errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED ||
    errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 ||
    errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 ||
    errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS ||
    errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER ||
    errorCode ==
        CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE ||
    errorCode == CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE ||
    errorCode == CompileTimeErrorCode.INVALID_ANNOTATION ||
    errorCode == CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT ||
    errorCode == CompileTimeErrorCode.PART_OF_NON_PART ||
    errorCode == CompileTimeErrorCode.UNDEFINED_ANNOTATION ||
    errorCode ==
        CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT ||
    errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST ||
    errorCode == CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED ||
    errorCode == HintCode.CAN_BE_NULL_AFTER_NULL_AWARE ||
    errorCode == HintCode.DEAD_CODE ||
    errorCode == HintCode.DIVISION_OPTIMIZATION ||
    errorCode == HintCode.TYPE_CHECK_IS_NOT_NULL ||
    errorCode == HintCode.TYPE_CHECK_IS_NULL ||
    errorCode == HintCode.UNNECESSARY_CAST ||
    errorCode == HintCode.UNUSED_CATCH_CLAUSE ||
    errorCode == HintCode.UNUSED_CATCH_STACK ||
    errorCode == HintCode.UNUSED_IMPORT ||
    errorCode == ParserErrorCode.EXPECTED_TOKEN ||
    errorCode == ParserErrorCode.GETTER_WITH_PARAMETERS ||
    errorCode == ParserErrorCode.VAR_AS_TYPE_NAME ||
    errorCode == StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE ||
    errorCode == StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER ||
    errorCode == StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION ||
    errorCode == StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT ||
    errorCode == StaticTypeWarningCode.UNDEFINED_FUNCTION ||
    errorCode == StaticTypeWarningCode.UNDEFINED_GETTER ||
    errorCode == StaticTypeWarningCode.UNDEFINED_METHOD ||
    errorCode == StaticTypeWarningCode.UNDEFINED_SETTER ||
    errorCode == CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER ||
    (errorCode is LintCode &&
        (errorCode.name == LintNames.always_require_non_null_named_parameters ||
            errorCode.name == LintNames.annotate_overrides ||
            errorCode.name == LintNames.avoid_annotating_with_dynamic ||
            errorCode.name == LintNames.avoid_empty_else ||
            errorCode.name == LintNames.avoid_init_to_null ||
            errorCode.name == LintNames.avoid_redundant_argument_values ||
            errorCode.name == LintNames.avoid_return_types_on_setters ||
            errorCode.name == LintNames.avoid_types_on_closure_parameters ||
            errorCode.name == LintNames.await_only_futures ||
            errorCode.name == LintNames.empty_catches ||
            errorCode.name == LintNames.empty_constructor_bodies ||
            errorCode.name == LintNames.empty_statements ||
            errorCode.name == LintNames.no_duplicate_case_values ||
            errorCode.name == LintNames.non_constant_identifier_names ||
            errorCode.name == LintNames.null_closures ||
            errorCode.name == LintNames.prefer_collection_literals ||
            errorCode.name == LintNames.prefer_conditional_assignment ||
            errorCode.name == LintNames.prefer_const_declarations ||
            errorCode.name == LintNames.prefer_equal_for_default_values ||
            errorCode.name == LintNames.prefer_final_fields ||
            errorCode.name == LintNames.prefer_final_locals ||
            errorCode.name == LintNames.prefer_is_not_empty ||
            errorCode.name == LintNames.type_init_formals ||
            errorCode.name == LintNames.unawaited_futures ||
            errorCode.name == LintNames.unnecessary_brace_in_string_interps ||
            errorCode.name == LintNames.unnecessary_const ||
            errorCode.name == LintNames.unnecessary_lambdas ||
            errorCode.name == LintNames.unnecessary_new ||
            errorCode.name == LintNames.unnecessary_overrides ||
            errorCode.name == LintNames.unnecessary_this ||
            errorCode.name == LintNames.use_rethrow_when_possible));

/// An enumeration of quick fix kinds for the errors found in an analysis
/// options file.
class AnalysisOptionsFixKind {
  static const REMOVE_SETTING = FixKind('REMOVE_SETTING', 50, "Remove '{0}'");
}

/// The implementation of [DartFixContext].
class DartFixContextImpl implements DartFixContext {
  @override
  final ChangeWorkspace workspace;

  @override
  final ResolvedUnitResult resolveResult;

  @override
  final AnalysisError error;

  final List<TopLevelDeclaration> Function(String name)
      getTopLevelDeclarationsFunction;

  DartFixContextImpl(this.workspace, this.resolveResult, this.error,
      this.getTopLevelDeclarationsFunction);

  @override
  List<TopLevelDeclaration> getTopLevelDeclarations(String name) {
    return getTopLevelDeclarationsFunction(name);
  }
}

/// An enumeration of quick fix kinds found in a Dart file.
class DartFixKind {
  static const ADD_ASYNC = FixKind('ADD_ASYNC', 50, "Add 'async' modifier");
  static const ADD_AWAIT = FixKind('ADD_AWAIT', 50, "Add 'await' keyword");
  static const ADD_EXPLICIT_CAST = FixKind('ADD_EXPLICIT_CAST', 50, 'Add cast',
      appliedTogetherMessage: 'Add all casts in file');
  static const ADD_CONST = FixKind('ADD_CONST', 50, "Add 'const' modifier");
  static const ADD_CURLY_BRACES =
      FixKind('ADD_CURLY_BRACES', 50, 'Add curly braces');
  static const ADD_DIAGNOSTIC_PROPERTY_REFERENCE = FixKind(
      'ADD_DIAGNOSTIC_PROPERTY_REFERENCE',
      50,
      'Add a debug reference to this property');
  static const ADD_FIELD_FORMAL_PARAMETERS = FixKind(
      'ADD_FIELD_FORMAL_PARAMETERS', 70, 'Add final field formal parameters');
  static const ADD_MISSING_ENUM_CASE_CLAUSES =
      FixKind('ADD_MISSING_ENUM_CASE_CLAUSES', 50, 'Add missing case clauses');
  static const ADD_MISSING_PARAMETER_NAMED =
      FixKind('ADD_MISSING_PARAMETER_NAMED', 70, "Add named parameter '{0}'");
  static const ADD_MISSING_PARAMETER_POSITIONAL = FixKind(
      'ADD_MISSING_PARAMETER_POSITIONAL',
      69,
      'Add optional positional parameter');
  static const ADD_MISSING_PARAMETER_REQUIRED =
      FixKind('ADD_MISSING_PARAMETER_REQUIRED', 70, 'Add required parameter');
  static const ADD_MISSING_REQUIRED_ARGUMENT = FixKind(
      'ADD_MISSING_REQUIRED_ARGUMENT', 70, "Add required argument '{0}'");
  static const ADD_NE_NULL = FixKind('ADD_NE_NULL', 50, 'Add != null',
      appliedTogetherMessage: 'Add != null everywhere in file');
  static const ADD_OVERRIDE =
      FixKind('ADD_OVERRIDE', 50, "Add '@override' annotation");
  static const ADD_REQUIRED =
      FixKind('ADD_REQUIRED', 50, "Add '@required' annotation");
  static const ADD_RETURN_TYPE =
      FixKind('ADD_RETURN_TYPE', 50, 'Add return type');
  static const ADD_STATIC = FixKind('ADD_STATIC', 50, "Add 'static' modifier");
  static const ADD_SUPER_CONSTRUCTOR_INVOCATION = FixKind(
      'ADD_SUPER_CONSTRUCTOR_INVOCATION',
      50,
      'Add super constructor {0} invocation');
  static const ADD_TYPE_ANNOTATION =
      FixKind('ADD_TYPE_ANNOTATION', 50, 'Add type annotation');
  static const CHANGE_ARGUMENT_NAME =
      FixKind('CHANGE_ARGUMENT_NAME', 60, "Change to '{0}'");
  static const CHANGE_TO = FixKind('CHANGE_TO', 51, "Change to '{0}'");
  static const CHANGE_TO_NEAREST_PRECISE_VALUE = FixKind(
      'CHANGE_TO_NEAREST_PRECISE_VALUE',
      50,
      'Change to nearest precise int-as-double value: {0}');
  static const CHANGE_TO_STATIC_ACCESS = FixKind(
      'CHANGE_TO_STATIC_ACCESS', 50, "Change access to static using '{0}'");
  static const CHANGE_TYPE_ANNOTATION = FixKind(
      'CHANGE_TYPE_ANNOTATION', 50, "Change '{0}' to '{1}' type annotation");
  static const CONVERT_FLUTTER_CHILD =
      FixKind('CONVERT_FLUTTER_CHILD', 50, 'Convert to children:');
  static const CONVERT_FLUTTER_CHILDREN =
      FixKind('CONVERT_FLUTTER_CHILDREN', 50, 'Convert to child:');
  static const CONVERT_INTO_EXPRESSION_BODY =
      FixKind('CONVERT_INTO_EXPRESSION_BODY', 50, 'Convert to expression body');
  static const CONVERT_TO_CONTAINS =
      FixKind('CONVERT_TO_CONTAINS', 50, "Convert to using 'contains'");
  static const CONVERT_TO_FOR_ELEMENT =
      FixKind('CONVERT_TO_FOR_ELEMENT', 50, "Convert to a 'for' element");
  static const CONVERT_TO_GENERIC_FUNCTION_SYNTAX = FixKind(
      'CONVERT_TO_GENERIC_FUNCTION_SYNTAX',
      50,
      "Convert into 'Function' syntax");
  static const CONVERT_TO_IF_ELEMENT =
      FixKind('CONVERT_TO_IF_ELEMENT', 50, "Convert to an 'if' element");
  static const CONVERT_TO_IF_NULL =
      FixKind('CONVERT_TO_IF_NULL', 50, "Convert to use '??'");
  static const CONVERT_TO_INT_LITERAL =
      FixKind('CONVERT_TO_INT_LITERAL', 50, 'Convert to an int literal');
  static const CONVERT_TO_LINE_COMMENT = FixKind(
      'CONVERT_TO_LINE_COMMENT', 50, 'Convert to line documentation comment');
  static const CONVERT_TO_LIST_LITERAL =
      FixKind('CONVERT_TO_LIST_LITERAL', 50, 'Convert to list literal');
  static const CONVERT_TO_MAP_LITERAL =
      FixKind('CONVERT_TO_MAP_LITERAL', 50, 'Convert to map literal');
  static const CONVERT_TO_NAMED_ARGUMENTS =
      FixKind('CONVERT_TO_NAMED_ARGUMENTS', 50, 'Convert to named arguments');
  static const CONVERT_TO_NULL_AWARE =
      FixKind('CONVERT_TO_NULL_AWARE', 50, "Convert to use '?.'");
  static const CONVERT_TO_PACKAGE_IMPORT =
      FixKind('CONVERT_TO_PACKAGE_IMPORT', 50, "Convert to 'package:' import");
  static const CONVERT_TO_RELATIVE_IMPORT =
      FixKind('CONVERT_TO_RELATIVE_IMPORT', 50, 'Convert to relative import');
  static const CONVERT_TO_SET_LITERAL =
      FixKind('CONVERT_TO_SET_LITERAL', 50, 'Convert to set literal');
  static const CONVERT_TO_SINGLE_QUOTED_STRING = FixKind(
      'CONVERT_TO_SINGLE_QUOTED_STRING', 50, 'Convert to single quoted string');
  static const CONVERT_TO_SPREAD =
      FixKind('CONVERT_TO_SPREAD', 50, 'Convert to a spread');
  static const CONVERT_TO_WHERE_TYPE =
      FixKind('CONVERT_TO_WHERE_TYPE', 50, "Convert to a use 'whereType'");
  static const CREATE_CLASS = FixKind('CREATE_CLASS', 50, "Create class '{0}'");
  static const CREATE_CONSTRUCTOR =
      FixKind('CREATE_CONSTRUCTOR', 50, "Create constructor '{0}'");
  static const CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS = FixKind(
      'CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS',
      50,
      'Create constructor for final fields');
  static const CREATE_CONSTRUCTOR_SUPER =
      FixKind('CREATE_CONSTRUCTOR_SUPER', 50, 'Create constructor to call {0}');
  static const CREATE_FIELD = FixKind('CREATE_FIELD', 49, "Create field '{0}'");
  static const CREATE_FILE = FixKind('CREATE_FILE', 50, "Create file '{0}'");
  static const CREATE_FUNCTION =
      FixKind('CREATE_FUNCTION', 49, "Create function '{0}'");
  static const CREATE_GETTER =
      FixKind('CREATE_GETTER', 50, "Create getter '{0}'");
  static const CREATE_LOCAL_VARIABLE =
      FixKind('CREATE_LOCAL_VARIABLE', 50, "Create local variable '{0}'");
  static const CREATE_METHOD =
      FixKind('CREATE_METHOD', 50, "Create method '{0}'");
  static const CREATE_MISSING_OVERRIDES =
      FixKind('CREATE_MISSING_OVERRIDES', 51, 'Create {0} missing override(s)');
  static const CREATE_MIXIN = FixKind('CREATE_MIXIN', 50, "Create mixin '{0}'");
  static const CREATE_NO_SUCH_METHOD =
      FixKind('CREATE_NO_SUCH_METHOD', 49, "Create 'noSuchMethod' method");
  static const CREATE_SETTER =
      FixKind('CREATE_SETTER', 50, "Create setter '{0}'");
  static const EXTEND_CLASS_FOR_MIXIN =
      FixKind('EXTEND_CLASS_FOR_MIXIN', 50, "Extend the class '{0}'");
  static const IMPORT_ASYNC =
      FixKind('IMPORT_ASYNC', 49, "Import 'dart:async'");
  static const IMPORT_LIBRARY_PREFIX = FixKind('IMPORT_LIBRARY_PREFIX', 49,
      "Use imported library '{0}' with prefix '{1}'");
  static const IMPORT_LIBRARY_PROJECT1 =
      FixKind('IMPORT_LIBRARY_PROJECT1', 53, "Import library '{0}'");
  static const IMPORT_LIBRARY_PROJECT2 =
      FixKind('IMPORT_LIBRARY_PROJECT2', 52, "Import library '{0}'");
  static const IMPORT_LIBRARY_PROJECT3 =
      FixKind('IMPORT_LIBRARY_PROJECT3', 51, "Import library '{0}'");
  static const IMPORT_LIBRARY_SDK =
      FixKind('IMPORT_LIBRARY_SDK', 54, "Import library '{0}'");
  static const IMPORT_LIBRARY_SHOW =
      FixKind('IMPORT_LIBRARY_SHOW', 55, "Update library '{0}' import");
  static const INLINE_INVOCATION =
      FixKind('INLINE_INVOCATION', 30, "Inline invocation of '{0}'");
  static const INLINE_TYPEDEF =
      FixKind('INLINE_TYPEDEF', 30, "Inline the definition of '{0}'");
  static const INSERT_SEMICOLON = FixKind('INSERT_SEMICOLON', 50, "Insert ';'");
  static const MAKE_CLASS_ABSTRACT =
      FixKind('MAKE_CLASS_ABSTRACT', 50, "Make class '{0}' abstract");
  static const MAKE_FIELD_NOT_FINAL =
      FixKind('MAKE_FIELD_NOT_FINAL', 50, "Make field '{0}' not final");
  static const MAKE_FINAL = FixKind('MAKE_FINAL', 50, 'Make final');
  static const MOVE_TYPE_ARGUMENTS_TO_CLASS = FixKind(
      'MOVE_TYPE_ARGUMENTS_TO_CLASS',
      50,
      'Move type arguments to after class name');
  static const MAKE_VARIABLE_NOT_FINAL =
      FixKind('MAKE_VARIABLE_NOT_FINAL', 50, "Make variable '{0}' not final");
  static const QUALIFY_REFERENCE =
      FixKind('QUALIFY_REFERENCE', 50, "Use '{0}'");
  static const REMOVE_ANNOTATION =
      FixKind('REMOVE_ANNOTATION', 50, "Remove the '{0}' annotation");
  static const REMOVE_ARGUMENT =
      FixKind('REMOVE_ARGUMENT', 50, 'Remove argument');
  static const REMOVE_AWAIT = FixKind('REMOVE_AWAIT', 50, 'Remove await');
  static const REMOVE_CONST = FixKind('REMOVE_CONST', 50, 'Remove const');
  static const REMOVE_DEAD_CODE =
      FixKind('REMOVE_DEAD_CODE', 50, 'Remove dead code');
  static const REMOVE_DUPLICATE_CASE =
      FixKind('REMOVE_DUPLICATE_CASE', 50, 'Remove duplicate case statement');
  static const REMOVE_EMPTY_CATCH =
      FixKind('REMOVE_EMPTY_CATCH', 50, 'Remove empty catch clause');
  static const REMOVE_EMPTY_CONSTRUCTOR_BODY = FixKind(
      'REMOVE_EMPTY_CONSTRUCTOR_BODY', 50, 'Remove empty constructor body');
  static const REMOVE_EMPTY_ELSE =
      FixKind('REMOVE_EMPTY_ELSE', 50, 'Remove empty else clause');
  static const REMOVE_EMPTY_STATEMENT =
      FixKind('REMOVE_EMPTY_STATEMENT', 50, 'Remove empty statement');
  static const REMOVE_IF_NULL_OPERATOR =
      FixKind('REMOVE_IF_NULL_OPERATOR', 50, "Remove the '??' operator");
  static const REMOVE_INITIALIZER =
      FixKind('REMOVE_INITIALIZER', 50, 'Remove initializer');
  static const REMOVE_INTERPOLATION_BRACES = FixKind(
      'REMOVE_INTERPOLATION_BRACES',
      50,
      'Remove unnecessary interpolation braces');
  static const REMOVE_METHOD_DECLARATION =
      FixKind('REMOVE_METHOD_DECLARATION', 50, 'Remove method declaration');
  static const REMOVE_NAME_FROM_COMBINATOR =
      FixKind('REMOVE_NAME_FROM_COMBINATOR', 50, "Remove name from '{0}'");
  static const REMOVE_OPERATOR =
      FixKind('REMOVE_OPERATOR', 50, 'Remove the operator');
  static const REMOVE_PARAMETERS_IN_GETTER_DECLARATION = FixKind(
      'REMOVE_PARAMETERS_IN_GETTER_DECLARATION',
      50,
      'Remove parameters in getter declaration');
  static const REMOVE_PARENTHESIS_IN_GETTER_INVOCATION = FixKind(
      'REMOVE_PARENTHESIS_IN_GETTER_INVOCATION',
      50,
      'Remove parentheses in getter invocation');
  static const REMOVE_THIS_EXPRESSION =
      FixKind('REMOVE_THIS_EXPRESSION', 50, 'Remove this expression');
  static const REMOVE_TYPE_ANNOTATION =
      FixKind('REMOVE_TYPE_ANNOTATION', 50, 'Remove type annotation');
  static const REMOVE_TYPE_ARGUMENTS =
      FixKind('REMOVE_TYPE_ARGUMENTS', 49, 'Remove type arguments');
  static const REMOVE_UNNECESSARY_CAST = FixKind(
      'REMOVE_UNNECESSARY_CAST', 50, 'Remove unnecessary cast',
      appliedTogetherMessage: 'Remove all unnecessary casts in file');
  static const REMOVE_UNNECESSARY_CONST = FixKind(
      'REMOVE_UNNECESSARY_CONST', 50, 'Remove unnecessary const keyword');
  static const REMOVE_UNNECESSARY_NEW =
      FixKind('REMOVE_UNNECESSARY_NEW', 50, 'Remove unnecessary new keyword');
  static const REMOVE_UNUSED_CATCH_CLAUSE =
      FixKind('REMOVE_UNUSED_CATCH_CLAUSE', 50, "Remove unused 'catch' clause");
  static const REMOVE_UNUSED_CATCH_STACK = FixKind(
      'REMOVE_UNUSED_CATCH_STACK', 50, 'Remove unused stack trace variable');
  static const REMOVE_UNUSED_ELEMENT =
      FixKind('REMOVE_UNUSED_ELEMENT', 50, 'Remove unused element');
  static const REMOVE_UNUSED_FIELD =
      FixKind('REMOVE_UNUSED_FIELD', 50, 'Remove unused field');
  static const REMOVE_UNUSED_IMPORT = FixKind(
      'REMOVE_UNUSED_IMPORT', 50, 'Remove unused import',
      appliedTogetherMessage: 'Remove all unused imports in this file');
  static const REMOVE_UNUSED_LABEL =
      FixKind('REMOVE_UNUSED_LABEL', 50, 'Remove unused label');
  static const REMOVE_UNUSED_LOCAL_VARIABLE = FixKind(
      'REMOVE_UNUSED_LOCAL_VARIABLE', 50, 'Remove unused local variable');
  static const RENAME_TO_CAMEL_CASE =
      FixKind('RENAME_TO_CAMEL_CASE', 50, "Rename to '{0}'");
  static const REPLACE_BOOLEAN_WITH_BOOL = FixKind(
      'REPLACE_BOOLEAN_WITH_BOOL', 50, "Replace 'boolean' with 'bool'",
      appliedTogetherMessage: "Replace all 'boolean' with 'bool' in file");
  static const REPLACE_COLON_WITH_EQUALS =
      FixKind('REPLACE_COLON_WITH_EQUALS', 50, "Replace ':' with '='");
  static const REPLACE_FINAL_WITH_CONST =
      FixKind('REPLACE_FINAL_WITH_CONST', 50, "Replace 'final' with 'const'");
  static const REPLACE_NEW_WITH_CONST =
      FixKind('REPLACE_NEW_WITH_CONST', 50, "Replace 'new' with 'const'");
  static const REPLACE_NULL_WITH_CLOSURE =
      FixKind('REPLACE_NULL_WITH_CLOSURE', 50, "Replace 'null' with a closure");
  static const REPLACE_RETURN_TYPE_FUTURE = FixKind(
      'REPLACE_RETURN_TYPE_FUTURE',
      50,
      "Return 'Future' from 'async' function");
  static const REPLACE_VAR_WITH_DYNAMIC =
      FixKind('REPLACE_VAR_WITH_DYNAMIC', 50, "Replace 'var' with 'dynamic'");
  static const REPLACE_WITH_EIGHT_DIGIT_HEX =
      FixKind('REPLACE_WITH_EIGHT_DIGIT_HEX', 50, "Replace with '{0}'");
  static const REPLACE_WITH_BRACKETS =
      FixKind('REPLACE_WITH_BRACKETS', 50, 'Replace with { }');
  static const REPLACE_WITH_CONDITIONAL_ASSIGNMENT =
      FixKind('REPLACE_WITH_CONDITIONAL_ASSIGNMENT', 50, 'Replace with ??=');
  static const REPLACE_WITH_EXTENSION_NAME =
      FixKind('REPLACE_WITH_EXTENSION_NAME', 50, "Replace with '{0}'");
  static const REPLACE_WITH_IDENTIFIER =
      FixKind('REPLACE_WITH_IDENTIFIER', 50, 'Replace with identifier');
  static const REPLACE_WITH_IS_EMPTY =
      FixKind('REPLACE_WITH_IS_EMPTY', 50, "Replace with 'isEmpty'");
  static const REPLACE_WITH_IS_NOT_EMPTY =
      FixKind('REPLACE_WITH_IS_NOT_EMPTY', 50, "Replace with 'isNotEmpty'");
  static const REPLACE_WITH_NULL_AWARE = FixKind('REPLACE_WITH_NULL_AWARE', 50,
      "Replace the '.' with a '?.' in the invocation");
  static const REPLACE_WITH_TEAR_OFF = FixKind(
      'REPLACE_WITH_TEAR_OFF', 50, 'Replace function literal with tear-off');
  static const REPLACE_WITH_VAR =
      FixKind('REPLACE_WITH_VAR', 50, "Replace type annotation with 'var'");
  static const SORT_CHILD_PROPERTY_LAST = FixKind('SORT_CHILD_PROPERTY_LAST',
      50, 'Move child property to end of arguments');
  static const UPDATE_SDK_CONSTRAINTS =
      FixKind('UPDATE_SDK_CONSTRAINTS', 50, 'Update the SDK constraints');
  static const USE_CONST = FixKind('USE_CONST', 50, 'Change to constant');
  static const USE_EFFECTIVE_INTEGER_DIVISION = FixKind(
      'USE_EFFECTIVE_INTEGER_DIVISION',
      50,
      'Use effective integer division ~/');
  static const USE_EQ_EQ_NULL = FixKind(
      'USE_EQ_EQ_NULL', 50, "Use == null instead of 'is Null'",
      appliedTogetherMessage:
          "Use == null instead of 'is Null' everywhere in file");
  static const USE_IS_NOT_EMPTY = FixKind(
      'USE_IS_NOT_EMPTY', 50, "Use x.isNotEmpty instead of '!x.isEmpty'");
  static const USE_NOT_EQ_NULL = FixKind(
      'USE_NOT_EQ_NULL', 50, "Use != null instead of 'is! Null'",
      appliedTogetherMessage:
          "Use != null instead of 'is! Null' everywhere in file");
  static const USE_RETHROW =
      FixKind('USE_RETHROW', 50, 'Replace throw with rethrow');
  static const WRAP_IN_FUTURE =
      FixKind('WRAP_IN_FUTURE', 50, "Wrap in 'Future.value'");
  static const WRAP_IN_TEXT =
      FixKind('WRAP_IN_TEXT', 50, "Wrap in a 'Text' widget");
}

/// An enumeration of quick fix kinds for the errors found in an Android
/// manifest file.
class ManifestFixKind {}

/// An enumeration of quick fix kinds for the errors found in a pubspec file.
class PubspecFixKind {}
