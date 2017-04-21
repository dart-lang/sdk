// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.services.correction.fix;

import 'dart:async';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';

/**
 * Compute and return the fixes available for the given [error]. The error was
 * reported after it's source was analyzed in the given [context]. The [plugin]
 * is used to get the list of fix contributors.
 */
Future<List<Fix>> computeFixes(
    ServerPlugin plugin,
    ResourceProvider resourceProvider,
    AnalysisContext context,
    AnalysisError error) async {
  List<Fix> fixes = <Fix>[];
  List<FixContributor> contributors = plugin.fixContributors;
  FixContext fixContext = new FixContextImpl(resourceProvider, context, error);
  for (FixContributor contributor in contributors) {
    try {
      List<Fix> contributedFixes = await contributor.computeFixes(fixContext);
      if (contributedFixes != null) {
        fixes.addAll(contributedFixes);
      }
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logError(
          'Exception from fix contributor: ${contributor.runtimeType}',
          new CaughtException(exception, stackTrace));
    }
  }
  fixes.sort(Fix.SORT_BY_RELEVANCE);
  return fixes;
}

/**
 * Return true if this [errorCode] is likely to have a fix associated with it.
 */
bool hasFix(ErrorCode errorCode) =>
    errorCode == StaticWarningCode.UNDEFINED_CLASS_BOOLEAN ||
    errorCode == StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER ||
    errorCode == StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS ||
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
    errorCode == CompileTimeErrorCode.INVALID_ANNOTATION ||
    errorCode == CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT ||
    errorCode == CompileTimeErrorCode.PART_OF_NON_PART ||
    errorCode ==
        CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT ||
    errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST ||
    errorCode == CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED ||
    errorCode == HintCode.CAN_BE_NULL_AFTER_NULL_AWARE ||
    errorCode == HintCode.DEAD_CODE ||
    errorCode == HintCode.DIVISION_OPTIMIZATION ||
    errorCode == HintCode.TYPE_CHECK_IS_NOT_NULL ||
    errorCode == HintCode.TYPE_CHECK_IS_NULL ||
    errorCode == HintCode.UNDEFINED_GETTER ||
    errorCode == HintCode.UNDEFINED_SETTER ||
    errorCode == HintCode.UNNECESSARY_CAST ||
    errorCode == HintCode.UNUSED_CATCH_CLAUSE ||
    errorCode == HintCode.UNUSED_CATCH_STACK ||
    errorCode == HintCode.UNUSED_IMPORT ||
    errorCode == HintCode.UNDEFINED_METHOD ||
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
            errorCode.name == LintNames.unnecessary_brace_in_string_interp));

/**
 * An enumeration of possible quick fix kinds.
 */
class DartFixKind {
  static const ADD_ASYNC =
      const FixKind('ADD_ASYNC', 50, "Add 'async' modifier");
  static const ADD_FIELD_FORMAL_PARAMETERS = const FixKind(
      'ADD_FIELD_FORMAL_PARAMETERS', 30, "Add final field formal parameters");
  static const ADD_MISSING_PARAMETER_POSITIONAL = const FixKind(
      'ADD_MISSING_PARAMETER_POSITIONAL',
      31,
      "Add optional positional parameter");
  static const ADD_MISSING_PARAMETER_REQUIRED = const FixKind(
      'ADD_MISSING_PARAMETER_REQUIRED', 30, "Add required parameter");
  static const ADD_MISSING_REQUIRED_ARGUMENT = const FixKind(
      'ADD_MISSING_REQUIRED_ARGUMENT', 30, "Add required argument '{0}'");
  static const ADD_NE_NULL = const FixKind('ADD_NE_NULL', 50, "Add != null");
  static const ADD_PACKAGE_DEPENDENCY = const FixKind(
      'ADD_PACKAGE_DEPENDENCY', 50, "Add dependency on package '{0}'");
  static const ADD_SUPER_CONSTRUCTOR_INVOCATION = const FixKind(
      'ADD_SUPER_CONSTRUCTOR_INVOCATION',
      50,
      "Add super constructor {0} invocation");
  static const CHANGE_TO = const FixKind('CHANGE_TO', 49, "Change to '{0}'");
  static const CHANGE_TO_STATIC_ACCESS = const FixKind(
      'CHANGE_TO_STATIC_ACCESS', 50, "Change access to static using '{0}'");
  static const CHANGE_TYPE_ANNOTATION = const FixKind(
      'CHANGE_TYPE_ANNOTATION', 50, "Change '{0}' to '{1}' type annotation");
  static const CONVERT_FLUTTER_CHILD =
      const FixKind('CONVERT_FLUTTER_CHILD', 50, "Convert to children:");
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
      const FixKind('CREATE_FIELD', 51, "Create field '{0}'");
  static const CREATE_FILE =
      const FixKind('CREATE_FILE', 50, "Create file '{0}'");
  static const CREATE_FUNCTION =
      const FixKind('CREATE_FUNCTION', 51, "Create function '{0}'");
  static const CREATE_GETTER =
      const FixKind('CREATE_GETTER', 50, "Create getter '{0}'");
  static const CREATE_LOCAL_VARIABLE =
      const FixKind('CREATE_LOCAL_VARIABLE', 50, "Create local variable '{0}'");
  static const CREATE_METHOD =
      const FixKind('CREATE_METHOD', 50, "Create method '{0}'");
  static const CREATE_MISSING_METHOD_CALL =
      const FixKind('CREATE_MISSING_METHOD_CALL', 49, "Create method 'call'.");
  static const CREATE_MISSING_OVERRIDES = const FixKind(
      'CREATE_MISSING_OVERRIDES', 49, "Create {0} missing override(s)");
  static const CREATE_NO_SUCH_METHOD = const FixKind(
      'CREATE_NO_SUCH_METHOD', 51, "Create 'noSuchMethod' method");
  static const IMPORT_LIBRARY_PREFIX = const FixKind('IMPORT_LIBRARY_PREFIX',
      51, "Use imported library '{0}' with prefix '{1}'");
  static const IMPORT_LIBRARY_PROJECT1 =
      const FixKind('IMPORT_LIBRARY_PROJECT1', 47, "Import library '{0}'");
  static const IMPORT_LIBRARY_PROJECT2 =
      const FixKind('IMPORT_LIBRARY_PROJECT2', 48, "Import library '{0}'");
  static const IMPORT_LIBRARY_PROJECT3 =
      const FixKind('IMPORT_LIBRARY_PROJECT3', 49, "Import library '{0}'");
  static const IMPORT_LIBRARY_SDK =
      const FixKind('IMPORT_LIBRARY_SDK', 49, "Import library '{0}'");
  static const IMPORT_LIBRARY_SHOW =
      const FixKind('IMPORT_LIBRARY_SHOW', 49, "Update library '{0}' import");
  static const INSERT_SEMICOLON =
      const FixKind('INSERT_SEMICOLON', 50, "Insert ';'");
  static const LINT_ADD_OVERRIDE =
      const FixKind('LINT_ADD_OVERRIDE', 50, "Add '@override' annotation");
  static const LINT_REMOVE_INTERPOLATION_BRACES = const FixKind(
      'LINT_REMOVE_INTERPOLATION_BRACES',
      50,
      'Remove unnecessary interpolation braces');
  static const MAKE_CLASS_ABSTRACT =
      const FixKind('MAKE_CLASS_ABSTRACT', 50, "Make class '{0}' abstract");
  static const REMOVE_DEAD_CODE =
      const FixKind('REMOVE_DEAD_CODE', 50, "Remove dead code");
  static const MAKE_FIELD_NOT_FINAL =
      const FixKind('MAKE_FIELD_NOT_FINAL', 50, "Make field '{0}' not final");
  static const REMOVE_PARAMETERS_IN_GETTER_DECLARATION = const FixKind(
      'REMOVE_PARAMETERS_IN_GETTER_DECLARATION',
      50,
      "Remove parameters in getter declaration");
  static const REMOVE_PARENTHESIS_IN_GETTER_INVOCATION = const FixKind(
      'REMOVE_PARENTHESIS_IN_GETTER_INVOCATION',
      50,
      "Remove parentheses in getter invocation");
  static const REMOVE_UNNECESSARY_CAST =
      const FixKind('REMOVE_UNNECESSARY_CAST', 50, "Remove unnecessary cast");
  static const REMOVE_UNUSED_CATCH_CLAUSE =
      const FixKind('REMOVE_UNUSED_CATCH', 50, "Remove unused 'catch' clause");
  static const REMOVE_UNUSED_CATCH_STACK = const FixKind(
      'REMOVE_UNUSED_CATCH_STACK', 50, "Remove unused stack trace variable");
  static const REMOVE_UNUSED_IMPORT =
      const FixKind('REMOVE_UNUSED_IMPORT', 50, "Remove unused import");
  static const REPLACE_BOOLEAN_WITH_BOOL = const FixKind(
      'REPLACE_BOOLEAN_WITH_BOOL', 50, "Replace 'boolean' with 'bool'");
  static const REPLACE_VAR_WITH_DYNAMIC = const FixKind(
      'REPLACE_VAR_WITH_DYNAMIC', 50, "Replace 'var' with 'dynamic'");
  static const REPLACE_RETURN_TYPE_FUTURE = const FixKind(
      'REPLACE_RETURN_TYPE_FUTURE',
      50,
      "Return 'Future' from 'async' function");
  static const REPLACE_WITH_NULL_AWARE = const FixKind(
      'REPLACE_WITH_NULL_AWARE',
      50,
      "Replace the '.' with a '?.' in the invocation");
  static const USE_CONST = const FixKind('USE_CONST', 50, "Change to constant");
  static const USE_EFFECTIVE_INTEGER_DIVISION = const FixKind(
      'USE_EFFECTIVE_INTEGER_DIVISION',
      50,
      "Use effective integer division ~/");
  static const USE_EQ_EQ_NULL =
      const FixKind('USE_EQ_EQ_NULL', 50, "Use == null instead of 'is Null'");
  static const USE_NOT_EQ_NULL =
      const FixKind('USE_NOT_EQ_NULL', 50, "Use != null instead of 'is! Null'");
}

/**
 * The implementation of [FixContext].
 */
class FixContextImpl implements FixContext {
  @override
  final ResourceProvider resourceProvider;

  @override
  final AnalysisContext analysisContext;

  @override
  final AnalysisError error;

  FixContextImpl(this.resourceProvider, this.analysisContext, this.error);

  FixContextImpl.from(FixContext other)
      : resourceProvider = other.resourceProvider,
        analysisContext = other.analysisContext,
        error = other.error;
}
