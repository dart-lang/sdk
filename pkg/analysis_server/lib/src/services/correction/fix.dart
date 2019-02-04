// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/**
 * Return true if this [errorCode] is likely to have a fix associated with it.
 */
bool hasFix(ErrorCode errorCode) =>
    errorCode == StaticWarningCode.UNDEFINED_CLASS_BOOLEAN ||
    errorCode == StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER ||
    errorCode == StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS ||
    errorCode == StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED ||
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
    errorCode == StaticWarningCode.UNDEFINED_CLASS ||
    errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED ||
    errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 ||
    errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 ||
    errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS ||
    errorCode == StaticWarningCode.FUNCTION_WITHOUT_CALL ||
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
        (errorCode.name == LintNames.annotate_overrides ||
            errorCode.name == LintNames.avoid_init_to_null ||
            errorCode.name == LintNames.prefer_collection_literals ||
            errorCode.name == LintNames.prefer_conditional_assignment ||
            errorCode.name == LintNames.prefer_const_declarations ||
            errorCode.name == LintNames.unnecessary_brace_in_string_interp ||
            errorCode.name == LintNames.unnecessary_lambdas ||
            errorCode.name == LintNames.unnecessary_this));

/**
 * The implementation of [DartFixContext].
 */
class DartFixContextImpl implements DartFixContext {
  @override
  final ChangeWorkspace workspace;

  @override
  final ResolvedUnitResult resolveResult;

  @override
  final AnalysisError error;

  DartFixContextImpl(this.workspace, this.resolveResult, this.error);
}

/**
 * An enumeration of possible quick fix kinds.
 */
class DartFixKind {
  static const ADD_ASYNC =
      const FixKind('ADD_ASYNC', 50, "Add 'async' modifier");
  static const ADD_EXPLICIT_CAST = const FixKind(
      'ADD_EXPLICIT_CAST', 50, "Add cast",
      appliedTogetherMessage: "Add all casts in file");
  static const ADD_FIELD_FORMAL_PARAMETERS = const FixKind(
      'ADD_FIELD_FORMAL_PARAMETERS', 70, "Add final field formal parameters");
  static const ADD_MISSING_PARAMETER_NAMED = const FixKind(
      'ADD_MISSING_PARAMETER_NAMED', 70, "Add named parameter '{0}'");
  static const ADD_MISSING_PARAMETER_POSITIONAL = const FixKind(
      'ADD_MISSING_PARAMETER_POSITIONAL',
      69,
      "Add optional positional parameter");
  static const ADD_MISSING_PARAMETER_REQUIRED = const FixKind(
      'ADD_MISSING_PARAMETER_REQUIRED', 70, "Add required parameter");
  static const ADD_MISSING_REQUIRED_ARGUMENT = const FixKind(
      'ADD_MISSING_REQUIRED_ARGUMENT', 70, "Add required argument '{0}'");
  static const ADD_NE_NULL = const FixKind('ADD_NE_NULL', 50, "Add != null",
      appliedTogetherMessage: "Add != null everywhere in file");
  static const ADD_OVERRIDE =
      const FixKind('ADD_OVERRIDE', 50, "Add '@override' annotation");
  static const ADD_REQUIRED =
      const FixKind('ADD_REQUIRED', 50, "Add '@required' annotation");
  static const ADD_STATIC =
      const FixKind('ADD_STATIC', 50, "Add 'static' modifier");
  static const ADD_SUPER_CONSTRUCTOR_INVOCATION = const FixKind(
      'ADD_SUPER_CONSTRUCTOR_INVOCATION',
      50,
      "Add super constructor {0} invocation");
  static const CHANGE_TO = const FixKind('CHANGE_TO', 51, "Change to '{0}'");
  static const CHANGE_TO_NEAREST_PRECISE_VALUE = const FixKind(
      'CHANGE_TO_NEAREST_PRECISE_VALUE',
      50,
      "Change to nearest precise int-as-double value: {0}");
  static const CHANGE_TO_STATIC_ACCESS = const FixKind(
      'CHANGE_TO_STATIC_ACCESS', 50, "Change access to static using '{0}'");
  static const CHANGE_TYPE_ANNOTATION = const FixKind(
      'CHANGE_TYPE_ANNOTATION', 50, "Change '{0}' to '{1}' type annotation");
  static const CONVERT_FLUTTER_CHILD =
      const FixKind('CONVERT_FLUTTER_CHILD', 50, "Convert to children:");
  static const CONVERT_FLUTTER_CHILDREN =
      const FixKind('CONVERT_FLUTTER_CHILDREN', 50, "Convert to child:");
  static const CONVERT_TO_NAMED_ARGUMENTS = const FixKind(
      'CONVERT_TO_NAMED_ARGUMENTS', 50, "Convert to named arguments");
  static const CREATE_CLASS =
      const FixKind('CREATE_CLASS', 50, "Create class '{0}'");
  static const CREATE_CONSTRUCTOR =
      const FixKind('CREATE_CONSTRUCTOR', 50, "Create constructor '{0}'");
  static const CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS = const FixKind(
      'CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS',
      50,
      "Create constructor for final fields");
  static const CREATE_CONSTRUCTOR_SUPER = const FixKind(
      'CREATE_CONSTRUCTOR_SUPER', 50, "Create constructor to call {0}");
  static const CREATE_FIELD =
      const FixKind('CREATE_FIELD', 49, "Create field '{0}'");
  static const CREATE_FILE =
      const FixKind('CREATE_FILE', 50, "Create file '{0}'");
  static const CREATE_FUNCTION =
      const FixKind('CREATE_FUNCTION', 49, "Create function '{0}'");
  static const CREATE_GETTER =
      const FixKind('CREATE_GETTER', 50, "Create getter '{0}'");
  static const CREATE_LOCAL_VARIABLE =
      const FixKind('CREATE_LOCAL_VARIABLE', 50, "Create local variable '{0}'");
  static const CREATE_METHOD =
      const FixKind('CREATE_METHOD', 50, "Create method '{0}'");
  static const CREATE_MISSING_OVERRIDES = const FixKind(
      'CREATE_MISSING_OVERRIDES', 51, "Create {0} missing override(s)");
  static const CREATE_MIXIN =
      const FixKind('CREATE_MIXIN', 50, "Create mixin '{0}'");
  static const CREATE_NO_SUCH_METHOD = const FixKind(
      'CREATE_NO_SUCH_METHOD', 49, "Create 'noSuchMethod' method");
  static const EXTEND_CLASS_FOR_MIXIN =
      const FixKind('EXTEND_CLASS_FOR_MIXIN', 50, "Extend the class '{0}'");
  static const IMPORT_ASYNC =
      const FixKind('IMPORT_ASYNC', 49, "Import 'dart:async'");
  static const IMPORT_LIBRARY_PREFIX = const FixKind('IMPORT_LIBRARY_PREFIX',
      49, "Use imported library '{0}' with prefix '{1}'");
  static const IMPORT_LIBRARY_PROJECT1 =
      const FixKind('IMPORT_LIBRARY_PROJECT1', 53, "Import library '{0}'");
  static const IMPORT_LIBRARY_PROJECT2 =
      const FixKind('IMPORT_LIBRARY_PROJECT2', 52, "Import library '{0}'");
  static const IMPORT_LIBRARY_PROJECT3 =
      const FixKind('IMPORT_LIBRARY_PROJECT3', 51, "Import library '{0}'");
  static const IMPORT_LIBRARY_SDK =
      const FixKind('IMPORT_LIBRARY_SDK', 54, "Import library '{0}'");
  static const IMPORT_LIBRARY_SHOW =
      const FixKind('IMPORT_LIBRARY_SHOW', 55, "Update library '{0}' import");
  static const INSERT_SEMICOLON =
      const FixKind('INSERT_SEMICOLON', 50, "Insert ';'");
  static const MAKE_CLASS_ABSTRACT =
      const FixKind('MAKE_CLASS_ABSTRACT', 50, "Make class '{0}' abstract");
  static const MAKE_FIELD_NOT_FINAL =
      const FixKind('MAKE_FIELD_NOT_FINAL', 50, "Make field '{0}' not final");
  static const MAKE_FINAL = const FixKind('MAKE_FINAL', 50, "Make final");
  static const MOVE_TYPE_ARGUMENTS_TO_CLASS = const FixKind(
      'MOVE_TYPE_ARGUMENTS_TO_CLASS',
      50,
      "Move type arguments to after class name");
  static const REMOVE_ANNOTATION =
      const FixKind('REMOVE_ANNOTATION', 50, "Remove the '{0}' annotation");
  static const REMOVE_AWAIT = const FixKind('REMOVE_AWAIT', 50, "Remove await");
  static const REMOVE_DEAD_CODE =
      const FixKind('REMOVE_DEAD_CODE', 50, "Remove dead code");
  static const REMOVE_EMPTY_CATCH =
      const FixKind('REMOVE_EMPTY_CATCH', 50, "Remove empty catch clause");
  static const REMOVE_EMPTY_CONSTRUCTOR_BODY = const FixKind(
      'REMOVE_EMPTY_CONSTRUCTOR_BODY', 50, "Remove empty constructor body");
  static const REMOVE_EMPTY_ELSE =
      const FixKind('REMOVE_EMPTY_ELSE', 50, "Remove empty else clause");
  static const REMOVE_EMPTY_STATEMENT =
      const FixKind('REMOVE_EMPTY_STATEMENT', 50, "Remove empty statement");
  static const REMOVE_INITIALIZER =
      const FixKind('REMOVE_INITIALIZER', 50, "Remove initializer");
  static const REMOVE_INTERPOLATION_BRACES = const FixKind(
      'REMOVE_INTERPOLATION_BRACES',
      50,
      "Remove unnecessary interpolation braces");
  static const REMOVE_METHOD_DECLARATION = const FixKind(
      'REMOVE_METHOD_DECLARATION', 50, "Remove method declaration");
  static const REMOVE_NAME_FROM_COMBINATOR = const FixKind(
      'REMOVE_NAME_FROM_COMBINATOR', 50, "Remove name from '{0}'");
  static const REMOVE_PARAMETERS_IN_GETTER_DECLARATION = const FixKind(
      'REMOVE_PARAMETERS_IN_GETTER_DECLARATION',
      50,
      "Remove parameters in getter declaration");
  static const REMOVE_PARENTHESIS_IN_GETTER_INVOCATION = const FixKind(
      'REMOVE_PARENTHESIS_IN_GETTER_INVOCATION',
      50,
      "Remove parentheses in getter invocation");
  static const REMOVE_THIS_EXPRESSION =
      const FixKind('REMOVE_THIS_EXPRESSION', 50, "Remove this expression");
  static const REMOVE_TYPE_ANNOTATION =
      const FixKind('REMOVE_TYPE_ANNOTATION', 50, "Remove type annotation");
  static const REMOVE_TYPE_ARGUMENTS =
      const FixKind('REMOVE_TYPE_ARGUMENTS', 49, "Remove type arguments");
  static const REMOVE_UNNECESSARY_CAST = const FixKind(
      'REMOVE_UNNECESSARY_CAST', 50, "Remove unnecessary cast",
      appliedTogetherMessage: "Remove all unnecessary casts in file");
  static const REMOVE_UNUSED_CATCH_CLAUSE = const FixKind(
      'REMOVE_UNUSED_CATCH_CLAUSE', 50, "Remove unused 'catch' clause");
  static const REMOVE_UNUSED_CATCH_STACK = const FixKind(
      'REMOVE_UNUSED_CATCH_STACK', 50, "Remove unused stack trace variable");
  static const REMOVE_UNUSED_IMPORT = const FixKind(
      'REMOVE_UNUSED_IMPORT', 50, "Remove unused import",
      appliedTogetherMessage: "Remove all unused imports in this file");
  static const RENAME_TO_CAMEL_CASE =
      const FixKind('RENAME_TO_CAMEL_CASE', 50, "Rename to '{0}'");
  static const REPLACE_BOOLEAN_WITH_BOOL = const FixKind(
      'REPLACE_BOOLEAN_WITH_BOOL', 50, "Replace 'boolean' with 'bool'",
      appliedTogetherMessage: "Replace all 'boolean' with 'bool' in file");
  static const REPLACE_FINAL_WITH_CONST = const FixKind(
      'REPLACE_FINAL_WITH_CONST', 50, "Replace 'final' with 'const'");
  static const REPLACE_RETURN_TYPE_FUTURE = const FixKind(
      'REPLACE_RETURN_TYPE_FUTURE',
      50,
      "Return 'Future' from 'async' function");
  static const REPLACE_VAR_WITH_DYNAMIC = const FixKind(
      'REPLACE_VAR_WITH_DYNAMIC', 50, "Replace 'var' with 'dynamic'");
  static const REPLACE_WITH_BRACKETS =
      const FixKind('REPLACE_WITH_BRACKETS', 50, "Replace with { }");
  static const REPLACE_WITH_CONDITIONAL_ASSIGNMENT = const FixKind(
      'REPLACE_WITH_CONDITIONAL_ASSIGNMENT', 50, "Replace with ??=");
  static const REPLACE_WITH_IDENTIFIER =
      const FixKind('REPLACE_WITH_IDENTIFIER', 50, "Replace with identifier");
  static const REPLACE_WITH_LITERAL =
      const FixKind('REPLACE_WITH_LITERAL', 50, "Replace with literal");
  static const REPLACE_WITH_NULL_AWARE = const FixKind(
      'REPLACE_WITH_NULL_AWARE',
      50,
      "Replace the '.' with a '?.' in the invocation");
  static const REPLACE_WITH_TEAR_OFF = const FixKind(
      'REPLACE_WITH_TEAR_OFF', 50, "Replace function literal with tear-off");
  static const UPDATE_SDK_CONSTRAINTS =
      const FixKind('UPDATE_SDK_CONSTRAINTS', 50, "Update the SDK constraints");
  static const USE_CONST = const FixKind('USE_CONST', 50, "Change to constant");
  static const USE_EFFECTIVE_INTEGER_DIVISION = const FixKind(
      'USE_EFFECTIVE_INTEGER_DIVISION',
      50,
      "Use effective integer division ~/");
  static const USE_EQ_EQ_NULL = const FixKind(
      'USE_EQ_EQ_NULL', 50, "Use == null instead of 'is Null'",
      appliedTogetherMessage:
          "Use == null instead of 'is Null' everywhere in file");
  static const USE_IS_NOT_EMPTY = const FixKind(
      'USE_IS_NOT_EMPTY', 50, "Use x.isNotEmpty instead of '!x.isEmpty'");
  static const USE_NOT_EQ_NULL = const FixKind(
      'USE_NOT_EQ_NULL', 50, "Use != null instead of 'is! Null'",
      appliedTogetherMessage:
          "Use != null instead of 'is! Null' everywhere in file");
}
