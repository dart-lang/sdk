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
  static const REMOVE_LINT =
      FixKind('analysisOptions.fix.removeLint', 50, "Remove '{0}'");
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
  static const ADD_ASYNC = FixKind('dart.fix.add.async',
      DartFixKindPriority.DEFAULT, "Add 'async' modifier");
  static const ADD_AWAIT = FixKind(
      'dart.fix.add.await', DartFixKindPriority.DEFAULT, "Add 'await' keyword");
  static const ADD_AWAIT_MULTI = FixKind('dart.fix.add.await.multi',
      DartFixKindPriority.IN_FILE, "Add 'await's everywhere in file");
  static const ADD_EXPLICIT_CAST = FixKind(
      'dart.fix.add.explicitCast', DartFixKindPriority.DEFAULT, 'Add cast');
  static const ADD_CONST = FixKind('dart.fix.add.const',
      DartFixKindPriority.DEFAULT, "Add 'const' modifier");
  static const ADD_CONST_MULTI = FixKind('dart.fix.add.const.multi',
      DartFixKindPriority.IN_FILE, "Add 'const' modifiers everywhere in file");
  static const ADD_CURLY_BRACES = FixKind('dart.fix.add.curlyBraces',
      DartFixKindPriority.DEFAULT, 'Add curly braces');
  static const ADD_CURLY_BRACES_MULTI = FixKind(
      'dart.fix.add.curlyBraces.multi',
      DartFixKindPriority.IN_FILE,
      'Add curly braces everywhere in file');
  static const ADD_DIAGNOSTIC_PROPERTY_REFERENCE = FixKind(
      'dart.fix.add.diagnosticPropertyReference',
      DartFixKindPriority.DEFAULT,
      'Add a debug reference to this property');
  static const ADD_DIAGNOSTIC_PROPERTY_REFERENCE_MULTI = FixKind(
      'dart.fix.add.diagnosticPropertyReference.multi',
      DartFixKindPriority.IN_FILE,
      'Add missing debug property references everywhere in file');
  static const ADD_FIELD_FORMAL_PARAMETERS = FixKind(
      'dart.fix.add.fieldFormalParameters',
      70,
      'Add final field formal parameters');
  static const ADD_LATE = FixKind(
      'dart.fix.add.late', DartFixKindPriority.DEFAULT, "Add 'late' modifier");
  static const ADD_MISSING_ENUM_CASE_CLAUSES = FixKind(
      'dart.fix.add.missingEnumCaseClauses',
      DartFixKindPriority.DEFAULT,
      'Add missing case clauses');
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
  static const ADD_NE_NULL = FixKind(
      'dart.fix.add.neNull', DartFixKindPriority.DEFAULT, 'Add != null');
  static const ADD_NE_NULL_MULTI = FixKind('dart.fix.add.neNull.multi',
      DartFixKindPriority.IN_FILE, 'Add != null everywhere in file');
  static const ADD_NULL_CHECK = FixKind('dart.fix.add.nullCheck',
      DartFixKindPriority.DEFAULT, 'Add a null check (!)');
  static const ADD_OVERRIDE = FixKind('dart.fix.add.override',
      DartFixKindPriority.DEFAULT, "Add '@override' annotation");
  static const ADD_OVERRIDE_MULTI = FixKind(
      'dart.fix.add.override.multi',
      DartFixKindPriority.IN_FILE,
      "Add '@override' annotations everywhere in file");
  static const ADD_REQUIRED = FixKind('dart.fix.add.required',
      DartFixKindPriority.DEFAULT, "Add '@required' annotation");
  static const ADD_REQUIRED_MULTI = FixKind(
      'dart.fix.add.required.multi',
      DartFixKindPriority.IN_FILE,
      "Add '@required' annotations everywhere in file");
  static const ADD_REQUIRED2 = FixKind('dart.fix.add.required',
      DartFixKindPriority.DEFAULT, "Add 'required' keyword");
  static const ADD_REQUIRED2_MULTI = FixKind(
      'dart.fix.add.required.multi',
      DartFixKindPriority.IN_FILE,
      "Add 'required' keywords everywhere in file");
  static const ADD_RETURN_TYPE = FixKind('dart.fix.add.returnType',
      DartFixKindPriority.DEFAULT, 'Add return type');
  static const ADD_RETURN_TYPE_MULTI = FixKind('dart.fix.add.returnType.multi',
      DartFixKindPriority.IN_FILE, 'Add return types everywhere in file');
  static const ADD_STATIC = FixKind('dart.fix.add.static',
      DartFixKindPriority.DEFAULT, "Add 'static' modifier");
  static const ADD_SUPER_CONSTRUCTOR_INVOCATION = FixKind(
      'dart.fix.add.superConstructorInvocation',
      DartFixKindPriority.DEFAULT,
      'Add super constructor {0} invocation');
  static const ADD_TYPE_ANNOTATION = FixKind('dart.fix.add.typeAnnotation',
      DartFixKindPriority.DEFAULT, 'Add type annotation');
  static const ADD_TYPE_ANNOTATION_MULTI = FixKind(
      'dart.fix.add.typeAnnotation.multi',
      DartFixKindPriority.IN_FILE,
      'Add type annotations everywhere in file');
  static const CHANGE_ARGUMENT_NAME =
      FixKind('dart.fix.change.argumentName', 60, "Change to '{0}'");
  static const CHANGE_TO = FixKind(
      'dart.fix.change.to', DartFixKindPriority.DEFAULT + 1, "Change to '{0}'");
  static const CHANGE_TO_NEAREST_PRECISE_VALUE = FixKind(
      'dart.fix.change.toNearestPreciseValue',
      DartFixKindPriority.DEFAULT,
      'Change to nearest precise int-as-double value: {0}');
  static const CHANGE_TO_STATIC_ACCESS = FixKind(
      'dart.fix.change.toStaticAccess',
      DartFixKindPriority.DEFAULT,
      "Change access to static using '{0}'");
  static const CHANGE_TYPE_ANNOTATION = FixKind(
      'dart.fix.change.typeAnnotation',
      DartFixKindPriority.DEFAULT,
      "Change '{0}' to '{1}' type annotation");
  static const CONVERT_FLUTTER_CHILD = FixKind(
      'dart.fix.flutter.convert.childToChildren',
      DartFixKindPriority.DEFAULT,
      'Convert to children:');
  static const CONVERT_FLUTTER_CHILDREN = FixKind(
      'dart.fix.flutter.convert.childrenToChild',
      DartFixKindPriority.DEFAULT,
      'Convert to child:');
  static const CONVERT_INTO_EXPRESSION_BODY = FixKind(
      'dart.fix.convert.toExpressionBody',
      DartFixKindPriority.DEFAULT,
      'Convert to expression body');
  static const CONVERT_INTO_EXPRESSION_BODY_MULTI = FixKind(
      'dart.fix.convert.toExpressionBody.multi',
      DartFixKindPriority.IN_FILE,
      'Convert to expression bodies everywhere in file');
  static const CONVERT_TO_CONTAINS = FixKind('dart.fix.convert.toContains',
      DartFixKindPriority.DEFAULT, "Convert to using 'contains'");
  static const CONVERT_TO_CONTAINS_MULTI = FixKind(
      'dart.fix.convert.toContains.multi',
      DartFixKindPriority.IN_FILE,
      "Convert to using 'contains' everywhere in file");
  static const CONVERT_TO_FOR_ELEMENT = FixKind('dart.fix.convert.toForElement',
      DartFixKindPriority.DEFAULT, "Convert to a 'for' element");
  static const CONVERT_TO_FOR_ELEMENT_MULTI = FixKind(
      'dart.fix.convert.toForElement.multi',
      DartFixKindPriority.IN_FILE,
      "Convert to 'for' elements everywhere in file");
  static const CONVERT_TO_GENERIC_FUNCTION_SYNTAX = FixKind(
      'dart.fix.convert.toGenericFunctionSyntax',
      DartFixKindPriority.DEFAULT,
      "Convert into 'Function' syntax");
  static const CONVERT_TO_GENERIC_FUNCTION_SYNTAX_MULTI = FixKind(
      'dart.fix.convert.toGenericFunctionSyntax.multi',
      DartFixKindPriority.IN_FILE,
      "Convert to 'Function' syntax everywhere in file");
  static const CONVERT_TO_IF_ELEMENT = FixKind('dart.fix.convert.toIfElement',
      DartFixKindPriority.DEFAULT, "Convert to an 'if' element");
  static const CONVERT_TO_IF_ELEMENT_MULTI = FixKind(
      'dart.fix.convert.toIfElement.multi',
      DartFixKindPriority.IN_FILE,
      "Convert to 'if' elements everywhere in file");
  static const CONVERT_TO_IF_NULL = FixKind('dart.fix.convert.toIfNull',
      DartFixKindPriority.DEFAULT, "Convert to use '??'");
  static const CONVERT_TO_IF_NULL_MULTI = FixKind(
      'dart.fix.convert.toIfNull.multi',
      DartFixKindPriority.IN_FILE,
      "Convert to '??'s everywhere in file");
  static const CONVERT_TO_INT_LITERAL = FixKind('dart.fix.convert.toIntLiteral',
      DartFixKindPriority.DEFAULT, 'Convert to an int literal');
  static const CONVERT_TO_INT_LITERAL_MULTI = FixKind(
      'dart.fix.convert.toIntLiteral.multi',
      DartFixKindPriority.IN_FILE,
      'Convert to int literals everywhere in file');
  static const CONVERT_TO_LINE_COMMENT = FixKind(
      'dart.fix.convert.toLineComment',
      DartFixKindPriority.DEFAULT,
      'Convert to line documentation comment');
  static const CONVERT_TO_LINE_COMMENT_MULTI = FixKind(
      'dart.fix.convert.toLineComment.multi',
      DartFixKindPriority.IN_FILE,
      'Convert to line documentation comments everywhere in file');
  static const CONVERT_TO_LIST_LITERAL = FixKind(
      'dart.fix.convert.toListLiteral',
      DartFixKindPriority.DEFAULT,
      'Convert to list literal');
  static const CONVERT_TO_LIST_LITERAL_MULTI = FixKind(
      'dart.fix.convert.toListLiteral.multi',
      DartFixKindPriority.IN_FILE,
      'Convert to list literals everywhere in file');
  static const CONVERT_TO_MAP_LITERAL = FixKind('dart.fix.convert.toMapLiteral',
      DartFixKindPriority.DEFAULT, 'Convert to map literal');
  static const CONVERT_TO_MAP_LITERAL_MULTI = FixKind(
      'dart.fix.convert.toMapLiteral.multi',
      DartFixKindPriority.IN_FILE,
      'Convert to map literals everywhere in file');
  static const CONVERT_TO_NAMED_ARGUMENTS = FixKind(
      'dart.fix.convert.toNamedArguments',
      DartFixKindPriority.DEFAULT,
      'Convert to named arguments');
  static const CONVERT_TO_NULL_AWARE = FixKind('dart.fix.convert.toNullAware',
      DartFixKindPriority.DEFAULT, "Convert to use '?.'");
  static const CONVERT_TO_NULL_AWARE_MULTI = FixKind(
      'dart.fix.convert.toNullAware.multi',
      DartFixKindPriority.IN_FILE,
      "Convert to use '?.' everywhere in file");
  static const CONVERT_TO_NULL_AWARE_SPREAD = FixKind(
      'dart.fix.convert.toNullAwareSpread',
      DartFixKindPriority.DEFAULT,
      "Convert to use '...?'");
  static const CONVERT_TO_NULL_AWARE_SPREAD_MULTI = FixKind(
      'dart.fix.convert.toNullAwareSpread.multi',
      DartFixKindPriority.IN_FILE,
      "Convert to use '...?' everywhere in file");
  static const CONVERT_TO_ON_TYPE = FixKind('dart.fix.convert.toOnType',
      DartFixKindPriority.DEFAULT, "Convert to 'on {0}'");
  static const CONVERT_TO_PACKAGE_IMPORT = FixKind(
      'dart.fix.convert.toPackageImport',
      DartFixKindPriority.DEFAULT,
      "Convert to 'package:' import");
  static const CONVERT_TO_PACKAGE_IMPORT_MULTI = FixKind(
      'dart.fix.convert.toPackageImport.multi',
      DartFixKindPriority.IN_FILE,
      "Convert to 'package:' imports everywhere in file");
  static const CONVERT_TO_RELATIVE_IMPORT = FixKind(
      'dart.fix.convert.toRelativeImport',
      DartFixKindPriority.DEFAULT,
      'Convert to relative import');
  static const CONVERT_TO_RELATIVE_IMPORT_MULTI = FixKind(
      'dart.fix.convert.toRelativeImport.multi',
      DartFixKindPriority.IN_FILE,
      'Convert to relative imports everywhere in file');
  static const CONVERT_TO_SET_LITERAL = FixKind('dart.fix.convert.toSetLiteral',
      DartFixKindPriority.DEFAULT, 'Convert to set literal');
  static const CONVERT_TO_SET_LITERAL_MULTI = FixKind(
      'dart.fix.convert.toSetLiteral.multi',
      DartFixKindPriority.IN_FILE,
      'Convert to set literals everywhere in file');
  static const CONVERT_TO_SINGLE_QUOTED_STRING = FixKind(
      'dart.fix.convert.toSingleQuotedString',
      DartFixKindPriority.DEFAULT,
      'Convert to single quoted string');
  static const CONVERT_TO_SINGLE_QUOTED_STRING_MULTI = FixKind(
      'dart.fix.convert.toSingleQuotedString.multi',
      DartFixKindPriority.IN_FILE,
      'Convert to single quoted strings everywhere in file');
  static const CONVERT_TO_SPREAD = FixKind('dart.fix.convert.toSpread',
      DartFixKindPriority.DEFAULT, 'Convert to a spread');
  static const CONVERT_TO_SPREAD_MULTI = FixKind(
      'dart.fix.convert.toSpread.multi',
      DartFixKindPriority.IN_FILE,
      'Convert to spreads everywhere in file');
  static const CONVERT_TO_WHERE_TYPE = FixKind('dart.fix.convert.toWhereType',
      DartFixKindPriority.DEFAULT, "Convert to use 'whereType'");
  static const CONVERT_TO_WHERE_TYPE_MULTI = FixKind(
      'dart.fix.convert.toWhereType.multi',
      DartFixKindPriority.IN_FILE,
      "Convert to using 'whereType' everywhere in file");
  static const CREATE_CLASS = FixKind('dart.fix.create.class',
      DartFixKindPriority.DEFAULT, "Create class '{0}'");
  static const CREATE_CONSTRUCTOR = FixKind('dart.fix.create.constructor',
      DartFixKindPriority.DEFAULT, "Create constructor '{0}'");
  static const CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS = FixKind(
      'dart.fix.create.constructorForFinalFields',
      DartFixKindPriority.DEFAULT,
      'Create constructor for final fields');
  static const CREATE_CONSTRUCTOR_SUPER = FixKind(
      'dart.fix.create.constructorSuper',
      DartFixKindPriority.DEFAULT,
      'Create constructor to call {0}');
  static const CREATE_FIELD =
      FixKind('dart.fix.create.field', 49, "Create field '{0}'");
  static const CREATE_FILE = FixKind(
      'dart.fix.create.file', DartFixKindPriority.DEFAULT, "Create file '{0}'");
  static const CREATE_FUNCTION =
      FixKind('dart.fix.create.function', 49, "Create function '{0}'");
  static const CREATE_GETTER = FixKind('dart.fix.create.getter',
      DartFixKindPriority.DEFAULT, "Create getter '{0}'");
  static const CREATE_LOCAL_VARIABLE = FixKind('dart.fix.create.localVariable',
      DartFixKindPriority.DEFAULT, "Create local variable '{0}'");
  static const CREATE_METHOD = FixKind('dart.fix.create.method',
      DartFixKindPriority.DEFAULT, "Create method '{0}'");
  // todo (pq): used by LintNames.hash_and_equals; consider removing.
  static const CREATE_METHOD_MULTI = FixKind('dart.fix.create.method.multi',
      DartFixKindPriority.IN_FILE, 'Create methods in file');
  static const CREATE_MISSING_OVERRIDES = FixKind(
      'dart.fix.create.missingOverrides',
      DartFixKindPriority.DEFAULT + 1,
      'Create {0} missing override(s)');
  static const CREATE_MIXIN = FixKind('dart.fix.create.mixin',
      DartFixKindPriority.DEFAULT, "Create mixin '{0}'");
  static const CREATE_NO_SUCH_METHOD = FixKind(
      'dart.fix.create.noSuchMethod', 49, "Create 'noSuchMethod' method");
  static const CREATE_SETTER = FixKind('dart.fix.create.setter',
      DartFixKindPriority.DEFAULT, "Create setter '{0}'");
  static const DATA_DRIVEN =
      FixKind('dart.fix.dataDriven', DartFixKindPriority.DEFAULT, '{0}');
  static const EXTEND_CLASS_FOR_MIXIN = FixKind('dart.fix.extendClassForMixin',
      DartFixKindPriority.DEFAULT, "Extend the class '{0}'");
  static const IMPORT_ASYNC =
      FixKind('dart.fix.import.async', 49, "Import 'dart:async'");
  static const IMPORT_LIBRARY_PREFIX = FixKind('dart.fix.import.libraryPrefix',
      49, "Use imported library '{0}' with prefix '{1}'");
  static const IMPORT_LIBRARY_PROJECT1 = FixKind(
      'dart.fix.import.libraryProject1',
      DartFixKindPriority.DEFAULT + 3,
      "Import library '{0}'");
  static const IMPORT_LIBRARY_PROJECT2 = FixKind(
      'dart.fix.import.libraryProject2',
      DartFixKindPriority.DEFAULT + 2,
      "Import library '{0}'");
  static const IMPORT_LIBRARY_PROJECT3 = FixKind(
      'dart.fix.import.libraryProject3',
      DartFixKindPriority.DEFAULT + 1,
      "Import library '{0}'");
  static const IMPORT_LIBRARY_SDK = FixKind('dart.fix.import.librarySdk',
      DartFixKindPriority.DEFAULT + 4, "Import library '{0}'");
  static const IMPORT_LIBRARY_SHOW = FixKind('dart.fix.import.libraryShow',
      DartFixKindPriority.DEFAULT + 5, "Update library '{0}' import");
  static const INLINE_INVOCATION = FixKind('dart.fix.inlineInvocation',
      DartFixKindPriority.DEFAULT - 20, "Inline invocation of '{0}'");
  static const INLINE_INVOCATION_MULTI = FixKind(
      'dart.fix.inlineInvocation.multi',
      DartFixKindPriority.IN_FILE - 20,
      'Inline invocations everywhere in file');
  static const INLINE_TYPEDEF = FixKind('dart.fix.inlineTypedef',
      DartFixKindPriority.DEFAULT - 20, "Inline the definition of '{0}'");
  static const INLINE_TYPEDEF_MULTI = FixKind(
      'dart.fix.inlineTypedef.multi',
      DartFixKindPriority.IN_FILE - 20,
      'Inline type definitions everywhere in file');
  static const INSERT_SEMICOLON = FixKind(
      'dart.fix.insertSemicolon', DartFixKindPriority.DEFAULT, "Insert ';'");
  static const MAKE_CLASS_ABSTRACT = FixKind('dart.fix.makeClassAbstract',
      DartFixKindPriority.DEFAULT, "Make class '{0}' abstract");
  static const MAKE_FIELD_NOT_FINAL = FixKind('dart.fix.makeFieldNotFinal',
      DartFixKindPriority.DEFAULT, "Make field '{0}' not final");
  static const MAKE_FINAL =
      FixKind('dart.fix.makeFinal', DartFixKindPriority.DEFAULT, 'Make final');
  // todo (pq): consider parameterizing: 'Make {fields} final...'
  static const MAKE_FINAL_MULTI = FixKind('dart.fix.makeFinal.multi',
      DartFixKindPriority.IN_FILE, 'Make final where possible in file');
  static const MAKE_RETURN_TYPE_NULLABLE = FixKind(
      'dart.fix.makeReturnTypeNullable',
      DartFixKindPriority.DEFAULT,
      'Make the return type nullable');
  static const MOVE_TYPE_ARGUMENTS_TO_CLASS = FixKind(
      'dart.fix.moveTypeArgumentsToClass',
      DartFixKindPriority.DEFAULT,
      'Move type arguments to after class name');
  static const MAKE_VARIABLE_NOT_FINAL = FixKind(
      'dart.fix.makeVariableNotFinal',
      DartFixKindPriority.DEFAULT,
      "Make variable '{0}' not final");
  static const MAKE_VARIABLE_NULLABLE = FixKind('dart.fix.makeVariableNullable',
      DartFixKindPriority.DEFAULT, "Make '{0}' nullable");
  static const ORGANIZE_IMPORTS = FixKind('dart.fix.organize.imports',
      DartFixKindPriority.DEFAULT, 'Organize Imports');
  static const QUALIFY_REFERENCE = FixKind(
      'dart.fix.qualifyReference', DartFixKindPriority.DEFAULT, "Use '{0}'");
  static const REMOVE_ANNOTATION = FixKind('dart.fix.remove.annotation',
      DartFixKindPriority.DEFAULT, "Remove the '{0}' annotation");
  static const REMOVE_ARGUMENT = FixKind('dart.fix.remove.argument',
      DartFixKindPriority.DEFAULT, 'Remove argument');
  // todo (pq): used by LintNames.avoid_redundant_argument_values; consider a parameterized message
  static const REMOVE_ARGUMENT_MULTI = FixKind('dart.fix.remove.argument.multi',
      DartFixKindPriority.IN_FILE, 'Remove arguments in file');
  static const REMOVE_AWAIT = FixKind(
      'dart.fix.remove.await', DartFixKindPriority.DEFAULT, 'Remove await');
  static const REMOVE_AWAIT_MULTI = FixKind('dart.fix.remove.await.multi',
      DartFixKindPriority.IN_FILE, 'Remove awaits in file');
  static const REMOVE_COMPARISON = FixKind('dart.fix.remove.comparison',
      DartFixKindPriority.DEFAULT, 'Remove comparison');
  static const REMOVE_CONST = FixKind(
      'dart.fix.remove.const', DartFixKindPriority.DEFAULT, 'Remove const');
  static const REMOVE_DEAD_CODE = FixKind('dart.fix.remove.deadCode',
      DartFixKindPriority.DEFAULT, 'Remove dead code');
  static const REMOVE_DUPLICATE_CASE = FixKind('dart.fix.remove.duplicateCase',
      DartFixKindPriority.DEFAULT, 'Remove duplicate case statement');
  // todo (pq): is this dangerous to bulk apply?  Consider removing.
  static const REMOVE_DUPLICATE_CASE_MULTI = FixKind(
      'dart.fix.remove.duplicateCase.multi',
      DartFixKindPriority.IN_FILE,
      'Remove duplicate case statement');
  static const REMOVE_EMPTY_CATCH = FixKind('dart.fix.remove.emptyCatch',
      DartFixKindPriority.DEFAULT, 'Remove empty catch clause');
  static const REMOVE_EMPTY_CATCH_MULTI = FixKind(
      'dart.fix.remove.emptyCatch.multi',
      DartFixKindPriority.IN_FILE,
      'Remove empty catch clauses everywhere in file');
  static const REMOVE_EMPTY_CONSTRUCTOR_BODY = FixKind(
      'dart.fix.remove.emptyConstructorBody',
      DartFixKindPriority.DEFAULT,
      'Remove empty constructor body');
  static const REMOVE_EMPTY_CONSTRUCTOR_BODY_MULTI = FixKind(
      'dart.fix.remove.emptyConstructorBody.multi',
      DartFixKindPriority.IN_FILE,
      'Remove empty constructor bodies in file');
  static const REMOVE_EMPTY_ELSE = FixKind('dart.fix.remove.emptyElse',
      DartFixKindPriority.DEFAULT, 'Remove empty else clause');
  static const REMOVE_EMPTY_ELSE_MULTI = FixKind(
      'dart.fix.remove.emptyElse.multi',
      DartFixKindPriority.IN_FILE,
      'Remove empty else clauses everywhere in file');
  static const REMOVE_EMPTY_STATEMENT = FixKind(
      'dart.fix.remove.emptyStatement',
      DartFixKindPriority.DEFAULT,
      'Remove empty statement');
  static const REMOVE_EMPTY_STATEMENT_MULTI = FixKind(
      'dart.fix.remove.emptyStatement.multi',
      DartFixKindPriority.IN_FILE,
      'Remove empty statements everywhere in file');
  static const REMOVE_IF_NULL_OPERATOR = FixKind(
      'dart.fix.remove.ifNullOperator',
      DartFixKindPriority.DEFAULT,
      "Remove the '??' operator");
  static const REMOVE_IF_NULL_OPERATOR_MULTI = FixKind(
      'dart.fix.remove.ifNullOperator.multi',
      DartFixKindPriority.IN_FILE,
      "Remove unnecessary '??' operators everywhere in file");
  static const REMOVE_INITIALIZER = FixKind('dart.fix.remove.initializer',
      DartFixKindPriority.DEFAULT, 'Remove initializer');
  static const REMOVE_INITIALIZER_MULTI = FixKind(
      'dart.fix.remove.initializer.multi',
      DartFixKindPriority.IN_FILE,
      'Remove unnecessary initializers everywhere in file');
  static const REMOVE_INTERPOLATION_BRACES = FixKind(
      'dart.fix.remove.interpolationBraces',
      DartFixKindPriority.DEFAULT,
      'Remove unnecessary interpolation braces');
  static const REMOVE_INTERPOLATION_BRACES_MULTI = FixKind(
      'dart.fix.remove.interpolationBraces.multi',
      DartFixKindPriority.IN_FILE,
      'Remove unnecessary interpolation braces everywhere in file');
  static const REMOVE_METHOD_DECLARATION = FixKind(
      'dart.fix.remove.methodDeclaration',
      DartFixKindPriority.DEFAULT,
      'Remove method declaration');
  // todo (pq): parameterize to make scope explicit
  static const REMOVE_METHOD_DECLARATION_MULTI = FixKind(
      'dart.fix.remove.methodDeclaration.multi',
      DartFixKindPriority.IN_FILE,
      'Remove unnecessary method declarations in file');
  static const REMOVE_NAME_FROM_COMBINATOR = FixKind(
      'dart.fix.remove.nameFromCombinator',
      DartFixKindPriority.DEFAULT,
      "Remove name from '{0}'");
  static const REMOVE_NON_NULL_ASSERTION = FixKind(
      'dart.fix.remove.nonNullAssertion',
      DartFixKindPriority.DEFAULT,
      "Remove the '!'");
  static const REMOVE_OPERATOR = FixKind('dart.fix.remove.operator',
      DartFixKindPriority.DEFAULT, 'Remove the operator');
  static const REMOVE_OPERATOR_MULTI = FixKind(
      'dart.fix.remove.operator.multi.multi',
      DartFixKindPriority.IN_FILE,
      'Remove operators in file');
  static const REMOVE_PARAMETERS_IN_GETTER_DECLARATION = FixKind(
      'dart.fix.remove.parametersInGetterDeclaration',
      DartFixKindPriority.DEFAULT,
      'Remove parameters in getter declaration');
  static const REMOVE_PARENTHESIS_IN_GETTER_INVOCATION = FixKind(
      'dart.fix.remove.parenthesisInGetterInvocation',
      DartFixKindPriority.DEFAULT,
      'Remove parentheses in getter invocation');
  static const REMOVE_QUESTION_MARK = FixKind('dart.fix.remove.questionMark',
      DartFixKindPriority.DEFAULT, "Remove the '?'");
  static const REMOVE_QUESTION_MARK_MULTI = FixKind(
      'dart.fix.remove.questionMark.multi',
      DartFixKindPriority.IN_FILE,
      'Remove unnecessary question marks in file');
  static const REMOVE_THIS_EXPRESSION = FixKind(
      'dart.fix.remove.thisExpression',
      DartFixKindPriority.DEFAULT,
      'Remove this expression');
  static const REMOVE_THIS_EXPRESSION_MULTI = FixKind(
      'dart.fix.remove.thisExpression.multi',
      DartFixKindPriority.IN_FILE,
      'Remove unnecessary this expressions everywhere in file');
  static const REMOVE_TYPE_ANNOTATION = FixKind(
      'dart.fix.remove.typeAnnotation',
      DartFixKindPriority.DEFAULT,
      'Remove type annotation');
  static const REMOVE_TYPE_ANNOTATION_MULTI = FixKind(
      'dart.fix.remove.typeAnnotation.multi',
      DartFixKindPriority.IN_FILE,
      'Remove unnecessary type annotations in file');
  static const REMOVE_TYPE_ARGUMENTS =
      FixKind('dart.fix.remove.typeArguments', 49, 'Remove type arguments');
  static const REMOVE_UNNECESSARY_CAST = FixKind(
      'dart.fix.remove.unnecessaryCast',
      DartFixKindPriority.DEFAULT,
      'Remove unnecessary cast');
  static const REMOVE_UNNECESSARY_CAST_MULTI = FixKind(
      'dart.fix.remove.unnecessaryCast.multi',
      DartFixKindPriority.IN_FILE,
      'Remove all unnecessary casts in file');
  static const REMOVE_UNNECESSARY_CONST = FixKind(
      'dart.fix.remove.unnecessaryConst',
      DartFixKindPriority.DEFAULT,
      'Remove unnecessary const keyword');
  static const REMOVE_UNNECESSARY_CONST_MULTI = FixKind(
      'dart.fix.remove.unnecessaryConst.multi',
      DartFixKindPriority.IN_FILE,
      'Remove unnecessary const keywords everywhere in file');
  static const REMOVE_UNNECESSARY_NEW = FixKind(
      'dart.fix.remove.unnecessaryNew',
      DartFixKindPriority.DEFAULT,
      'Remove unnecessary new keyword');
  static const REMOVE_UNNECESSARY_NEW_MULTI = FixKind(
      'dart.fix.remove.unnecessaryNew.multi',
      DartFixKindPriority.IN_FILE,
      'Remove unnecessary new keywords everywhere in file');
  static const REMOVE_UNNECESSARY_PARENTHESES = FixKind(
      'dart.fix.remove.unnecessaryParentheses',
      DartFixKindPriority.DEFAULT,
      'Remove unnecessary parentheses');
  static const REMOVE_UNNECESSARY_PARENTHESES_MULTI = FixKind(
      'dart.fix.remove.unnecessaryParentheses.multi',
      DartFixKindPriority.IN_FILE,
      'Remove all unnecessary parentheses in file');
  static const REMOVE_UNNECESSARY_STRING_INTERPOLATION = FixKind(
      'dart.fix.remove.unnecessaryStringInterpolation',
      DartFixKindPriority.DEFAULT,
      'Remove unnecessary string interpolation');
  static const REMOVE_UNNECESSARY_STRING_INTERPOLATION_MULTI = FixKind(
      'dart.fix.remove.unnecessaryStringInterpolation.multi',
      DartFixKindPriority.IN_FILE,
      'Remove all unnecessary string interpolations in file');
  static const REMOVE_UNUSED_CATCH_CLAUSE = FixKind(
      'dart.fix.remove.unusedCatchClause',
      DartFixKindPriority.DEFAULT,
      "Remove unused 'catch' clause");
  static const REMOVE_UNUSED_CATCH_STACK = FixKind(
      'dart.fix.remove.unusedCatchStack',
      DartFixKindPriority.DEFAULT,
      'Remove unused stack trace variable');
  static const REMOVE_UNUSED_ELEMENT = FixKind('dart.fix.remove.unusedElement',
      DartFixKindPriority.DEFAULT, 'Remove unused element');
  static const REMOVE_UNUSED_FIELD = FixKind('dart.fix.remove.unusedField',
      DartFixKindPriority.DEFAULT, 'Remove unused field');
  static const REMOVE_UNUSED_IMPORT = FixKind('dart.fix.remove.unusedImport',
      DartFixKindPriority.DEFAULT, 'Remove unused import');
  static const REMOVE_UNUSED_IMPORT_MULTI = FixKind(
      'dart.fix.remove.unusedImport.multi',
      DartFixKindPriority.IN_FILE,
      'Remove all unused imports in file');
  static const REMOVE_UNUSED_LABEL = FixKind('dart.fix.remove.unusedLabel',
      DartFixKindPriority.DEFAULT, 'Remove unused label');
  static const REMOVE_UNUSED_LOCAL_VARIABLE = FixKind(
      'dart.fix.remove.unusedLocalVariable',
      DartFixKindPriority.DEFAULT,
      'Remove unused local variable');
  static const REMOVE_UNUSED_PARAMETER = FixKind(
      'dart.fix.remove.unusedParameter',
      DartFixKindPriority.DEFAULT,
      'Remove the unused parameter');
  static const REMOVE_UNUSED_PARAMETER_MULTI = FixKind(
      'dart.fix.remove.unusedParameter.multi',
      DartFixKindPriority.IN_FILE,
      'Remove unused parameters everywhere in file');
  static const RENAME_TO_CAMEL_CASE = FixKind('dart.fix.rename.toCamelCase',
      DartFixKindPriority.DEFAULT, "Rename to '{0}'");
  static const RENAME_TO_CAMEL_CASE_MULTI = FixKind(
      'dart.fix.rename.toCamelCase.multi',
      DartFixKindPriority.IN_FILE,
      'Rename to camel case everywhere in file');
  static const REPLACE_BOOLEAN_WITH_BOOL = FixKind(
      'dart.fix.replace.booleanWithBool',
      DartFixKindPriority.DEFAULT,
      "Replace 'boolean' with 'bool'");
  static const REPLACE_BOOLEAN_WITH_BOOL_MULTI = FixKind(
      'dart.fix.replace.booleanWithBool.multi',
      DartFixKindPriority.IN_FILE,
      "Replace all 'boolean's with 'bool' in file");
  static const REPLACE_CASCADE_WITH_DOT = FixKind(
      'dart.fix.replace.cascadeWithDot',
      DartFixKindPriority.DEFAULT,
      "Replace '..' with '.'");
  static const REPLACE_CASCADE_WITH_DOT_MULTI = FixKind(
      'dart.fix.replace.cascadeWithDot.multi',
      DartFixKindPriority.IN_FILE,
      "Replace unnecessary '..'s with '.'s everywhere in file");
  static const REPLACE_COLON_WITH_EQUALS = FixKind(
      'dart.fix.replace.colonWithEquals',
      DartFixKindPriority.DEFAULT,
      "Replace ':' with '='");
  static const REPLACE_COLON_WITH_EQUALS_MULTI = FixKind(
      'dart.fix.replace.colonWithEquals.multi',
      DartFixKindPriority.IN_FILE,
      "Replace ':'s with '='s everywhere in file");
  static const REPLACE_WITH_FILLED = FixKind(
      'dart.fix.replace.finalWithListFilled',
      DartFixKindPriority.DEFAULT,
      "Replace with 'List.filled'");
  static const REPLACE_FINAL_WITH_CONST = FixKind(
      'dart.fix.replace.finalWithConst',
      DartFixKindPriority.DEFAULT,
      "Replace 'final' with 'const'");
  static const REPLACE_FINAL_WITH_CONST_MULTI = FixKind(
      'dart.fix.replace.finalWithConst.multi',
      DartFixKindPriority.IN_FILE,
      "Replace 'final' with 'const' where possible in file");
  static const REPLACE_NEW_WITH_CONST = FixKind('dart.fix.replace.newWithConst',
      DartFixKindPriority.DEFAULT, "Replace 'new' with 'const'");
  static const REPLACE_NEW_WITH_CONST_MULTI = FixKind(
      'dart.fix.replace.newWithConst.multi',
      DartFixKindPriority.IN_FILE,
      "Replace 'new' with 'const' where possible in file");
  static const REPLACE_NULL_WITH_CLOSURE = FixKind(
      'dart.fix.replace.nullWithClosure',
      DartFixKindPriority.DEFAULT,
      "Replace 'null' with a closure");
  static const REPLACE_NULL_WITH_CLOSURE_MULTI = FixKind(
      'dart.fix.replace.nullWithClosure.multi',
      DartFixKindPriority.IN_FILE,
      "Replace 'null's with closures where possible in file");
  static const REPLACE_RETURN_TYPE_FUTURE = FixKind(
      'dart.fix.replace.returnTypeFuture',
      DartFixKindPriority.DEFAULT,
      "Return 'Future' from 'async' function");
  static const REPLACE_VAR_WITH_DYNAMIC = FixKind(
      'dart.fix.replace.varWithDynamic',
      DartFixKindPriority.DEFAULT,
      "Replace 'var' with 'dynamic'");
  static const REPLACE_WITH_EIGHT_DIGIT_HEX = FixKind(
      'dart.fix.replace.withEightDigitHex',
      DartFixKindPriority.DEFAULT,
      "Replace with '{0}'");
  static const REPLACE_WITH_EIGHT_DIGIT_HEX_MULTI = FixKind(
      'dart.fix.replace.withEightDigitHex.multi',
      DartFixKindPriority.IN_FILE,
      'Replace with hex digits everywhere in file');
  static const REPLACE_WITH_BRACKETS = FixKind('dart.fix.replace.withBrackets',
      DartFixKindPriority.DEFAULT, 'Replace with { }');
  static const REPLACE_WITH_BRACKETS_MULTI = FixKind(
      'dart.fix.replace.withBrackets.multi',
      DartFixKindPriority.IN_FILE,
      'Replace with { } everywhere in file');
  static const REPLACE_WITH_CONDITIONAL_ASSIGNMENT = FixKind(
      'dart.fix.replace.withConditionalAssignment',
      DartFixKindPriority.DEFAULT,
      'Replace with ??=');
  static const REPLACE_WITH_CONDITIONAL_ASSIGNMENT_MULTI = FixKind(
      'dart.fix.replace.withConditionalAssignment.multi',
      DartFixKindPriority.IN_FILE,
      'Replace with ??= everywhere in file');
  static const REPLACE_WITH_EXTENSION_NAME = FixKind(
      'dart.fix.replace.withExtensionName',
      DartFixKindPriority.DEFAULT,
      "Replace with '{0}'");
  static const REPLACE_WITH_IDENTIFIER = FixKind(
      'dart.fix.replace.withIdentifier',
      DartFixKindPriority.DEFAULT,
      'Replace with identifier');
  // todo (pq): parameterize message (used by LintNames.avoid_types_on_closure_parameters)
  static const REPLACE_WITH_IDENTIFIER_MULTI = FixKind(
      'dart.fix.replace.withIdentifier.multi',
      DartFixKindPriority.IN_FILE,
      'Replace with identifier everywhere in file');
  static const REPLACE_WITH_INTERPOLATION = FixKind(
      'dart.fix.replace.withInterpolation',
      DartFixKindPriority.DEFAULT,
      'Replace with interpolation');
  static const REPLACE_WITH_INTERPOLATION_MULTI = FixKind(
      'dart.fix.replace.withInterpolation.multi',
      DartFixKindPriority.IN_FILE,
      'Replace with interpolations everywhere in file');
  static const REPLACE_WITH_IS_EMPTY = FixKind('dart.fix.replace.withIsEmpty',
      DartFixKindPriority.DEFAULT, "Replace with 'isEmpty'");
  static const REPLACE_WITH_IS_EMPTY_MULTI = FixKind(
      'dart.fix.replace.withIsEmpty.multi',
      DartFixKindPriority.IN_FILE,
      "Replace with 'isEmpty' everywhere in file");
  static const REPLACE_WITH_IS_NOT_EMPTY = FixKind(
      'dart.fix.replace.withIsNotEmpty',
      DartFixKindPriority.DEFAULT,
      "Replace with 'isNotEmpty'");
  static const REPLACE_WITH_IS_NOT_EMPTY_MULTI = FixKind(
      'dart.fix.replace.withIsNotEmpty.multi',
      DartFixKindPriority.IN_FILE,
      "Replace with 'isNotEmpty' everywhere in file");
  static const REPLACE_WITH_NOT_NULL_AWARE = FixKind(
      'dart.fix.replace.withNotNullAware',
      DartFixKindPriority.DEFAULT,
      "Replace with '{0}'");
  static const REPLACE_WITH_NULL_AWARE = FixKind(
      'dart.fix.replace.withNullAware',
      DartFixKindPriority.DEFAULT,
      "Replace the '.' with a '?.' in the invocation");
  static const REPLACE_WITH_TEAR_OFF = FixKind('dart.fix.replace.withTearOff',
      DartFixKindPriority.DEFAULT, 'Replace function literal with tear-off');
  static const REPLACE_WITH_TEAR_OFF_MULTI = FixKind(
      'dart.fix.replace.withTearOff.multi',
      DartFixKindPriority.IN_FILE,
      'Replace function literals with tear-offs everywhere in file');
  static const REPLACE_WITH_VAR = FixKind('dart.fix.replace.withVar',
      DartFixKindPriority.DEFAULT, "Replace type annotation with 'var'");
  static const REPLACE_WITH_VAR_MULTI = FixKind(
      'dart.fix.replace.withVar.multi',
      DartFixKindPriority.IN_FILE,
      "Replace unnecessary type annotations with 'var' in file");
  static const SORT_CHILD_PROPERTY_LAST = FixKind(
      'dart.fix.sort.childPropertyLast',
      DartFixKindPriority.DEFAULT,
      'Move child property to end of arguments');
  static const SORT_CHILD_PROPERTY_LAST_MULTI = FixKind(
      'dart.fix.sort.childPropertyLast.multi',
      DartFixKindPriority.IN_FILE,
      'Move child properties to ends of arguments everywhere in file');
  static const UPDATE_SDK_CONSTRAINTS = FixKind('dart.fix.updateSdkConstraints',
      DartFixKindPriority.DEFAULT, 'Update the SDK constraints');
  static const USE_CONST = FixKind(
      'dart.fix.use.const', DartFixKindPriority.DEFAULT, 'Change to constant');
  static const USE_EFFECTIVE_INTEGER_DIVISION = FixKind(
      'dart.fix.use.effectiveIntegerDivision',
      DartFixKindPriority.DEFAULT,
      'Use effective integer division ~/');
  static const USE_EQ_EQ_NULL = FixKind('dart.fix.use.eqEqNull',
      DartFixKindPriority.DEFAULT, "Use == null instead of 'is Null'");
  static const USE_EQ_EQ_NULL_MULTI = FixKind(
      'dart.fix.use.eqEqNull.multi',
      DartFixKindPriority.IN_FILE,
      "Use == null instead of 'is Null' everywhere in file");
  static const USE_IS_NOT_EMPTY = FixKind('dart.fix.use.isNotEmpty',
      DartFixKindPriority.DEFAULT, "Use x.isNotEmpty instead of '!x.isEmpty'");
  static const USE_IS_NOT_EMPTY_MULTI = FixKind(
      'dart.fix.use.isNotEmpty.multi',
      DartFixKindPriority.IN_FILE,
      "Use x.isNotEmpty instead of '!x.isEmpty' everywhere in file");
  static const USE_NOT_EQ_NULL = FixKind('dart.fix.use.notEqNull',
      DartFixKindPriority.DEFAULT, "Use != null instead of 'is! Null'");
  static const USE_NOT_EQ_NULL_MULTI = FixKind(
      'dart.fix.use.notEqNull.multi',
      DartFixKindPriority.IN_FILE,
      "Use != null instead of 'is! Null' everywhere in file");
  static const USE_RETHROW = FixKind('dart.fix.use.rethrow',
      DartFixKindPriority.DEFAULT, 'Replace throw with rethrow');
  static const USE_RETHROW_MULTI = FixKind(
      'dart.fix.use.rethrow.multi',
      DartFixKindPriority.IN_FILE,
      'Replace throw with rethrow where possible in file');
  static const WRAP_IN_FUTURE = FixKind('dart.fix.wrap.future',
      DartFixKindPriority.DEFAULT, "Wrap in 'Future.value'");
  static const WRAP_IN_TEXT = FixKind('dart.fix.flutter.wrap.text',
      DartFixKindPriority.DEFAULT, "Wrap in a 'Text' widget");
}

class DartFixKindPriority {
  static const int DEFAULT = 50;
  static const int IN_FILE = 40;
}

/// An enumeration of quick fix kinds for the errors found in an Android
/// manifest file.
class ManifestFixKind {}

/// An enumeration of quick fix kinds for the errors found in a pubspec file.
class PubspecFixKind {}
