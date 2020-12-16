// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Return true if this [errorCode] is likely to have a fix associated with it.
bool hasFix(ErrorCode errorCode) =>
    errorCode == CompileTimeErrorCode.CAST_TO_NON_TYPE ||
    errorCode == CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER ||
    errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE ||
    errorCode == CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER ||
    errorCode == CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION ||
    errorCode == CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR ||
    errorCode ==
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE ||
    errorCode ==
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO ||
    errorCode ==
        CompileTimeErrorCode
            .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE ||
    errorCode ==
        CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR ||
    errorCode ==
        CompileTimeErrorCode
            .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS ||
    errorCode == CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT ||
    errorCode == CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME ||
    errorCode == CompileTimeErrorCode.FINAL_NOT_INITIALIZED ||
    errorCode == CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 ||
    errorCode == CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 ||
    errorCode ==
        CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS ||
    errorCode == CompileTimeErrorCode.UNDEFINED_IDENTIFIER ||
    errorCode ==
        CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE ||
    errorCode == CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE ||
    errorCode == CompileTimeErrorCode.INVALID_ANNOTATION ||
    errorCode == CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT ||
    errorCode == CompileTimeErrorCode.PART_OF_NON_PART ||
    errorCode == CompileTimeErrorCode.UNDEFINED_ANNOTATION ||
    errorCode == CompileTimeErrorCode.UNDEFINED_CLASS_BOOLEAN ||
    errorCode ==
        CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT ||
    errorCode == CompileTimeErrorCode.UNDEFINED_FUNCTION ||
    errorCode == CompileTimeErrorCode.UNDEFINED_GETTER ||
    errorCode == CompileTimeErrorCode.UNDEFINED_METHOD ||
    errorCode == CompileTimeErrorCode.UNDEFINED_SETTER ||
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
            errorCode.name == LintNames.prefer_const_constructors ||
            errorCode.name ==
                LintNames.prefer_const_constructors_in_immutables ||
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
  static const REMOVE_SETTING =
      FixKind('analysisOptions.fix.removeSetting', 50, "Remove '{0}'");
}

/// The implementation of [DartFixContext].
class DartFixContextImpl implements DartFixContext {
  @override
  final InstrumentationService instrumentationService;

  @override
  final ChangeWorkspace workspace;

  @override
  final ResolvedUnitResult resolveResult;

  @override
  final AnalysisError error;

  final List<TopLevelDeclaration> Function(String name)
      getTopLevelDeclarationsFunction;

  DartFixContextImpl(this.instrumentationService, this.workspace,
      this.resolveResult, this.error, this.getTopLevelDeclarationsFunction);

  @override
  List<TopLevelDeclaration> getTopLevelDeclarations(String name) {
    return getTopLevelDeclarationsFunction(name);
  }
}

/// An enumeration of quick fix kinds found in a Dart file.
class DartFixKind {
  static const ADD_ASYNC =
      FixKind('dart.fix.add.async', 50, "Add 'async' modifier");
  static const ADD_AWAIT =
      FixKind('dart.fix.add.await', 50, "Add 'await' keyword");
  static const ADD_EXPLICIT_CAST = FixKind(
      'dart.fix.add.explicitCast', 50, 'Add cast',
      appliedTogetherMessage: 'Add all casts in file');
  static const ADD_CONST =
      FixKind('dart.fix.add.const', 50, "Add 'const' modifier");
  static const ADD_CURLY_BRACES =
      FixKind('dart.fix.add.curlyBraces', 50, 'Add curly braces');
  static const ADD_DIAGNOSTIC_PROPERTY_REFERENCE = FixKind(
      'dart.fix.add.diagnosticPropertyReference',
      50,
      'Add a debug reference to this property');
  static const ADD_FIELD_FORMAL_PARAMETERS = FixKind(
      'dart.fix.add.fieldFormalParameters',
      70,
      'Add final field formal parameters');
  static const ADD_LATE =
      FixKind('dart.fix.add.late', 50, "Add 'late' modifier");
  static const ADD_MISSING_ENUM_CASE_CLAUSES = FixKind(
      'dart.fix.add.missingEnumCaseClauses', 50, 'Add missing case clauses');
  static const ADD_MISSING_PARAMETER_NAMED = FixKind(
      'dart.fix.add.missingParameterNamed', 70, "Add named parameter '{0}'");
  static const ADD_MISSING_PARAMETER_POSITIONAL = FixKind(
      'dart.fix.add.missingParameterPositional',
      69,
      'Add optional positional parameter');
  static const ADD_MISSING_PARAMETER_REQUIRED = FixKind(
      'dart.fix.add.missingParameterRequired',
      70,
      'Add required positional parameter');
  static const ADD_MISSING_REQUIRED_ARGUMENT = FixKind(
      'dart.fix.add.missingRequiredArgument',
      70,
      "Add required argument '{0}'");
  static const ADD_NE_NULL = FixKind('dart.fix.add.neNull', 50, 'Add != null',
      appliedTogetherMessage: 'Add != null everywhere in file');
  static const ADD_NULL_CHECK =
      FixKind('dart.fix.add.nullCheck', 50, 'Add a null check (!)');
  static const ADD_OVERRIDE =
      FixKind('dart.fix.add.override', 50, "Add '@override' annotation");
  static const ADD_REQUIRED =
      FixKind('dart.fix.add.required', 50, "Add '@required' annotation");
  static const ADD_REQUIRED2 =
      FixKind('dart.fix.add.required', 50, "Add 'required' keyword");
  static const ADD_RETURN_TYPE =
      FixKind('dart.fix.add.returnType', 50, 'Add return type');
  static const ADD_STATIC =
      FixKind('dart.fix.add.static', 50, "Add 'static' modifier");
  static const ADD_SUPER_CONSTRUCTOR_INVOCATION = FixKind(
      'dart.fix.add.superConstructorInvocation',
      50,
      'Add super constructor {0} invocation');
  static const ADD_TYPE_ANNOTATION =
      FixKind('dart.fix.add.typeAnnotation', 50, 'Add type annotation');
  static const CHANGE_ARGUMENT_NAME =
      FixKind('dart.fix.change.argumentName', 60, "Change to '{0}'");
  static const CHANGE_TO = FixKind('dart.fix.change.to', 51, "Change to '{0}'");
  static const CHANGE_TO_NEAREST_PRECISE_VALUE = FixKind(
      'dart.fix.change.toNearestPreciseValue',
      50,
      'Change to nearest precise int-as-double value: {0}');
  static const CHANGE_TO_STATIC_ACCESS = FixKind(
      'dart.fix.change.toStaticAccess',
      50,
      "Change access to static using '{0}'");
  static const CHANGE_TYPE_ANNOTATION = FixKind(
      'dart.fix.change.typeAnnotation',
      50,
      "Change '{0}' to '{1}' type annotation");
  static const CONVERT_FLUTTER_CHILD = FixKind(
      'dart.fix.flutter.convert.childToChildren', 50, 'Convert to children:');
  static const CONVERT_FLUTTER_CHILDREN = FixKind(
      'dart.fix.flutter.convert.childrenToChild', 50, 'Convert to child:');
  static const CONVERT_INTO_EXPRESSION_BODY = FixKind(
      'dart.fix.convert.toExpressionBody', 50, 'Convert to expression body');
  static const CONVERT_TO_CONTAINS =
      FixKind('dart.fix.convert.toContains', 50, "Convert to using 'contains'");
  static const CONVERT_TO_FOR_ELEMENT = FixKind(
      'dart.fix.convert.toForElement', 50, "Convert to a 'for' element");
  static const CONVERT_TO_GENERIC_FUNCTION_SYNTAX = FixKind(
      'dart.fix.convert.toGenericFunctionSyntax',
      50,
      "Convert into 'Function' syntax");
  static const CONVERT_TO_IF_ELEMENT =
      FixKind('dart.fix.convert.toIfElement', 50, "Convert to an 'if' element");
  static const CONVERT_TO_IF_NULL =
      FixKind('dart.fix.convert.toIfNull', 50, "Convert to use '??'");
  static const CONVERT_TO_INT_LITERAL =
      FixKind('dart.fix.convert.toIntLiteral', 50, 'Convert to an int literal');
  static const CONVERT_TO_LINE_COMMENT = FixKind(
      'dart.fix.convert.toLineComment',
      50,
      'Convert to line documentation comment');
  static const CONVERT_TO_LIST_LITERAL =
      FixKind('dart.fix.convert.toListLiteral', 50, 'Convert to list literal');
  static const CONVERT_TO_MAP_LITERAL =
      FixKind('dart.fix.convert.toMapLiteral', 50, 'Convert to map literal');
  static const CONVERT_TO_NAMED_ARGUMENTS = FixKind(
      'dart.fix.convert.toNamedArguments', 50, 'Convert to named arguments');
  static const CONVERT_TO_NULL_AWARE =
      FixKind('dart.fix.convert.toNullAware', 50, "Convert to use '?.'");
  static const CONVERT_TO_ON_TYPE =
      FixKind('dart.fix.convert.toOnType', 50, "Convert to 'on {0}'");
  static const CONVERT_TO_PACKAGE_IMPORT = FixKind(
      'dart.fix.convert.toPackageImport', 50, "Convert to 'package:' import");
  static const CONVERT_TO_RELATIVE_IMPORT = FixKind(
      'dart.fix.convert.toRelativeImport', 50, 'Convert to relative import');
  static const CONVERT_TO_SET_LITERAL =
      FixKind('dart.fix.convert.toSetLiteral', 50, 'Convert to set literal');
  static const CONVERT_TO_SINGLE_QUOTED_STRING = FixKind(
      'dart.fix.convert.toSingleQuotedString',
      50,
      'Convert to single quoted string');
  static const CONVERT_TO_SPREAD =
      FixKind('dart.fix.convert.toSpread', 50, 'Convert to a spread');
  static const CONVERT_TO_WHERE_TYPE =
      FixKind('dart.fix.convert.toWhereType', 50, "Convert to use 'whereType'");
  static const CREATE_CLASS =
      FixKind('dart.fix.create.class', 50, "Create class '{0}'");
  static const CREATE_CONSTRUCTOR =
      FixKind('dart.fix.create.constructor', 50, "Create constructor '{0}'");
  static const CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS = FixKind(
      'dart.fix.create.constructorForFinalFields',
      50,
      'Create constructor for final fields');
  static const CREATE_CONSTRUCTOR_SUPER = FixKind(
      'dart.fix.create.constructorSuper', 50, 'Create constructor to call {0}');
  static const CREATE_FIELD =
      FixKind('dart.fix.create.field', 49, "Create field '{0}'");
  static const CREATE_FILE =
      FixKind('dart.fix.create.file', 50, "Create file '{0}'");
  static const CREATE_FUNCTION =
      FixKind('dart.fix.create.function', 49, "Create function '{0}'");
  static const CREATE_GETTER =
      FixKind('dart.fix.create.getter', 50, "Create getter '{0}'");
  static const CREATE_LOCAL_VARIABLE = FixKind(
      'dart.fix.create.localVariable', 50, "Create local variable '{0}'");
  static const CREATE_METHOD =
      FixKind('dart.fix.create.method', 50, "Create method '{0}'");
  static const CREATE_MISSING_OVERRIDES = FixKind(
      'dart.fix.create.missingOverrides', 51, 'Create {0} missing override(s)');
  static const CREATE_MIXIN =
      FixKind('dart.fix.create.mixin', 50, "Create mixin '{0}'");
  static const CREATE_NO_SUCH_METHOD = FixKind(
      'dart.fix.create.noSuchMethod', 49, "Create 'noSuchMethod' method");
  static const CREATE_SETTER =
      FixKind('dart.fix.create.setter', 50, "Create setter '{0}'");
  static const DATA_DRIVEN = FixKind('dart.fix.dataDriven', 50, '{0}');
  static const EXTEND_CLASS_FOR_MIXIN =
      FixKind('dart.fix.extendClassForMixin', 50, "Extend the class '{0}'");
  static const IMPORT_ASYNC =
      FixKind('dart.fix.import.async', 49, "Import 'dart:async'");
  static const IMPORT_LIBRARY_PREFIX = FixKind('dart.fix.import.libraryPrefix',
      49, "Use imported library '{0}' with prefix '{1}'");
  static const IMPORT_LIBRARY_PROJECT1 =
      FixKind('dart.fix.import.libraryProject1', 53, "Import library '{0}'");
  static const IMPORT_LIBRARY_PROJECT2 =
      FixKind('dart.fix.import.libraryProject2', 52, "Import library '{0}'");
  static const IMPORT_LIBRARY_PROJECT3 =
      FixKind('dart.fix.import.libraryProject3', 51, "Import library '{0}'");
  static const IMPORT_LIBRARY_SDK =
      FixKind('dart.fix.import.librarySdk', 54, "Import library '{0}'");
  static const IMPORT_LIBRARY_SHOW =
      FixKind('dart.fix.import.libraryShow', 55, "Update library '{0}' import");
  static const INLINE_INVOCATION =
      FixKind('dart.fix.inlineInvocation', 30, "Inline invocation of '{0}'");
  static const INLINE_TYPEDEF =
      FixKind('dart.fix.inlineTypedef', 30, "Inline the definition of '{0}'");
  static const INSERT_SEMICOLON =
      FixKind('dart.fix.insertSemicolon', 50, "Insert ';'");
  static const MAKE_CLASS_ABSTRACT =
      FixKind('dart.fix.makeClassAbstract', 50, "Make class '{0}' abstract");
  static const MAKE_FIELD_NOT_FINAL =
      FixKind('dart.fix.makeFieldNotFinal', 50, "Make field '{0}' not final");
  static const MAKE_FINAL = FixKind('dart.fix.makeFinal', 50, 'Make final');
  static const MAKE_RETURN_TYPE_NULLABLE = FixKind(
      'dart.fix.makeReturnTypeNullable', 50, 'Make the return type nullable');
  static const MOVE_TYPE_ARGUMENTS_TO_CLASS = FixKind(
      'dart.fix.moveTypeArgumentsToClass',
      50,
      'Move type arguments to after class name');
  static const MAKE_VARIABLE_NOT_FINAL = FixKind(
      'dart.fix.makeVariableNotFinal', 50, "Make variable '{0}' not final");
  static const MAKE_VARIABLE_NULLABLE =
      FixKind('dart.fix.makeVariableNullable', 50, "Make '{0}' nullable");
  static const ORGANIZE_IMPORTS =
      FixKind('dart.fix.organize.imports', 50, 'Organize Imports');
  static const QUALIFY_REFERENCE =
      FixKind('dart.fix.qualifyReference', 50, "Use '{0}'");
  static const REMOVE_ANNOTATION =
      FixKind('dart.fix.remove.annotation', 50, "Remove the '{0}' annotation");
  static const REMOVE_ARGUMENT =
      FixKind('dart.fix.remove.argument', 50, 'Remove argument');
  static const REMOVE_AWAIT =
      FixKind('dart.fix.remove.await', 50, 'Remove await');
  static const REMOVE_COMPARISON =
      FixKind('dart.fix.remove.comparison', 50, 'Remove comparison');
  static const REMOVE_CONST =
      FixKind('dart.fix.remove.const', 50, 'Remove const');
  static const REMOVE_DEAD_CODE =
      FixKind('dart.fix.remove.deadCode', 50, 'Remove dead code');
  static const REMOVE_DUPLICATE_CASE = FixKind(
      'dart.fix.remove.duplicateCase', 50, 'Remove duplicate case statement');
  static const REMOVE_EMPTY_CATCH =
      FixKind('dart.fix.remove.emptyCatch', 50, 'Remove empty catch clause');
  static const REMOVE_EMPTY_CONSTRUCTOR_BODY = FixKind(
      'dart.fix.remove.emptyConstructorBody',
      50,
      'Remove empty constructor body');
  static const REMOVE_EMPTY_ELSE =
      FixKind('dart.fix.remove.emptyElse', 50, 'Remove empty else clause');
  static const REMOVE_EMPTY_STATEMENT =
      FixKind('dart.fix.remove.emptyStatement', 50, 'Remove empty statement');
  static const REMOVE_IF_NULL_OPERATOR =
      FixKind('dart.fix.remove.ifNullOperator', 50, "Remove the '??' operator");
  static const REMOVE_INITIALIZER =
      FixKind('dart.fix.remove.initializer', 50, 'Remove initializer');
  static const REMOVE_INTERPOLATION_BRACES = FixKind(
      'dart.fix.remove.interpolationBraces',
      50,
      'Remove unnecessary interpolation braces');
  static const REMOVE_METHOD_DECLARATION = FixKind(
      'dart.fix.remove.methodDeclaration', 50, 'Remove method declaration');
  static const REMOVE_NAME_FROM_COMBINATOR = FixKind(
      'dart.fix.remove.nameFromCombinator', 50, "Remove name from '{0}'");
  static const REMOVE_NON_NULL_ASSERTION =
      FixKind('dart.fix.remove.nonNullAssertion', 50, "Remove the '!'");
  static const REMOVE_OPERATOR =
      FixKind('dart.fix.remove.operator', 50, 'Remove the operator');
  static const REMOVE_PARAMETERS_IN_GETTER_DECLARATION = FixKind(
      'dart.fix.remove.parametersInGetterDeclaration',
      50,
      'Remove parameters in getter declaration');
  static const REMOVE_PARENTHESIS_IN_GETTER_INVOCATION = FixKind(
      'dart.fix.remove.parenthesisInGetterInvocation',
      50,
      'Remove parentheses in getter invocation');
  static const REMOVE_QUESTION_MARK =
      FixKind('dart.fix.remove.questionMark', 50, "Remove the '?'");
  static const REMOVE_THIS_EXPRESSION =
      FixKind('dart.fix.remove.thisExpression', 50, 'Remove this expression');
  static const REMOVE_TYPE_ANNOTATION =
      FixKind('dart.fix.remove.typeAnnotation', 50, 'Remove type annotation');
  static const REMOVE_TYPE_ARGUMENTS =
      FixKind('dart.fix.remove.typeArguments', 49, 'Remove type arguments');
  static const REMOVE_UNNECESSARY_CAST = FixKind(
      'dart.fix.remove.unnecessaryCast', 50, 'Remove unnecessary cast',
      appliedTogetherMessage: 'Remove all unnecessary casts in file');
  static const REMOVE_UNNECESSARY_CONST = FixKind(
      'dart.fix.remove.unnecessaryConst',
      50,
      'Remove unnecessary const keyword');
  static const REMOVE_UNNECESSARY_NEW = FixKind(
      'dart.fix.remove.unnecessaryNew', 50, 'Remove unnecessary new keyword');
  static const REMOVE_UNUSED_CATCH_CLAUSE = FixKind(
      'dart.fix.remove.unusedCatchClause', 50, "Remove unused 'catch' clause");
  static const REMOVE_UNUSED_CATCH_STACK = FixKind(
      'dart.fix.remove.unusedCatchStack',
      50,
      'Remove unused stack trace variable');
  static const REMOVE_UNUSED_ELEMENT =
      FixKind('dart.fix.remove.unusedElement', 50, 'Remove unused element');
  static const REMOVE_UNUSED_FIELD =
      FixKind('dart.fix.remove.unusedField', 50, 'Remove unused field');
  static const REMOVE_UNUSED_IMPORT = FixKind(
      'dart.fix.remove.unusedImport', 50, 'Remove unused import',
      appliedTogetherMessage: 'Remove all unused imports in this file');
  static const REMOVE_UNUSED_LABEL =
      FixKind('dart.fix.remove.unusedLabel', 50, 'Remove unused label');
  static const REMOVE_UNUSED_LOCAL_VARIABLE = FixKind(
      'dart.fix.remove.unusedLocalVariable',
      50,
      'Remove unused local variable');
  static const REMOVE_UNUSED_PARAMETER = FixKind(
      'dart.fix.remove.unusedParameter', 50, 'Remove the unused parameter');
  static const RENAME_TO_CAMEL_CASE =
      FixKind('dart.fix.rename.toCamelCase', 50, "Rename to '{0}'");
  static const REPLACE_BOOLEAN_WITH_BOOL = FixKind(
      'dart.fix.replace.booleanWithBool', 50, "Replace 'boolean' with 'bool'",
      appliedTogetherMessage: "Replace all 'boolean' with 'bool' in file");
  static const REPLACE_CASCADE_WITH_DOT =
      FixKind('dart.fix.replace.cascadeWithDot', 50, "Replace '..' with '.'");
  static const REPLACE_COLON_WITH_EQUALS =
      FixKind('dart.fix.replace.colonWithEquals', 50, "Replace ':' with '='");
  static const REPLACE_WITH_FILLED = FixKind(
      'dart.fix.replace.finalWithListFilled', 50, "Replace with 'List.filled'");
  static const REPLACE_FINAL_WITH_CONST = FixKind(
      'dart.fix.replace.finalWithConst', 50, "Replace 'final' with 'const'");
  static const REPLACE_NEW_WITH_CONST = FixKind(
      'dart.fix.replace.newWithConst', 50, "Replace 'new' with 'const'");
  static const REPLACE_NULL_WITH_CLOSURE = FixKind(
      'dart.fix.replace.nullWithClosure', 50, "Replace 'null' with a closure");
  static const REPLACE_RETURN_TYPE_FUTURE = FixKind(
      'dart.fix.replace.returnTypeFuture',
      50,
      "Return 'Future' from 'async' function");
  static const REPLACE_VAR_WITH_DYNAMIC = FixKind(
      'dart.fix.replace.varWithDynamic', 50, "Replace 'var' with 'dynamic'");
  static const REPLACE_WITH_EIGHT_DIGIT_HEX =
      FixKind('dart.fix.replace.withEightDigitHex', 50, "Replace with '{0}'");
  static const REPLACE_WITH_BRACKETS =
      FixKind('dart.fix.replace.withBrackets', 50, 'Replace with { }');
  static const REPLACE_WITH_CONDITIONAL_ASSIGNMENT = FixKind(
      'dart.fix.replace.withConditionalAssignment', 50, 'Replace with ??=');
  static const REPLACE_WITH_EXTENSION_NAME =
      FixKind('dart.fix.replace.withExtensionName', 50, "Replace with '{0}'");
  static const REPLACE_WITH_IDENTIFIER =
      FixKind('dart.fix.replace.withIdentifier', 50, 'Replace with identifier');
  static const REPLACE_WITH_INTERPOLATION = FixKind(
      'dart.fix.replace.withInterpolation', 50, 'Replace with interpolation');
  static const REPLACE_WITH_IS_EMPTY =
      FixKind('dart.fix.replace.withIsEmpty', 50, "Replace with 'isEmpty'");
  static const REPLACE_WITH_IS_NOT_EMPTY = FixKind(
      'dart.fix.replace.withIsNotEmpty', 50, "Replace with 'isNotEmpty'");
  static const REPLACE_WITH_NOT_NULL_AWARE =
      FixKind('dart.fix.replace.withNotNullAware', 50, "Replace with '{0}'");
  static const REPLACE_WITH_NULL_AWARE = FixKind(
      'dart.fix.replace.withNullAware',
      50,
      "Replace the '.' with a '?.' in the invocation");
  static const REPLACE_WITH_TEAR_OFF = FixKind('dart.fix.replace.withTearOff',
      50, 'Replace function literal with tear-off');
  static const REPLACE_WITH_VAR = FixKind(
      'dart.fix.replace.withVar', 50, "Replace type annotation with 'var'");
  static const SORT_CHILD_PROPERTY_LAST = FixKind(
      'dart.fix.sort.childPropertyLast',
      50,
      'Move child property to end of arguments');
  static const UPDATE_SDK_CONSTRAINTS = FixKind(
      'dart.fix.updateSdkConstraints', 50, 'Update the SDK constraints');
  static const USE_CONST =
      FixKind('dart.fix.use.const', 50, 'Change to constant');
  static const USE_EFFECTIVE_INTEGER_DIVISION = FixKind(
      'dart.fix.use.effectiveIntegerDivision',
      50,
      'Use effective integer division ~/');
  static const USE_EQ_EQ_NULL = FixKind(
      'dart.fix.use.eqEqNull', 50, "Use == null instead of 'is Null'",
      appliedTogetherMessage:
          "Use == null instead of 'is Null' everywhere in file");
  static const USE_IS_NOT_EMPTY = FixKind('dart.fix.use.isNotEmpty', 50,
      "Use x.isNotEmpty instead of '!x.isEmpty'");
  static const USE_NOT_EQ_NULL = FixKind(
      'dart.fix.use.notEqNull', 50, "Use != null instead of 'is! Null'",
      appliedTogetherMessage:
          "Use != null instead of 'is! Null' everywhere in file");
  static const USE_RETHROW =
      FixKind('dart.fix.use.rethrow', 50, 'Replace throw with rethrow');
  static const WRAP_IN_FUTURE =
      FixKind('dart.fix.wrap.future', 50, "Wrap in 'Future.value'");
  static const WRAP_IN_TEXT =
      FixKind('dart.fix.flutter.wrap.text', 50, "Wrap in a 'Text' widget");
}

/// An enumeration of quick fix kinds for the errors found in an Android
/// manifest file.
class ManifestFixKind {}

/// An enumeration of quick fix kinds for the errors found in a pubspec file.
class PubspecFixKind {}
