// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:math' as math;

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/correction/base_processor.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/add_async.dart';
import 'package:analysis_server/src/services/correction/dart/add_await.dart';
import 'package:analysis_server/src/services/correction/dart/add_const.dart';
import 'package:analysis_server/src/services/correction/dart/add_diagnostic_property_reference.dart';
import 'package:analysis_server/src/services/correction/dart/add_explicit_cast.dart';
import 'package:analysis_server/src/services/correction/dart/add_field_formal_parameters.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_enum_case_clauses.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_required_argument.dart';
import 'package:analysis_server/src/services/correction/dart/add_override.dart';
import 'package:analysis_server/src/services/correction/dart/add_required.dart';
import 'package:analysis_server/src/services/correction/dart/add_required_keyword.dart';
import 'package:analysis_server/src/services/correction/dart/add_return_type.dart';
import 'package:analysis_server/src/services/correction/dart/add_static.dart';
import 'package:analysis_server/src/services/correction/dart/add_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/change_argument_name.dart';
import 'package:analysis_server/src/services/correction/dart/change_to_nearest_precise_value.dart';
import 'package:analysis_server/src/services/correction/dart/change_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/convert_add_all_to_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_conditional_expression_to_if_element.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_line.dart';
import 'package:analysis_server/src/services/correction/dart/convert_flutter_child.dart';
import 'package:analysis_server/src/services/correction/dart/convert_flutter_children.dart';
import 'package:analysis_server/src/services/correction/dart/convert_map_from_iterable_to_for_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_quotes.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_contains.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_expression_function_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_generic_function_syntax.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_if_null.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_int_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_list_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_named_arguments.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_on_type.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_package_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_relative_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_set_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_where_type.dart';
import 'package:analysis_server/src/services/correction/dart/inline_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/inline_typedef.dart';
import 'package:analysis_server/src/services/correction/dart/remove_dead_if_null.dart';
import 'package:analysis_server/src/services/correction/dart/remove_if_null_operator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_question_mark.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/replace_boolean_with_bool.dart';
import 'package:analysis_server/src/services/correction/dart/replace_new_with_const.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_eight_digit_hex.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_interpolation.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/sort_child_property_last.dart';
import 'package:analysis_server/src/services/correction/dart/use_curly_braces.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_future.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_text.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/levenshtein.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/correction/organize_directives.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/inheritance_override.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError, Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart' hide FixContributor;
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart';

/// A predicate is a one-argument function that returns a boolean value.
typedef ElementPredicate = bool Function(Element argument);

/// A function that can be executed to create a multi-correction producer.
typedef MultiProducerGenerator = MultiCorrectionProducer Function();

/// A function that can be executed to create a correction producer.
typedef ProducerGenerator = CorrectionProducer Function();

/// A fix contributor that provides the default set of fixes for Dart files.
class DartFixContributor implements FixContributor {
  @override
  Future<List<Fix>> computeFixes(DartFixContext context) async {
    try {
      var processor = FixProcessor(context);
      var fixes = await processor.compute();
      var fixAllFixes = await _computeFixAllFixes(context, fixes);
      return List.from(fixes)..addAll(fixAllFixes);
    } on CancelCorrectionException {
      return const <Fix>[];
    }
  }

  Future<List<Fix>> _computeFixAllFixes(
      DartFixContext context, List<Fix> fixes) async {
    final analysisError = context.error;
    final allAnalysisErrors = context.resolveResult.errors.toList();

    // Validate inputs:
    // - return if no fixes
    // - return if no other analysis errors
    if (fixes.isEmpty || allAnalysisErrors.length < 2) {
      return const <Fix>[];
    }

    // Remove any analysis errors that don't have the expected error code name
    allAnalysisErrors
        .removeWhere((e) => analysisError.errorCode.name != e.errorCode.name);
    if (allAnalysisErrors.length < 2) {
      return const <Fix>[];
    }

    // A map between each FixKind and the List of associated fixes
    var map = <FixKind, List<Fix>>{};

    // Populate the HashMap by looping through all AnalysisErrors, creating a
    // new FixProcessor to compute the other fixes that can be applied with this
    // one.
    // For each fix, put the fix into the HashMap.
    for (var i = 0; i < allAnalysisErrors.length; i++) {
      final FixContext fixContextI = DartFixContextImpl(
        context.workspace,
        context.resolveResult,
        allAnalysisErrors[i],
        (name) => [],
      );
      var processorI = FixProcessor(fixContextI);
      var fixesListI = await processorI.compute();
      for (var f in fixesListI) {
        if (!map.containsKey(f.kind)) {
          map[f.kind] = <Fix>[]..add(f);
        } else {
          map[f.kind].add(f);
        }
      }
    }

    // For each FixKind in the HashMap, union each list together, then return
    // the set of unioned Fixes.
    var result = <Fix>[];
    map.forEach((FixKind kind, List<Fix> fixesListJ) {
      if (fixesListJ.first.kind.canBeAppliedTogether()) {
        var unionFix = _unionFixList(fixesListJ);
        if (unionFix != null) {
          result.add(unionFix);
        }
      }
    });
    return result;
  }

  Fix _unionFixList(List<Fix> fixList) {
    if (fixList == null || fixList.isEmpty) {
      return null;
    } else if (fixList.length == 1) {
      return fixList[0];
    }
    var sourceChange = SourceChange(fixList[0].kind.appliedTogetherMessage);
    sourceChange.edits = List.from(fixList[0].change.edits);
    var edits = <SourceEdit>[];
    edits.addAll(fixList[0].change.edits[0].edits);
    sourceChange.linkedEditGroups =
        List.from(fixList[0].change.linkedEditGroups);
    for (var i = 1; i < fixList.length; i++) {
      edits.addAll(fixList[i].change.edits[0].edits);
      sourceChange.linkedEditGroups..addAll(fixList[i].change.linkedEditGroups);
    }
    // Sort the list of SourceEdits so that when the edits are applied, they
    // are applied from the end of the file to the top of the file.
    edits.sort((s1, s2) => s2.offset - s1.offset);

    sourceChange.edits[0].edits = edits;

    return Fix(fixList[0].kind, sourceChange);
  }
}

/// The computer for Dart fixes.
class FixProcessor extends BaseProcessor {
  static const int MAX_LEVENSHTEIN_DISTANCE = 3;

  /// A map from the names of lint rules to a list of generators used to create
  /// the correction producers used to build fixes for those diagnostics. The
  /// generators used for non-lint diagnostics are in the [nonLintProducerMap].
  static const Map<String, List<ProducerGenerator>> lintProducerMap = {
    LintNames.always_declare_return_types: [
      AddReturnType.newInstance,
    ],
    LintNames.always_require_non_null_named_parameters: [
      AddRequired.newInstance,
    ],
    LintNames.always_specify_types: [
      AddTypeAnnotation.newInstance,
    ],
    LintNames.annotate_overrides: [
      AddOverride.newInstance,
    ],
//    LintNames.avoid_annotating_with_dynamic : [],
//    LintNames.avoid_empty_else : [],
//    LintNames.avoid_init_to_null : [],
    LintNames.avoid_private_typedef_functions: [
      InlineTypedef.newInstance,
    ],
//    LintNames.avoid_redundant_argument_values : [],
    LintNames.avoid_relative_lib_imports: [
      ConvertToPackageImport.newInstance,
    ],
//    LintNames.avoid_return_types_on_setters : [],
    LintNames.avoid_returning_null_for_future: [
      AddSync.newInstance,
      WrapInFuture.newInstance,
    ],
    LintNames.avoid_types_as_parameter_names: [
      ConvertToOnType.newInstance,
    ],
//    LintNames.avoid_types_on_closure_parameters : [],
//    LintNames.await_only_futures : [],
    LintNames.curly_braces_in_flow_control_structures: [
      UseCurlyBraces.newInstance,
    ],
    LintNames.diagnostic_describe_all_properties: [
      AddDiagnosticPropertyReference.newInstance,
    ],
//    LintNames.directives_ordering : [],
//    LintNames.empty_catches : [],
//    LintNames.empty_constructor_bodies : [],
//    LintNames.empty_statements : [],
//    LintNames.hash_and_equals : [],
//    LintNames.no_duplicate_case_values : [],
//    LintNames.non_constant_identifier_names : [],
//    LintNames.null_closures : [],
    LintNames.omit_local_variable_types: [
      ReplaceWithVar.newInstance,
    ],
//    LintNames.prefer_adjacent_string_concatenation : [],
    LintNames.prefer_collection_literals: [
      ConvertToListLiteral.newInstance,
      ConvertToMapLiteral.newInstance,
      ConvertToSetLiteral.newInstance,
    ],
//    LintNames.prefer_conditional_assignment : [],
    LintNames.prefer_const_constructors: [
      AddConst.newInstance,
      ReplaceNewWithConst.newInstance,
    ],
    LintNames.prefer_const_constructors_in_immutables: [
      AddConst.newInstance,
    ],
//    LintNames.prefer_const_declarations : [],
    LintNames.prefer_contains: [
      ConvertToContains.newInstance,
    ],
//    LintNames.prefer_equal_for_default_values : [],
    LintNames.prefer_expression_function_bodies: [
      ConvertToExpressionFunctionBody.newInstance,
    ],
//    LintNames.prefer_final_fields : [],
//    LintNames.prefer_final_locals : [],
    LintNames.prefer_for_elements_to_map_fromIterable: [
      ConvertMapFromIterableToForLiteral.newInstance,
    ],
    LintNames.prefer_generic_function_type_aliases: [
      ConvertToGenericFunctionSyntax.newInstance,
    ],
    LintNames.prefer_if_elements_to_conditional_expressions: [
      ConvertConditionalExpressionToIfElement.newInstance,
    ],
//    LintNames.prefer_is_empty : [],
//    LintNames.prefer_is_not_empty : [],
    LintNames.prefer_if_null_operators: [
      ConvertToIfNull.newInstance,
    ],
    LintNames.prefer_inlined_adds: [
      InlineInvocation.newInstance,
    ],
    LintNames.prefer_int_literals: [
      ConvertToIntLiteral.newInstance,
    ],
    LintNames.prefer_interpolation_to_compose_strings: [
      ReplaceWithInterpolation.newInstance,
    ],
    LintNames.prefer_iterable_whereType: [
      ConvertToWhereType.newInstance,
    ],
    LintNames.prefer_null_aware_operators: [
      ConvertToNullAware.newInstance,
    ],
    LintNames.prefer_relative_imports: [
      ConvertToRelativeImport.newInstance,
    ],
    LintNames.prefer_single_quotes: [
      ConvertToSingleQuotes.newInstance,
    ],
    LintNames.prefer_spread_collections: [
      ConvertAddAllToSpread.newInstance,
    ],
    LintNames.slash_for_doc_comments: [
      ConvertDocumentationIntoLine.newInstance,
    ],
    LintNames.sort_child_properties_last: [
      SortChildPropertyLast.newInstance,
    ],
    LintNames.type_annotate_public_apis: [
      AddTypeAnnotation.newInstance,
    ],
//    LintNames.type_init_formals : [],
    LintNames.unawaited_futures: [
      AddAwait.newInstance,
    ],
//    LintNames.unnecessary_brace_in_string_interps : [],
//    LintNames.unnecessary_const : [],
//    LintNames.unnecessary_lambdas : [],
//    LintNames.unnecessary_new : [],
    LintNames.unnecessary_null_in_if_null_operators: [
      RemoveIfNullOperator.newInstance,
    ],
//    LintNames.unnecessary_overrides : [],
//    LintNames.unnecessary_this : [],
    LintNames.use_full_hex_values_for_flutter_colors: [
      ReplaceWithEightDigitHex.newInstance,
    ],
    LintNames.use_function_type_syntax_for_parameters: [
      ConvertToGenericFunctionSyntax.newInstance,
    ],
//    LintNames.use_rethrow_when_possible : [],
  };

  /// A map from error codes to a list of generators used to create multiple
  /// correction producers used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintMultiProducerMap].
  static const Map<ErrorCode, List<MultiProducerGenerator>>
      nonLintMultiProducerMap = {
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      ChangeArgumentName.newInstance
    ],
  };

  /// A map from error codes to a list of generators used to create the
  /// correction producers used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintProducerMap].
  static const Map<ErrorCode, List<ProducerGenerator>> nonLintProducerMap = {
    CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT: [
      AddSync.newInstance,
    ],
    CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT: [
      AddSync.newInstance,
    ],
//    CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE : [],
    CompileTimeErrorCode.CONST_INSTANCE_FIELD: [
      AddStatic.newInstance,
    ],
//    CompileTimeErrorCode.CONST_WITH_NON_CONST : [],
//    CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER : [],
//    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS : [],
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
      ConvertToNamedArguments.newInstance,
    ],
//    CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD : [],
    CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE: [
      ChangeToNearestPreciseValue.newInstance,
    ],
//    CompileTimeErrorCode.INVALID_ANNOTATION : [],
    CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER: [
      AddRequiredKeyword.newInstance,
    ],
//    CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE : [],
//    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT : [],
//    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT : [],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE: [
      RemoveQuestionMark.newInstance,
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE: [
      RemoveQuestionMark.newInstance,
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE: [
      RemoveQuestionMark.newInstance,
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE: [
      RemoveQuestionMark.newInstance,
    ],
//    CompileTimeErrorCode.UNDEFINED_ANNOTATION : [],
//    CompileTimeErrorCode.UNDEFINED_CLASS : [],
//    CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT : [],
//    CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER : [],
//    CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD : [],
//    CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER : [],
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      ConvertFlutterChild.newInstance,
      ConvertFlutterChildren.newInstance,
    ],
//    CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE : [],
//    CompileTimeErrorCode.URI_DOES_NOT_EXIST : [],

    HintCode.CAN_BE_NULL_AFTER_NULL_AWARE: [
      ReplaceWithNullAware.newInstance,
    ],
//    HintCode.DEAD_CODE : [],
//    HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH : [],
//    HintCode.DEAD_CODE_ON_CATCH_SUBTYPE : [],
//    HintCode.DIVISION_OPTIMIZATION : [],
//    HintCode.DUPLICATE_HIDDEN_NAME : [],
//    HintCode.DUPLICATE_IMPORT : [],
//    HintCode.DUPLICATE_SHOWN_NAME : [],
//    HintCode.INVALID_FACTORY_ANNOTATION : [],
//    HintCode.INVALID_IMMUTABLE_ANNOTATION : [],
//    HintCode.INVALID_LITERAL_ANNOTATION : [],
//    HintCode.INVALID_REQUIRED_NAMED_PARAM : [],
//    HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM : [],
//    HintCode.INVALID_REQUIRED_POSITIONAL_PARAM : [],
//    HintCode.INVALID_SEALED_ANNOTATION : [],
    HintCode.MISSING_REQUIRED_PARAM: [
      AddMissingRequiredArgument.newInstance,
    ],
    HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS: [
      AddMissingRequiredArgument.newInstance,
    ],
    HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE: [
      RemoveQuestionMark.newInstance,
    ],
//    HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD : [],
//    HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER : [],
//    HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD : [],
//    HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER : [],
//    HintCode.SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT : [],
//    HintCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE : [],
//    HintCode.SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT : [],
//    HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT : [],
//    HintCode.SDK_VERSION_EXTENSION_METHODS : [],
//    HintCode.SDK_VERSION_GT_GT_GT_OPERATOR : [],
//    HintCode.SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT : [],
//    HintCode.SDK_VERSION_SET_LITERAL : [],
//    HintCode.SDK_VERSION_UI_AS_CODE : [],
//    HintCode.TYPE_CHECK_IS_NOT_NULL : [],
//    HintCode.TYPE_CHECK_IS_NULL : [],
//    HintCode.UNDEFINED_HIDDEN_NAME : [],
//    HintCode.UNDEFINED_SHOWN_NAME : [],
//    HintCode.UNNECESSARY_CAST : [],
//    HintCode.UNUSED_CATCH_CLAUSE : [],
//    HintCode.UNUSED_CATCH_STACK : [],
    HintCode.UNUSED_ELEMENT: [
      RemoveUnusedElement.newInstance,
    ],
    HintCode.UNUSED_FIELD: [
      RemoveUnusedField.newInstance,
    ],
//    HintCode.UNUSED_IMPORT : [],
//    HintCode.UNUSED_LABEL : [],
    HintCode.UNUSED_LOCAL_VARIABLE: [
      RemoveUnusedLocalVariable.newInstance,
    ],
//    HintCode.UNUSED_SHOWN_NAME : [],

//    ParserErrorCode.EXPECTED_TOKEN : [],
//    ParserErrorCode.GETTER_WITH_PARAMETERS : [],
    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE: [
      AddTypeAnnotation.newInstance,
    ],
//    ParserErrorCode.VAR_AS_TYPE_NAME : [],

//    StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE : [],
//    StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER : [],
    StaticTypeWarningCode.INVALID_ASSIGNMENT: [
      AddExplicitCast.newInstance,
      ChangeTypeAnnotation.newInstance,
    ],
//    StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION : [],
//    StaticTypeWarningCode.NON_BOOL_CONDITION : [],
//    StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT : [],
//    StaticTypeWarningCode.UNDEFINED_FUNCTION : [],
//    StaticTypeWarningCode.UNDEFINED_GETTER : [],
//    StaticTypeWarningCode.UNDEFINED_METHOD : [],
//    StaticTypeWarningCode.UNDEFINED_SETTER : [],
//    StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR : [],
//    StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER : [],

//    StaticWarningCode.ASSIGNMENT_TO_FINAL : [],
//    StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL : [],
    StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE: [
      WrapInText.newInstance,
    ],
//    StaticWarningCode.CAST_TO_NON_TYPE : [],
//    StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER : [],
    StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION: [
      RemoveDeadIfNull.newInstance,
    ],
//    StaticWarningCode.FINAL_NOT_INITIALIZED : [],
    StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1: [
      AddFieldFormalParameters.newInstance,
    ],
    StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2: [
      AddFieldFormalParameters.newInstance,
    ],
    StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS: [
      AddFieldFormalParameters.newInstance,
    ],
    StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH: [
      AddMissingEnumCaseClauses.newInstance,
    ],
//    StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR : [],
//    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS : [],
//    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR : [],
//    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE : [],
//    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE : [],
//    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO : [],
//    StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE : [],
//    StaticWarningCode.NOT_A_TYPE : [],
//    StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME : [],
    StaticWarningCode.UNDEFINED_CLASS_BOOLEAN: [
      ReplaceBooleanWithBool.newInstance
    ],
//    StaticWarningCode.UNDEFINED_IDENTIFIER : [],
    StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT: [
      AddSync.newInstance,
    ],
  };

  final DartFixContext context;

  final ResourceProvider resourceProvider;
  final TypeSystem typeSystem;

  final LibraryElement unitLibraryElement;
  final CompilationUnit unit;
  final AnalysisError error;

  final int errorOffset;

  final int errorLength;

  final List<Fix> fixes = <Fix>[];

  AstNode coveredNode;

  FixProcessor(this.context)
      : resourceProvider = context.resolveResult.session.resourceProvider,
        typeSystem = context.resolveResult.typeSystem,
        unitLibraryElement = context.resolveResult.libraryElement,
        unit = context.resolveResult.unit,
        error = context.error,
        errorOffset = context.error.offset,
        errorLength = context.error.length,
        super(
          resolvedResult: context.resolveResult,
          workspace: context.workspace,
        );

  DartType get coreTypeBool => context.resolveResult.typeProvider.boolType;

  FeatureSet get _featureSet {
    return unit.featureSet;
  }

  bool get _isNonNullable => _featureSet.isEnabled(Feature.non_nullable);

  Future<List<Fix>> compute() async {
    node = NodeLocator2(errorOffset).searchWithin(unit);
    coveredNode =
        NodeLocator2(errorOffset, math.max(errorOffset + errorLength - 1, 0))
            .searchWithin(unit);
    if (coveredNode == null) {
      // TODO(brianwilkerson) Figure out why the coveredNode is sometimes null.
      return fixes;
    }

    // analyze ErrorCode
    var errorCode = error.errorCode;
    if (errorCode ==
        CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE) {
      await _addFix_replaceWithConstInstanceCreation();
    }
    if (errorCode == CompileTimeErrorCode.INVALID_ANNOTATION ||
        errorCode == CompileTimeErrorCode.UNDEFINED_ANNOTATION) {
      if (node is Annotation) {
        Annotation annotation = node;
        var name = annotation.name;
        if (name != null && name.staticElement == null) {
          node = name;
          if (annotation.arguments == null) {
            await _addFix_importLibrary_withTopLevelVariable();
          } else {
            await _addFix_importLibrary_withType();
            await _addFix_createClass();
            await _addFix_undefinedClass_useSimilar();
          }
        }
      }
    }
    if (errorCode ==
        CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT) {
      await _addFix_createConstructorSuperExplicit();
    }
    if (errorCode ==
        CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT) {
      await _addFix_createConstructorSuperImplicit();
      // TODO(brianwilkerson) The following was added because fasta produces
      // NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT in places where analyzer produced
      // NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT
      await _addFix_createConstructorSuperExplicit();
    }
    if (errorCode ==
        CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT) {
      await _addFix_createConstructorSuperExplicit();
    }
    if (errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST) {
      await _addFix_createImportUri();
      await _addFix_createPartUri();
    }
    if (errorCode == HintCode.DEAD_CODE) {
      await _addFix_removeDeadCode();
    }
    if (errorCode == HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH ||
        errorCode == HintCode.DEAD_CODE_ON_CATCH_SUBTYPE) {
      await _addFix_removeDeadCode();
      // TODO(brianwilkerson) Add a fix to move the unreachable catch clause to
      //  a place where it can be reached (when possible).
    }
    // TODO(brianwilkerson) Define a syntax for deprecated members to indicate
    //  how to update the code and implement a fix to apply the update.
//    if (errorCode == HintCode.DEPRECATED_MEMBER_USE ||
//        errorCode == HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE) {
//      await _addFix_replaceDeprecatedMemberUse();
//    }
    if (errorCode == HintCode.DIVISION_OPTIMIZATION) {
      await _addFix_useEffectiveIntegerDivision();
    }
    if (errorCode == HintCode.DUPLICATE_IMPORT) {
      await _addFix_removeUnusedImport();
    }
    if (errorCode == HintCode.DUPLICATE_HIDDEN_NAME ||
        errorCode == HintCode.DUPLICATE_SHOWN_NAME) {
      await _addFix_removeNameFromCombinator();
    }
    // TODO(brianwilkerson) Add a fix to convert the path to a package: import.
//    if (errorCode == HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE) {
//      await _addFix_convertPathToPackageUri();
//    }
    if (errorCode == HintCode.INVALID_FACTORY_ANNOTATION ||
        errorCode == HintCode.INVALID_IMMUTABLE_ANNOTATION ||
        errorCode == HintCode.INVALID_LITERAL_ANNOTATION ||
        errorCode == HintCode.INVALID_REQUIRED_NAMED_PARAM ||
        errorCode == HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM ||
        errorCode == HintCode.INVALID_REQUIRED_POSITIONAL_PARAM ||
        errorCode == HintCode.INVALID_SEALED_ANNOTATION) {
      await _addFix_removeAnnotation();
    }
    if (errorCode == HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER ||
        errorCode == HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD ||
        errorCode == HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD ||
        errorCode == HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER) {
      await _addFix_removeAnnotation();
    }
    // TODO(brianwilkerson) Add a fix to normalize the path.
//    if (errorCode == HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT) {
//      await _addFix_normalizeUri();
//    }
    if (errorCode == HintCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE) {
      await _addFix_importAsync();
      await _addFix_updateSdkConstraints('2.1.0');
    }
    if (errorCode == HintCode.SDK_VERSION_SET_LITERAL) {
      await _addFix_updateSdkConstraints('2.2.0');
    }
    if (errorCode == HintCode.SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT ||
        errorCode == HintCode.SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT ||
        errorCode == HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT ||
        errorCode == HintCode.SDK_VERSION_GT_GT_GT_OPERATOR ||
        errorCode == HintCode.SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT ||
        errorCode == HintCode.SDK_VERSION_UI_AS_CODE) {
      await _addFix_updateSdkConstraints('2.2.2');
    }
    if (errorCode == HintCode.SDK_VERSION_EXTENSION_METHODS) {
      await _addFix_updateSdkConstraints('2.6.0');
    }
    if (errorCode == HintCode.TYPE_CHECK_IS_NOT_NULL) {
      await _addFix_isNotNull();
    }
    if (errorCode == HintCode.TYPE_CHECK_IS_NULL) {
      await _addFix_isNull();
    }
    if (errorCode == HintCode.UNDEFINED_HIDDEN_NAME ||
        errorCode == HintCode.UNDEFINED_SHOWN_NAME) {
      await _addFix_removeNameFromCombinator();
    }
    if (errorCode == HintCode.UNNECESSARY_CAST) {
      await _addFix_removeUnnecessaryCast();
    }
    // TODO(brianwilkerson) Add a fix to remove the method.
//    if (errorCode == HintCode.UNNECESSARY_NO_SUCH_METHOD) {
//      await _addFix_removeMethodDeclaration();
//    }
    // TODO(brianwilkerson) Add a fix to remove the type check.
//    if (errorCode == HintCode.UNNECESSARY_TYPE_CHECK_FALSE ||
//        errorCode == HintCode.UNNECESSARY_TYPE_CHECK_TRUE) {
//      await _addFix_removeUnnecessaryTypeCheck();
//    }
    if (errorCode == HintCode.UNUSED_CATCH_CLAUSE) {
      await _addFix_removeUnusedCatchClause();
    }
    if (errorCode == HintCode.UNUSED_CATCH_STACK) {
      await _addFix_removeUnusedCatchStack();
    }
    if (errorCode == HintCode.UNUSED_IMPORT) {
      await _addFix_removeUnusedImport();
    }
    if (errorCode == HintCode.UNUSED_LABEL) {
      await _addFix_removeUnusedLabel();
    }
    if (errorCode == HintCode.UNUSED_SHOWN_NAME) {
      await _addFix_removeNameFromCombinator();
    }
    if (errorCode == ParserErrorCode.EXPECTED_TOKEN) {
      await _addFix_insertSemicolon();
    }
    if (errorCode == ParserErrorCode.GETTER_WITH_PARAMETERS) {
      await _addFix_removeParameters_inGetterDeclaration();
    }
    if (errorCode == ParserErrorCode.VAR_AS_TYPE_NAME) {
      await _addFix_replaceVarWithDynamic();
    }
    if (errorCode == StaticWarningCode.ASSIGNMENT_TO_FINAL) {
      await _addFix_makeFieldNotFinal();
    }
    if (errorCode == StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL) {
      await _addFix_makeVariableNotFinal();
    }
    if (errorCode == StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER) {
      await _addFix_makeEnclosingClassAbstract();
    }
    if (errorCode == CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS ||
        errorCode ==
            CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED) {
      await _addFix_createConstructor_insteadOfSyntheticDefault();
      await _addFix_addMissingParameter();
    }
    if (errorCode == StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR) {
      await _addFix_createConstructor_named();
    }
    if (errorCode == StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER ||
        errorCode ==
            StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE ||
        errorCode ==
            StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO ||
        errorCode ==
            StaticWarningCode
                .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE ||
        errorCode ==
            StaticWarningCode
                .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR ||
        errorCode ==
            StaticWarningCode
                .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS) {
      // make class abstract
      await _addFix_makeEnclosingClassAbstract();
      await _addFix_createNoSuchMethod();
      // implement methods
      await _addFix_createMissingOverrides();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_CLASS ||
        errorCode == StaticWarningCode.CAST_TO_NON_TYPE ||
        errorCode == StaticWarningCode.NOT_A_TYPE ||
        errorCode == StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME) {
      await _addFix_importLibrary_withType();
      await _addFix_createClass();
      await _addFix_createMixin();
      await _addFix_undefinedClass_useSimilar();
    }
    if (errorCode == StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE) {
      await _addFix_importLibrary_withType();
    }
    if (errorCode == StaticWarningCode.FINAL_NOT_INITIALIZED) {
      await _addFix_createConstructor_forUninitializedFinalFields();
    }
    if (errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createClass();
      await _addFix_createField();
      await _addFix_createGetter();
      await _addFix_createFunction_forFunctionType();
      await _addFix_createMixin();
      await _addFix_createSetter();
      await _addFix_importLibrary_withType();
      await _addFix_importLibrary_withExtension();
      await _addFix_importLibrary_withFunction();
      await _addFix_importLibrary_withTopLevelVariable();
      await _addFix_createLocalVariable();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER) {
      await _addFix_addMissingParameterNamed();
    }
    if (errorCode == StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE) {
      await _addFix_illegalAsyncReturnType();
    }
    if (errorCode == StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER) {
      await _addFix_useStaticAccess_method();
      await _addFix_useStaticAccess_property();
    }
    if (errorCode ==
        StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION) {
      await _addFix_removeParentheses_inGetterInvocation();
    }
    if (errorCode == StaticTypeWarningCode.NON_BOOL_CONDITION) {
      await _addFix_nonBoolCondition_addNotNull();
    }
    if (errorCode == StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT) {
      await _addFix_importLibrary_withType();
      await _addFix_createClass();
      await _addFix_createMixin();
    }
    if (errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST) {
      await _addFix_removeConstKeyword(DartFixKind.REMOVE_CONST);
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_FUNCTION) {
      await _addFix_createClass();
      await _addFix_importLibrary_withExtension();
      await _addFix_importLibrary_withFunction();
      await _addFix_importLibrary_withType();
      await _addFix_undefinedFunction_useSimilar();
      await _addFix_undefinedFunction_create();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_GETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createField();
      await _addFix_createGetter();
      await _addFix_createFunction_forFunctionType();
      // TODO(brianwilkerson) The following were added because fasta produces
      // UNDEFINED_GETTER in places where analyzer produced UNDEFINED_IDENTIFIER
      await _addFix_createClass();
      await _addFix_createMixin();
      await _addFix_createLocalVariable();
      await _addFix_importLibrary_withTopLevelVariable();
      await _addFix_importLibrary_withType();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createGetter();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_METHOD) {
      await _addFix_createClass();
      await _addFix_importLibrary_withFunction();
      await _addFix_importLibrary_withType();
      await _addFix_undefinedMethod_useSimilar();
      await _addFix_createMethod();
      await _addFix_undefinedFunction_create();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD) {
      await _addFix_undefinedMethod_useSimilar();
      await _addFix_createMethod();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_SETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createField();
      await _addFix_createSetter();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createSetter();
    }
    if (errorCode ==
        CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD) {
      await _addFix_createField_initializingFormal();
    }
    if (errorCode ==
        StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR) {
      await _addFix_moveTypeArgumentsToClass();
      await _addFix_removeTypeArguments();
    }
    if (errorCode ==
        CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE) {
      await _addFix_extendClassForMixin();
    }
    if (errorCode ==
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER) {
      await _addFix_replaceWithExtensionName();
    }
    if (errorCode ==
        CompileTimeErrorCode
            .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE) {
      await _addFix_qualifyReference();
      // TODO(brianwilkerson) Consider adding fixes to create a field, getter,
      //  method or setter. The existing _addFix methods would need to be
      //  updated so that only the appropriate subset is generated.
    }
    if (errorCode ==
        StaticTypeWarningCode
            .UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER) {
      await _addFix_qualifyReference();
      // TODO(brianwilkerson) Consider adding fixes to create a field, getter,
      //  method or setter. The existing _addFix methods would need to be
      //  updated so that only the appropriate subset is generated.
    }
    // lints
    if (errorCode is LintCode) {
      var name = errorCode.name;
      if (name == LintNames.avoid_annotating_with_dynamic) {
        await _addFix_removeTypeAnnotation();
      }
      if (name == LintNames.avoid_empty_else) {
        await _addFix_removeEmptyElse();
      }
      if (name == LintNames.avoid_init_to_null) {
        await _addFix_removeInitializer();
      }
      if (name == LintNames.avoid_redundant_argument_values) {
        await _addFix_removeArgument();
      }
      if (name == LintNames.avoid_return_types_on_setters) {
        await _addFix_removeTypeAnnotation();
      }
      if (name == LintNames.avoid_types_on_closure_parameters) {
        await _addFix_replaceWithIdentifier();
      }
      if (name == LintNames.await_only_futures) {
        await _addFix_removeAwait();
      }
      if (name == LintNames.directives_ordering) {
        await _addFix_sortDirectives();
      }
      if (name == LintNames.empty_catches) {
        await _addFix_removeEmptyCatch();
      }
      if (name == LintNames.empty_constructor_bodies) {
        await _addFix_removeEmptyConstructorBody();
      }
      if (name == LintNames.empty_statements) {
        await _addFix_removeEmptyStatement();
      }
      if (name == LintNames.hash_and_equals) {
        await _addFix_addMissingHashOrEquals();
      }
      if (name == LintNames.no_duplicate_case_values) {
        await _addFix_removeCaseStatement();
      }
      if (name == LintNames.non_constant_identifier_names) {
        await _addFix_renameToCamelCase();
      }
      if (name == LintNames.null_closures) {
        await _addFix_replaceNullWithClosure();
      }
      if (name == LintNames.prefer_adjacent_string_concatenation) {
        await _addFix_removeOperator();
      }
      if (name == LintNames.prefer_conditional_assignment) {
        await _addFix_replaceWithConditionalAssignment();
      }
      if (errorCode.name == LintNames.prefer_const_declarations) {
        await _addFix_replaceFinalWithConst();
      }
      if (errorCode.name == LintNames.prefer_equal_for_default_values) {
        await _addFix_replaceColonWithEquals();
      }
      if (name == LintNames.prefer_final_fields) {
        await _addFix_makeVariableFinal();
      }
      if (name == LintNames.prefer_final_locals) {
        await _addFix_makeVariableFinal();
      }
      if (name == LintNames.prefer_is_empty) {
        await _addFix_replaceWithIsEmpty();
      }
      if (name == LintNames.prefer_is_not_empty) {
        await _addFix_isNotEmpty();
      }
      if (name == LintNames.type_init_formals) {
        await _addFix_removeTypeAnnotation();
      }
      if (name == LintNames.unnecessary_brace_in_string_interps) {
        await _addFix_removeInterpolationBraces();
      }
      if (name == LintNames.unnecessary_const) {
        await _addFix_removeConstKeyword(DartFixKind.REMOVE_UNNECESSARY_CONST);
      }
      if (name == LintNames.unnecessary_lambdas) {
        await _addFix_replaceWithTearOff();
      }
      if (name == LintNames.unnecessary_new) {
        await _addFix_removeNewKeyword();
      }
      if (name == LintNames.unnecessary_overrides) {
        await _addFix_removeMethodDeclaration();
      }
      if (name == LintNames.unnecessary_this) {
        await _addFix_removeThisExpression();
      }
      if (name == LintNames.use_rethrow_when_possible) {
        await _addFix_replaceWithRethrow();
      }
    }

    await _addFromProducers();

    // done
    return fixes;
  }

  Future<Fix> computeFix() async {
    var fixes = await compute();
    fixes.sort(Fix.SORT_BY_RELEVANCE);
    return fixes.isNotEmpty ? fixes.first : null;
  }

  Future<void> _addFix_addMissingHashOrEquals() async {
    final methodDecl = node.thisOrAncestorOfType<MethodDeclaration>();
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (methodDecl != null && classDecl != null) {
      final classElement = classDecl.declaredElement;

      var element;
      var memberName;
      if (methodDecl.name.name == 'hashCode') {
        memberName = '==';
        element = classElement.lookUpInheritedMethod(
            memberName, classElement.library);
      } else {
        memberName = 'hashCode';
        element = classElement.lookUpInheritedConcreteGetter(
            memberName, classElement.library);
      }

      final location =
          utils.prepareNewClassMemberLocation(classDecl, (_) => true);

      final changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (fileBuilder) {
        fileBuilder.addInsertion(location.offset, (builder) {
          builder.write(location.prefix);
          builder.writeOverride(element, invokeSuper: true);
          builder.write(location.suffix);
        });
      });

      changeBuilder.setSelection(Position(file, location.offset));
      _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_METHOD,
          args: [memberName]);
    }
  }

  Future<void> _addFix_addMissingParameter() async {
    // The error is reported on ArgumentList.
    if (node is! ArgumentList) {
      return;
    }
    ArgumentList argumentList = node;
    List<Expression> arguments = argumentList.arguments;

    // Prepare the invoked element.
    var context = _ExecutableParameters(sessionHelper, node.parent);
    if (context == null) {
      return;
    }

    // prepare the argument to add a new parameter for
    var numRequired = context.required.length;
    if (numRequired >= arguments.length) {
      return;
    }
    var argument = arguments[numRequired];

    Future<void> addParameter(
        FixKind kind, int offset, String prefix, String suffix) async {
      if (offset != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(context.file, (builder) {
          builder.addInsertion(offset, (builder) {
            builder.write(prefix);
            builder.writeParameterMatchingArgument(
                argument, numRequired, <String>{});
            builder.write(suffix);
          });
        });
        _addFixFromBuilder(changeBuilder, kind);
      }
    }

    // Suggest adding a required parameter.
    {
      var kind = DartFixKind.ADD_MISSING_PARAMETER_REQUIRED;
      if (context.required.isNotEmpty) {
        var prevNode = await context.getParameterNode(context.required.last);
        await addParameter(kind, prevNode?.end, ', ', '');
      } else {
        var parameterList = await context.getParameterList();
        var offset = parameterList?.leftParenthesis?.end;
        var suffix = context.executable.parameters.isNotEmpty ? ', ' : '';
        await addParameter(kind, offset, '', suffix);
      }
    }

    // Suggest adding the first optional positional parameter.
    if (context.optionalPositional.isEmpty && context.named.isEmpty) {
      var kind = DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL;
      var prefix = context.required.isNotEmpty ? ', [' : '[';
      if (context.required.isNotEmpty) {
        var prevNode = await context.getParameterNode(context.required.last);
        await addParameter(kind, prevNode?.end, prefix, ']');
      } else {
        var parameterList = await context.getParameterList();
        var offset = parameterList?.leftParenthesis?.end;
        await addParameter(kind, offset, prefix, ']');
      }
    }
  }

  Future<void> _addFix_addMissingParameterNamed() async {
    // Prepare the name of the missing parameter.
    if (this.node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier node = this.node;
    var name = node.name;

    // We expect that the node is part of a NamedExpression.
    if (node.parent?.parent is! NamedExpression) {
      return;
    }
    NamedExpression namedExpression = node.parent.parent;

    // We should be in an ArgumentList.
    if (namedExpression.parent is! ArgumentList) {
      return;
    }
    var argumentList = namedExpression.parent;

    // Prepare the invoked element.
    var context = _ExecutableParameters(sessionHelper, argumentList.parent);
    if (context == null) {
      return;
    }

    // We cannot add named parameters when there are positional positional.
    if (context.optionalPositional.isNotEmpty) {
      return;
    }

    Future<void> addParameter(int offset, String prefix, String suffix) async {
      if (offset != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(context.file, (builder) {
          builder.addInsertion(offset, (builder) {
            builder.write(prefix);
            builder
                .writeParameterMatchingArgument(namedExpression, 0, <String>{});
            builder.write(suffix);
          });
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.ADD_MISSING_PARAMETER_NAMED,
            args: [name]);
      }
    }

    if (context.named.isNotEmpty) {
      var prevNode = await context.getParameterNode(context.named.last);
      await addParameter(prevNode?.end, ', ', '');
    } else if (context.required.isNotEmpty) {
      var prevNode = await context.getParameterNode(context.required.last);
      await addParameter(prevNode?.end, ', {', '}');
    } else {
      var parameterList = await context.getParameterList();
      await addParameter(parameterList?.leftParenthesis?.end, '{', '}');
    }
  }

  Future<void> _addFix_createClass() async {
    Element prefixElement;
    String name;
    SimpleIdentifier nameNode;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is PrefixedIdentifier) {
        PrefixedIdentifier prefixedIdentifier = parent;
        prefixElement = prefixedIdentifier.prefix.staticElement;
        if (prefixElement == null) {
          return;
        }
        parent = prefixedIdentifier.parent;
        nameNode = prefixedIdentifier.identifier;
        name = prefixedIdentifier.identifier.name;
      } else {
        nameNode = node;
        name = nameNode.name;
      }
      if (!_mayBeTypeIdentifier(nameNode)) {
        return;
      }
    } else {
      return;
    }
    // prepare environment
    Element targetUnit;
    var prefix = '';
    var suffix = '';
    var offset = -1;
    String filePath;
    if (prefixElement == null) {
      targetUnit = unit.declaredElement;
      var enclosingMember = node.thisOrAncestorMatching((node) =>
          node is CompilationUnitMember && node.parent is CompilationUnit);
      if (enclosingMember == null) {
        return;
      }
      offset = enclosingMember.end;
      filePath = file;
      prefix = '$eol$eol';
    } else {
      for (var import in unitLibraryElement.imports) {
        if (prefixElement is PrefixElement && import.prefix == prefixElement) {
          var library = import.importedLibrary;
          if (library != null) {
            targetUnit = library.definingCompilationUnit;
            var targetSource = targetUnit.source;
            try {
              offset = targetSource.contents.data.length;
              filePath = targetSource.fullName;
              prefix = '$eol';
              suffix = '$eol';
            } on FileSystemException {
              // If we can't read the file to get the offset, then we can't
              // create a fix.
            }
            break;
          }
        }
      }
    }
    if (offset < 0) {
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(filePath, (DartFileEditBuilder builder) {
      builder.addInsertion(offset, (DartEditBuilder builder) {
        builder.write(prefix);
        builder.writeClassDeclaration(name, nameGroupName: 'NAME');
        builder.write(suffix);
      });
      if (prefixElement == null) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_CLASS, args: [name]);
  }

  /// Here we handle cases when there are no constructors in a class, and the
  /// class has uninitialized final fields.
  Future<void> _addFix_createConstructor_forUninitializedFinalFields() async {
    if (node is! SimpleIdentifier || node.parent is! VariableDeclaration) {
      return;
    }

    var classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null) {
      return;
    }
    var className = classDeclaration.name.name;
    var superType = classDeclaration.declaredElement.supertype;

    // prepare names of uninitialized final fields
    var fieldNames = <String>[];
    for (var member in classDeclaration.members) {
      if (member is FieldDeclaration) {
        var variableList = member.fields;
        if (variableList.isFinal) {
          fieldNames.addAll(variableList.variables
              .where((v) => v.initializer == null)
              .map((v) => v.name.name));
        }
      }
    }
    // prepare location for a new constructor
    var targetLocation = utils.prepareNewConstructorLocation(classDeclaration);

    var changeBuilder = _newDartChangeBuilder();
    if (flutter.isExactlyStatelessWidgetType(superType) ||
        flutter.isExactlyStatefulWidgetType(superType)) {
      // Specialize for Flutter widgets.
      var keyClass = await sessionHelper.getClass(flutter.widgetsUri, 'Key');
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
          builder.write(targetLocation.prefix);
          builder.write('const ');
          builder.write(className);
          builder.write('({');
          builder.writeType(
            keyClass.instantiate(
              typeArguments: const [],
              nullabilitySuffix: _isNonNullable
                  ? NullabilitySuffix.question
                  : NullabilitySuffix.star,
            ),
          );
          builder.write(' key');

          var childrenFields = <String>[];
          for (var fieldName in fieldNames) {
            if (fieldName == 'child' || fieldName == 'children') {
              childrenFields.add(fieldName);
              continue;
            }
            builder.write(', this.');
            builder.write(fieldName);
          }
          for (var fieldName in childrenFields) {
            builder.write(', this.');
            builder.write(fieldName);
          }

          builder.write('}) : super(key: key);');
          builder.write(targetLocation.suffix);
        });
      });
    } else {
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
          builder.write(targetLocation.prefix);
          builder.writeConstructorDeclaration(className,
              fieldNames: fieldNames);
          builder.write(targetLocation.suffix);
        });
      });
    }
    _addFixFromBuilder(
        changeBuilder, DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS);
  }

  Future<void> _addFix_createConstructor_insteadOfSyntheticDefault() async {
    if (node is! ArgumentList) {
      return;
    }
    if (node.parent is! InstanceCreationExpression) {
      return;
    }
    InstanceCreationExpression instanceCreation = node.parent;
    var constructorName = instanceCreation.constructorName;
    // should be synthetic default constructor
    var constructorElement = constructorName.staticElement;
    if (constructorElement == null ||
        !constructorElement.isDefaultConstructor ||
        !constructorElement.isSynthetic) {
      return;
    }
    // prepare target
    if (constructorElement.enclosingElement is! ClassElement) {
      return;
    }

    // prepare target ClassDeclaration
    var targetElement = constructorElement.enclosingElement;
    var targetResult = await sessionHelper.getElementDeclaration(targetElement);
    if (targetResult.node is! ClassOrMixinDeclaration) {
      return;
    }
    ClassOrMixinDeclaration targetNode = targetResult.node;

    // prepare location
    var targetLocation = CorrectionUtils(targetResult.resolvedUnit)
        .prepareNewConstructorLocation(targetNode);

    var targetSource = targetElement.source;
    var targetFile = targetSource.fullName;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        builder.write(targetLocation.prefix);
        builder.writeConstructorDeclaration(targetElement.name,
            argumentList: instanceCreation.argumentList);
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_CONSTRUCTOR,
        args: [constructorName]);
  }

  Future<void> _addFix_createConstructor_named() async {
    SimpleIdentifier name;
    ConstructorName constructorName;
    InstanceCreationExpression instanceCreation;
    if (node is SimpleIdentifier) {
      // name
      name = node as SimpleIdentifier;
      if (name.parent is ConstructorName) {
        constructorName = name.parent as ConstructorName;
        if (constructorName.name == name) {
          // Type.name
          if (constructorName.parent is InstanceCreationExpression) {
            instanceCreation =
                constructorName.parent as InstanceCreationExpression;
            // new Type.name()
            if (instanceCreation.constructorName != constructorName) {
              return;
            }
          }
        }
      }
    }
    // do we have enough information?
    if (instanceCreation == null) {
      return;
    }
    // prepare target interface type
    var targetType = constructorName.type.type;
    if (targetType is! InterfaceType) {
      return;
    }

    // prepare target ClassDeclaration
    ClassElement targetElement = targetType.element;
    var targetResult = await sessionHelper.getElementDeclaration(targetElement);
    if (targetResult.node is! ClassOrMixinDeclaration) {
      return;
    }
    ClassOrMixinDeclaration targetNode = targetResult.node;

    // prepare location
    var targetLocation = CorrectionUtils(targetResult.resolvedUnit)
        .prepareNewConstructorLocation(targetNode);

    var targetFile = targetElement.source.fullName;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        builder.write(targetLocation.prefix);
        builder.writeConstructorDeclaration(targetElement.name,
            argumentList: instanceCreation.argumentList,
            constructorName: name,
            constructorNameGroupName: 'NAME');
        builder.write(targetLocation.suffix);
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(name), 'NAME');
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_CONSTRUCTOR,
        args: [constructorName]);
  }

  Future<void> _addFix_createConstructorSuperExplicit() async {
    if (node.parent is! ConstructorDeclaration ||
        node.parent.parent is! ClassDeclaration) {
      return;
    }
    var targetConstructor = node.parent as ConstructorDeclaration;
    var targetClassNode = targetConstructor.parent as ClassDeclaration;
    var targetClassElement = targetClassNode.declaredElement;
    var superType = targetClassElement.supertype;
    // add proposals for all super constructors
    for (var superConstructor in superType.constructors) {
      var constructorName = superConstructor.name;
      // skip private
      if (Identifier.isPrivateName(constructorName)) {
        continue;
      }
      List<ConstructorInitializer> initializers =
          targetConstructor.initializers;
      int insertOffset;
      String prefix;
      if (initializers.isEmpty) {
        insertOffset = targetConstructor.parameters.end;
        prefix = ' : ';
      } else {
        var lastInitializer = initializers[initializers.length - 1];
        insertOffset = lastInitializer.end;
        prefix = ', ';
      }
      var proposalName = _getConstructorProposalName(superConstructor);
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(insertOffset, (DartEditBuilder builder) {
          builder.write(prefix);
          // add super constructor name
          builder.write('super');
          if (!isEmpty(constructorName)) {
            builder.write('.');
            builder.addSimpleLinkedEdit('NAME', constructorName);
          }
          // add arguments
          builder.write('(');
          var firstParameter = true;
          for (var parameter in superConstructor.parameters) {
            // skip non-required parameters
            if (parameter.isOptional) {
              break;
            }
            // comma
            if (firstParameter) {
              firstParameter = false;
            } else {
              builder.write(', ');
            }
            // default value
            builder.addSimpleLinkedEdit(
                parameter.name, getDefaultValueCode(parameter.type));
          }
          builder.write(')');
        });
      });
      _addFixFromBuilder(
          changeBuilder, DartFixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION,
          args: [proposalName]);
    }
  }

  Future<void> _addFix_createConstructorSuperImplicit() async {
    var targetClassNode = node.thisOrAncestorOfType<ClassDeclaration>();
    var targetClassElement = targetClassNode.declaredElement;
    var superType = targetClassElement.supertype;
    var targetClassName = targetClassElement.name;
    // add proposals for all super constructors
    for (var superConstructor in superType.constructors) {
      var constructorName = superConstructor.name;
      // skip private
      if (Identifier.isPrivateName(constructorName)) {
        continue;
      }
      // prepare parameters and arguments
      var requiredParameters = superConstructor.parameters
          .where((parameter) => parameter.isRequiredPositional);
      // add proposal
      var targetLocation = utils.prepareNewConstructorLocation(targetClassNode);
      var proposalName = _getConstructorProposalName(superConstructor);
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
          void writeParameters(bool includeType) {
            var firstParameter = true;
            for (var parameter in requiredParameters) {
              if (firstParameter) {
                firstParameter = false;
              } else {
                builder.write(', ');
              }
              var parameterName = parameter.displayName;
              if (parameterName.length > 1 && parameterName.startsWith('_')) {
                parameterName = parameterName.substring(1);
              }
              if (includeType && builder.writeType(parameter.type)) {
                builder.write(' ');
              }
              builder.write(parameterName);
            }
          }

          builder.write(targetLocation.prefix);
          builder.write(targetClassName);
          if (constructorName.isNotEmpty) {
            builder.write('.');
            builder.addSimpleLinkedEdit('NAME', constructorName);
          }
          builder.write('(');
          writeParameters(true);
          builder.write(') : super');
          if (constructorName.isNotEmpty) {
            builder.write('.');
            builder.addSimpleLinkedEdit('NAME', constructorName);
          }
          builder.write('(');
          writeParameters(false);
          builder.write(');');
          builder.write(targetLocation.suffix);
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_CONSTRUCTOR_SUPER,
          args: [proposalName]);
    }
  }

  Future<void> _addFix_createField() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    var name = nameNode.name;
    // prepare target Expression
    Expression target;
    {
      var nameParent = nameNode.parent;
      if (nameParent is PrefixedIdentifier) {
        target = nameParent.prefix;
      } else if (nameParent is PropertyAccess) {
        target = nameParent.realTarget;
      }
    }
    // prepare target ClassElement
    var staticModifier = false;
    ClassElement targetClassElement;
    if (target != null) {
      targetClassElement = _getTargetClassElement(target);
      // maybe static
      if (target is Identifier) {
        var targetIdentifier = target;
        var targetElement = targetIdentifier.staticElement;
        if (targetElement == null) {
          return;
        }
        staticModifier = targetElement.kind == ElementKind.CLASS;
      }
    } else {
      targetClassElement = getEnclosingClassElement(node);
      staticModifier = _inStaticContext();
    }
    if (targetClassElement == null) {
      return;
    }
    if (targetClassElement.librarySource.isInSystemLibrary) {
      return;
    }
    utils.targetClassElement = targetClassElement;
    // prepare target ClassDeclaration
    var targetDeclarationResult =
        await sessionHelper.getElementDeclaration(targetClassElement);
    if (targetDeclarationResult == null) {
      return;
    }
    if (targetDeclarationResult.node is! ClassOrMixinDeclaration) {
      return;
    }
    ClassOrMixinDeclaration targetNode = targetDeclarationResult.node;
    // prepare location
    var targetLocation = CorrectionUtils(targetDeclarationResult.resolvedUnit)
        .prepareNewFieldLocation(targetNode);
    // build field source
    var targetSource = targetClassElement.source;
    var targetFile = targetSource.fullName;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      var fieldTypeNode = climbPropertyAccess(nameNode);
      var fieldType = _inferUndefinedExpressionType(fieldTypeNode);
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        builder.write(targetLocation.prefix);
        builder.writeFieldDeclaration(name,
            isStatic: staticModifier,
            nameGroupName: 'NAME',
            type: fieldType,
            typeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FIELD, args: [name]);
  }

  Future<void> _addFix_createField_initializingFormal() async {
    //
    // Ensure that we are in an initializing formal parameter.
    //
    var parameter = node.thisOrAncestorOfType<FieldFormalParameter>();
    if (parameter == null) {
      return;
    }
    var targetClassNode = parameter.thisOrAncestorOfType<ClassDeclaration>();
    if (targetClassNode == null) {
      return;
    }
    var nameNode = parameter.identifier;
    var name = nameNode.name;
    var targetLocation = utils.prepareNewFieldLocation(targetClassNode);
    //
    // Add proposal.
    //
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      var fieldType = parameter.type?.type;
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        builder.write(targetLocation.prefix);
        builder.writeFieldDeclaration(name,
            nameGroupName: 'NAME', type: fieldType, typeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FIELD, args: [name]);
  }

  Future<void> _addFix_createFunction_forFunctionType() async {
    if (node is SimpleIdentifier) {
      var nameNode = node as SimpleIdentifier;
      // prepare argument expression (to get parameter)
      ClassElement targetElement;
      Expression argument;
      {
        var target = getQualifiedPropertyTarget(node);
        if (target != null) {
          var targetType = target.staticType;
          if (targetType != null && targetType.element is ClassElement) {
            targetElement = targetType.element as ClassElement;
            argument = target.parent as Expression;
          } else {
            return;
          }
        } else {
          var enclosingClass =
              node.thisOrAncestorOfType<ClassOrMixinDeclaration>();
          targetElement = enclosingClass?.declaredElement;
          argument = nameNode;
        }
      }
      argument = stepUpNamedExpression(argument);
      // should be argument of some invocation
      var parameterElement = argument.staticParameterElement;
      if (parameterElement == null) {
        return;
      }
      // should be parameter of function type
      var parameterType = parameterElement.type;
      if (parameterType is InterfaceType && parameterType.isDartCoreFunction) {
        parameterType = FunctionTypeImpl(
          typeFormals: const [],
          parameters: const [],
          returnType: typeProvider.dynamicType,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
      if (parameterType is! FunctionType) {
        return;
      }
      var functionType = parameterType as FunctionType;
      // add proposal
      if (targetElement != null) {
        await _addProposal_createFunction_method(targetElement, functionType);
      } else {
        await _addProposal_createFunction_function(functionType);
      }
    }
  }

  Future<void> _addFix_createGetter() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    var name = nameNode.name;
    if (!nameNode.inGetterContext()) {
      return;
    }
    // prepare target
    Expression target;
    {
      var nameParent = nameNode.parent;
      if (nameParent is PrefixedIdentifier) {
        target = nameParent.prefix;
      } else if (nameParent is PropertyAccess) {
        target = nameParent.realTarget;
      }
    }
    // prepare target element
    var staticModifier = false;
    Element targetElement;
    if (target is ExtensionOverride) {
      targetElement = target.staticElement;
    } else if (target is Identifier &&
        target.staticElement is ExtensionElement) {
      targetElement = target.staticElement;
      staticModifier = true;
    } else if (target != null) {
      // prepare target interface type
      var targetType = target.staticType;
      if (targetType is! InterfaceType) {
        return;
      }
      targetElement = targetType.element;
      // maybe static
      if (target is Identifier) {
        var targetIdentifier = target;
        var targetElement = targetIdentifier.staticElement;
        staticModifier = targetElement?.kind == ElementKind.CLASS;
      }
    } else {
      targetElement =
          getEnclosingClassElement(node) ?? getEnclosingExtensionElement(node);
      if (targetElement == null) {
        return;
      }
      staticModifier = _inStaticContext();
    }
    if (targetElement.librarySource.isInSystemLibrary) {
      return;
    }
    // prepare target declaration
    var targetDeclarationResult =
        await sessionHelper.getElementDeclaration(targetElement);
    if (targetDeclarationResult == null) {
      return;
    }
    if (targetDeclarationResult.node is! ClassOrMixinDeclaration &&
        targetDeclarationResult.node is! ExtensionDeclaration) {
      return;
    }
    CompilationUnitMember targetNode = targetDeclarationResult.node;
    // prepare location
    var targetLocation = CorrectionUtils(targetDeclarationResult.resolvedUnit)
        .prepareNewGetterLocation(targetNode);
    // build method source
    var targetSource = targetElement.source;
    var targetFile = targetSource.fullName;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        var fieldTypeNode = climbPropertyAccess(nameNode);
        var fieldType = _inferUndefinedExpressionType(fieldTypeNode);
        builder.write(targetLocation.prefix);
        builder.writeGetterDeclaration(name,
            isStatic: staticModifier,
            nameGroupName: 'NAME',
            returnType: fieldType,
            returnTypeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_GETTER, args: [name]);
  }

  Future<void> _addFix_createImportUri() async {
    // TODO(brianwilkerson) Generalize this to allow other valid string literals.
    // TODO(brianwilkerson) Support the case where the node's parent is a Configuration.
    if (node is SimpleStringLiteral && node.parent is ImportDirective) {
      ImportDirective importDirective = node.parent;
      var source = importDirective.uriSource;
      if (source != null) {
        var file = source.fullName;
        if (isAbsolute(file) && AnalysisEngine.isDartFileName(file)) {
          var changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(source.fullName, (builder) {
            builder.addSimpleInsertion(0, '// TODO Implement this library.');
          });
          _addFixFromBuilder(
            changeBuilder,
            DartFixKind.CREATE_FILE,
            args: [source.shortName],
          );
        }
      }
    }
  }

  Future<void> _addFix_createLocalVariable() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    var name = nameNode.name;
    // if variable is assigned, convert assignment into declaration
    if (node.parent is AssignmentExpression) {
      AssignmentExpression assignment = node.parent;
      if (assignment.leftHandSide == node &&
          assignment.operator.type == TokenType.EQ &&
          assignment.parent is ExpressionStatement) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleInsertion(node.offset, 'var ');
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_LOCAL_VARIABLE,
            args: [name]);
        return;
      }
    }
    // prepare target Statement
    var target = node.thisOrAncestorOfType<Statement>();
    if (target == null) {
      return;
    }
    var prefix = utils.getNodePrefix(target);
    // compute type
    var type = _inferUndefinedExpressionType(node);
    if (!(type == null || type is InterfaceType || type is FunctionType)) {
      return;
    }
    // build variable declaration source
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(target.offset, (DartEditBuilder builder) {
        builder.writeLocalVariableDeclaration(name,
            nameGroupName: 'NAME', type: type, typeGroupName: 'TYPE');
        builder.write(eol);
        builder.write(prefix);
      });
      builder.addLinkedPosition(range.node(node), 'NAME');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_LOCAL_VARIABLE,
        args: [name]);
  }

  Future<void> _addFix_createMethod() async {
    if (node is! SimpleIdentifier || node.parent is! MethodInvocation) {
      return;
    }
    var name = (node as SimpleIdentifier).name;
    var invocation = node.parent as MethodInvocation;
    // prepare environment
    Element targetElement;
    var staticModifier = false;

    CompilationUnitMember targetNode;
    var target = invocation.realTarget;
    var utils = this.utils;
    if (target is ExtensionOverride) {
      targetElement = target.staticElement;
      targetNode = await _getExtensionDeclaration(targetElement);
      if (targetNode == null) {
        return;
      }
    } else if (target is Identifier &&
        target.staticElement is ExtensionElement) {
      targetElement = target.staticElement;
      targetNode = await _getExtensionDeclaration(targetElement);
      if (targetNode == null) {
        return;
      }
      staticModifier = true;
    } else if (target == null) {
      targetElement = unit.declaredElement;
      var enclosingMember = node.thisOrAncestorOfType<ClassMember>();
      if (enclosingMember == null) {
        // If the undefined identifier isn't inside a class member, then it
        // doesn't make sense to create a method.
        return;
      }
      targetNode = enclosingMember.parent;
      staticModifier = _inStaticContext();
    } else {
      var targetClassElement = _getTargetClassElement(target);
      if (targetClassElement == null) {
        return;
      }
      targetElement = targetClassElement;
      if (targetClassElement.librarySource.isInSystemLibrary) {
        return;
      }
      // prepare target ClassDeclaration
      targetNode = await _getClassDeclaration(targetClassElement);
      if (targetNode == null) {
        return;
      }
      // maybe static
      if (target is Identifier) {
        staticModifier = target.staticElement.kind == ElementKind.CLASS;
      }
      // use different utils
      var targetPath = targetClassElement.source.fullName;
      var targetResolveResult = await session.getResolvedUnit(targetPath);
      utils = CorrectionUtils(targetResolveResult);
    }
    var targetLocation = utils.prepareNewMethodLocation(targetNode);
    var targetFile = targetElement.source.fullName;
    // build method source
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        builder.write(targetLocation.prefix);
        // maybe "static"
        if (staticModifier) {
          builder.write('static ');
        }
        // append return type
        {
          var type = _inferUndefinedExpressionType(invocation);
          if (builder.writeType(type, groupName: 'RETURN_TYPE')) {
            builder.write(' ');
          }
        }
        // append name
        builder.addLinkedEdit('NAME', (DartLinkedEditBuilder builder) {
          builder.write(name);
        });
        builder.write('(');
        builder.writeParametersMatchingArguments(invocation.argumentList);
        builder.write(') {}');
        builder.write(targetLocation.suffix);
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_METHOD, args: [name]);
  }

  Future<void> _addFix_createMissingOverrides() async {
    if (node.parent is! ClassDeclaration) {
      return;
    }
    var targetClass = node.parent as ClassDeclaration;
    var targetClassElement = targetClass.declaredElement;
    utils.targetClassElement = targetClassElement;
    var signatures =
        InheritanceOverrideVerifier.missingOverrides(targetClass).toList();
    // sort by name, getters before setters
    signatures.sort((ExecutableElement a, ExecutableElement b) {
      var names = compareStrings(a.displayName, b.displayName);
      if (names != 0) {
        return names;
      }
      if (a.kind == ElementKind.GETTER) {
        return -1;
      }
      return 1;
    });
    var numElements = signatures.length;

    var location =
        utils.prepareNewClassMemberLocation(targetClass, (_) => true);

    var prefix = utils.getIndent(1);
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(location.offset, (DartEditBuilder builder) {
        // Separator management.
        var numOfMembersWritten = 0;
        void addSeparatorBetweenDeclarations() {
          if (numOfMembersWritten == 0) {
            builder.write(location.prefix);
          } else {
            builder.write(eol); // after the previous member
            builder.write(eol); // empty line separator
            builder.write(prefix);
          }
          numOfMembersWritten++;
        }

        // merge getter/setter pairs into fields
        for (var i = 0; i < signatures.length; i++) {
          var element = signatures[i];
          if (element.kind == ElementKind.GETTER && i + 1 < signatures.length) {
            var nextElement = signatures[i + 1];
            if (nextElement.kind == ElementKind.SETTER) {
              // remove this and the next elements, adjust iterator
              signatures.removeAt(i + 1);
              signatures.removeAt(i);
              i--;
              numElements--;
              // separator
              addSeparatorBetweenDeclarations();
              // @override
              builder.write('@override');
              builder.write(eol);
              // add field
              builder.write(prefix);
              builder.writeType(element.returnType, required: true);
              builder.write(' ');
              builder.write(element.name);
              builder.write(';');
            }
          }
        }
        // add elements
        for (var element in signatures) {
          addSeparatorBetweenDeclarations();
          builder.writeOverride(element);
        }
        builder.write(location.suffix);
      });
    });
    changeBuilder.setSelection(Position(file, location.offset));
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_MISSING_OVERRIDES,
        args: [numElements]);
  }

  Future<void> _addFix_createMixin() async {
    Element prefixElement;
    String name;
    SimpleIdentifier nameNode;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is PrefixedIdentifier) {
        if (parent.parent is InstanceCreationExpression) {
          return;
        }
        PrefixedIdentifier prefixedIdentifier = parent;
        prefixElement = prefixedIdentifier.prefix.staticElement;
        if (prefixElement == null) {
          return;
        }
        parent = prefixedIdentifier.parent;
        nameNode = prefixedIdentifier.identifier;
        name = prefixedIdentifier.identifier.name;
      } else if (parent is TypeName &&
          parent.parent is ConstructorName &&
          parent.parent.parent is InstanceCreationExpression) {
        return;
      } else {
        nameNode = node;
        name = nameNode.name;
      }
      if (!_mayBeTypeIdentifier(nameNode)) {
        return;
      }
    } else {
      return;
    }
    // prepare environment
    Element targetUnit;
    var prefix = '';
    var suffix = '';
    var offset = -1;
    String filePath;
    if (prefixElement == null) {
      targetUnit = unit.declaredElement;
      var enclosingMember = node.thisOrAncestorMatching((node) =>
          node is CompilationUnitMember && node.parent is CompilationUnit);
      if (enclosingMember == null) {
        return;
      }
      offset = enclosingMember.end;
      filePath = file;
      prefix = '$eol$eol';
    } else {
      for (var import in unitLibraryElement.imports) {
        if (prefixElement is PrefixElement && import.prefix == prefixElement) {
          var library = import.importedLibrary;
          if (library != null) {
            targetUnit = library.definingCompilationUnit;
            var targetSource = targetUnit.source;
            try {
              offset = targetSource.contents.data.length;
              filePath = targetSource.fullName;
              prefix = '$eol';
              suffix = '$eol';
            } on FileSystemException {
              // If we can't read the file to get the offset, then we can't
              // create a fix.
            }
            break;
          }
        }
      }
    }
    if (offset < 0) {
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(filePath, (DartFileEditBuilder builder) {
      builder.addInsertion(offset, (DartEditBuilder builder) {
        builder.write(prefix);
        builder.writeMixinDeclaration(name, nameGroupName: 'NAME');
        builder.write(suffix);
      });
      if (prefixElement == null) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_MIXIN, args: [name]);
  }

  Future<void> _addFix_createNoSuchMethod() async {
    if (node.parent is! ClassDeclaration) {
      return;
    }
    var targetClass = node.parent as ClassDeclaration;
    // prepare environment
    var prefix = utils.getIndent(1);
    var insertOffset = targetClass.end - 1;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(insertOffset, (DartEditBuilder builder) {
        builder.selectHere();
        // insert empty line before existing member
        if (targetClass.members.isNotEmpty) {
          builder.write(eol);
        }
        // append method
        builder.write(prefix);
        builder.write(
            'noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);');
        builder.write(eol);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_NO_SUCH_METHOD);
  }

  Future<void> _addFix_createPartUri() async {
    // TODO(brianwilkerson) Generalize this to allow other valid string literals.
    if (node is SimpleStringLiteral && node.parent is PartDirective) {
      PartDirective partDirective = node.parent;
      var source = partDirective.uriSource;
      if (source != null) {
        var libName = unitLibraryElement.name;
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(source.fullName,
            (DartFileEditBuilder builder) {
          // TODO(brianwilkerson) Consider using the URI rather than name
          builder.addSimpleInsertion(0, 'part of $libName;$eol$eol');
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FILE,
            args: [source.shortName]);
      }
    }
  }

  Future<void> _addFix_createSetter() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    if (!nameNode.inSetterContext()) {
      return;
    }
    // prepare target
    Expression target;
    {
      var nameParent = nameNode.parent;
      if (nameParent is PrefixedIdentifier) {
        target = nameParent.prefix;
      } else if (nameParent is PropertyAccess) {
        target = nameParent.realTarget;
      }
    }
    // prepare target element
    var staticModifier = false;
    Element targetElement;
    if (target is ExtensionOverride) {
      targetElement = target.staticElement;
    } else if (target is Identifier &&
        target.staticElement is ExtensionElement) {
      targetElement = target.staticElement;
      staticModifier = true;
    } else if (target != null) {
      // prepare target interface type
      var targetType = target.staticType;
      if (targetType is! InterfaceType) {
        return;
      }
      targetElement = targetType.element;
      // maybe static
      if (target is Identifier) {
        var targetIdentifier = target;
        var targetElement = targetIdentifier.staticElement;
        staticModifier = targetElement?.kind == ElementKind.CLASS;
      }
    } else {
      targetElement =
          getEnclosingClassElement(node) ?? getEnclosingExtensionElement(node);
      if (targetElement == null) {
        return;
      }
      staticModifier = _inStaticContext();
    }
    if (targetElement.librarySource.isInSystemLibrary) {
      return;
    }
    // prepare target declaration
    var targetDeclarationResult =
        await sessionHelper.getElementDeclaration(targetElement);
    if (targetDeclarationResult == null) {
      return;
    }
    if (targetDeclarationResult.node is! ClassOrMixinDeclaration &&
        targetDeclarationResult.node is! ExtensionDeclaration) {
      return;
    }
    CompilationUnitMember targetNode = targetDeclarationResult.node;
    // prepare location
    var targetLocation = CorrectionUtils(targetDeclarationResult.resolvedUnit)
        .prepareNewGetterLocation(targetNode); // Rename to "AccessorLocation"
    // build method source
    var targetSource = targetElement.source;
    var targetFile = targetSource.fullName;
    var name = nameNode.name;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(targetLocation.offset, (DartEditBuilder builder) {
        var parameterTypeNode = climbPropertyAccess(nameNode);
        var parameterType = _inferUndefinedExpressionType(parameterTypeNode);
        builder.write(targetLocation.prefix);
        builder.writeSetterDeclaration(name,
            isStatic: staticModifier,
            nameGroupName: 'NAME',
            parameterType: parameterType,
            parameterTypeGroupName: 'TYPE');
        builder.write(targetLocation.suffix);
      });
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_SETTER, args: [name]);
  }

  Future<void> _addFix_extendClassForMixin() async {
    var declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration != null && declaration.extendsClause == null) {
      // TODO(brianwilkerson) Find a way to pass in the name of the class
      //  without needing to parse the message.
      var message = error.message;
      var endIndex = message.lastIndexOf("'");
      var startIndex = message.lastIndexOf("'", endIndex - 1) + 1;
      var typeName = message.substring(startIndex, endIndex);
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleInsertion(
            declaration.typeParameters?.end ?? declaration.name.end,
            ' extends $typeName');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.EXTEND_CLASS_FOR_MIXIN,
          args: [typeName]);
    }
  }

  Future<void> _addFix_illegalAsyncReturnType() async {
    // prepare the existing type
    var typeName = node.thisOrAncestorOfType<TypeAnnotation>();
    var typeProvider = this.typeProvider;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.replaceTypeWithFuture(typeName, typeProvider);
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_RETURN_TYPE_FUTURE);
  }

  Future<void> _addFix_importAsync() async {
    await _addFix_importLibrary(
        DartFixKind.IMPORT_ASYNC, Uri.parse('dart:async'));
  }

  Future<void> _addFix_importLibrary(FixKind kind, Uri library,
      [String relativeURI]) async {
    String uriText;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      uriText = builder.importLibrary(library);
    });
    _addFixFromBuilder(changeBuilder, kind, args: [uriText]);

    if (relativeURI != null && relativeURI.isNotEmpty) {
      var changeBuilder2 = _newDartChangeBuilder();
      await changeBuilder2.addFileEdit(file, (DartFileEditBuilder builder) {
        if (builder is DartFileEditBuilderImpl) {
          builder.importLibraryWithRelativeUri(relativeURI);
        }
      });
      _addFixFromBuilder(changeBuilder2, kind, args: [relativeURI]);
    }
  }

  Future<void> _addFix_importLibrary_withElement(
      String name,
      List<ElementKind> elementKinds,
      List<TopLevelDeclarationKind> kinds2) async {
    // ignore if private
    if (name.startsWith('_')) {
      return;
    }
    // may be there is an existing import,
    // but it is with prefix and we don't use this prefix
    var alreadyImportedWithPrefix = <String>{};
    for (var imp in unitLibraryElement.imports) {
      // prepare element
      var libraryElement = imp.importedLibrary;
      var element = getExportedElement(libraryElement, name);
      if (element == null) {
        continue;
      }
      if (element is PropertyAccessorElement) {
        element = (element as PropertyAccessorElement).variable;
      }
      if (!elementKinds.contains(element.kind)) {
        continue;
      }
      // may be apply prefix
      var prefix = imp.prefix;
      if (prefix != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              range.startLength(node, 0), '${prefix.displayName}.');
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.IMPORT_LIBRARY_PREFIX,
            args: [libraryElement.displayName, prefix.displayName]);
        continue;
      }
      // may be update "show" directive
      var combinators = imp.combinators;
      if (combinators.length == 1 && combinators[0] is ShowElementCombinator) {
        var showCombinator = combinators[0] as ShowElementCombinator;
        // prepare new set of names to show
        Set<String> showNames = SplayTreeSet<String>();
        showNames.addAll(showCombinator.shownNames);
        showNames.add(name);
        // prepare library name - unit name or 'dart:name' for SDK library
        var libraryName =
            libraryElement.definingCompilationUnit.source.uri.toString();
        if (libraryElement.isInSdk) {
          libraryName = libraryElement.source.shortName;
        }
        // don't add this library again
        alreadyImportedWithPrefix.add(libraryElement.source.fullName);
        // update library
        var newShowCode = 'show ${showNames.join(', ')}';
        var offset = showCombinator.offset;
        var length = showCombinator.end - offset;
        var libraryFile = context.resolveResult.libraryElement.source.fullName;
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(libraryFile,
            (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              SourceRange(offset, length), newShowCode);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.IMPORT_LIBRARY_SHOW,
            args: [libraryName]);
      }
    }
    // Find new top-level declarations.
    {
      var declarations = context.getTopLevelDeclarations(name);
      for (var declaration in declarations) {
        // Check the kind.
        if (!kinds2.contains(declaration.kind)) {
          continue;
        }
        // Check the source.
        if (alreadyImportedWithPrefix.contains(declaration.path)) {
          continue;
        }
        // Check that the import doesn't end with '.template.dart'
        if (declaration.uri.path.endsWith('.template.dart')) {
          continue;
        }
        // Compute the fix kind.
        FixKind fixKind;
        if (declaration.uri.isScheme('dart')) {
          fixKind = DartFixKind.IMPORT_LIBRARY_SDK;
        } else if (_isLibSrcPath(declaration.path)) {
          // Bad: non-API.
          fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT3;
        } else if (declaration.isExported) {
          // Ugly: exports.
          fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT2;
        } else {
          // Good: direct declaration.
          fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT1;
        }
        // Add the fix.
        var relativeURI =
            _getRelativeURIFromLibrary(unitLibraryElement, declaration.path);
        await _addFix_importLibrary(fixKind, declaration.uri, relativeURI);
      }
    }
  }

  Future<void> _addFix_importLibrary_withExtension() async {
    if (node is SimpleIdentifier) {
      var extensionName = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(
          extensionName,
          const [ElementKind.EXTENSION],
          const [TopLevelDeclarationKind.extension]);
    }
  }

  Future<void> _addFix_importLibrary_withFunction() async {
    if (node is SimpleIdentifier) {
      if (node.parent is MethodInvocation) {
        var invocation = node.parent as MethodInvocation;
        if (invocation.realTarget != null || invocation.methodName != node) {
          return;
        }
      }

      var name = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(name, const [
        ElementKind.FUNCTION,
        ElementKind.TOP_LEVEL_VARIABLE
      ], const [
        TopLevelDeclarationKind.function,
        TopLevelDeclarationKind.variable
      ]);
    }
  }

  Future<void> _addFix_importLibrary_withTopLevelVariable() async {
    if (node is SimpleIdentifier) {
      var name = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(
          name,
          const [ElementKind.TOP_LEVEL_VARIABLE],
          const [TopLevelDeclarationKind.variable]);
    }
  }

  Future<void> _addFix_importLibrary_withType() async {
    if (_mayBeTypeIdentifier(node)) {
      var typeName = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(
          typeName,
          const [ElementKind.CLASS, ElementKind.FUNCTION_TYPE_ALIAS],
          const [TopLevelDeclarationKind.type]);
    } else if (_mayBeImplicitConstructor(node)) {
      var typeName = (node as SimpleIdentifier).name;
      await _addFix_importLibrary_withElement(typeName,
          const [ElementKind.CLASS], const [TopLevelDeclarationKind.type]);
    }
  }

  Future<void> _addFix_insertSemicolon() async {
    if (error.message.contains("';'")) {
      if (_isAwaitNode()) {
        return;
      }
      var insertOffset = error.offset + error.length;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleInsertion(insertOffset, ';');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.INSERT_SEMICOLON);
    }
  }

  Future<void> _addFix_isNotEmpty() async {
    if (node is! PrefixExpression) {
      return;
    }
    PrefixExpression prefixExpression = node;
    var negation = prefixExpression.operator;
    if (negation.type != TokenType.BANG) {
      return;
    }
    SimpleIdentifier identifier;
    var expression = prefixExpression.operand;
    if (expression is PrefixedIdentifier) {
      identifier = expression.identifier;
    } else if (expression is PropertyAccess) {
      identifier = expression.propertyName;
    } else {
      return;
    }
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(range.token(negation));
      builder.addSimpleReplacement(range.node(identifier), 'isNotEmpty');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.USE_IS_NOT_EMPTY);
  }

  Future<void> _addFix_isNotNull() async {
    if (coveredNode is IsExpression) {
      var isExpression = coveredNode as IsExpression;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder
            .addReplacement(range.endEnd(isExpression.expression, isExpression),
                (DartEditBuilder builder) {
          builder.write(' != null');
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.USE_NOT_EQ_NULL);
    }
  }

  Future<void> _addFix_isNull() async {
    if (coveredNode is IsExpression) {
      var isExpression = coveredNode as IsExpression;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder
            .addReplacement(range.endEnd(isExpression.expression, isExpression),
                (DartEditBuilder builder) {
          builder.write(' == null');
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.USE_EQ_EQ_NULL);
    }
  }

  Future<void> _addFix_makeEnclosingClassAbstract() async {
    var enclosingClass = node.thisOrAncestorOfType<ClassDeclaration>();
    if (enclosingClass == null) {
      return;
    }
    var className = enclosingClass.name.name;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(
          enclosingClass.classKeyword.offset, 'abstract ');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.MAKE_CLASS_ABSTRACT,
        args: [className]);
  }

  Future<void> _addFix_makeFieldNotFinal() async {
    var node = this.node;
    if (node is SimpleIdentifier &&
        node.staticElement is PropertyAccessorElement) {
      PropertyAccessorElement getter = node.staticElement;
      if (getter.isGetter &&
          getter.isSynthetic &&
          !getter.variable.isSynthetic &&
          getter.variable.setter == null &&
          getter.enclosingElement is ClassElement) {
        var declarationResult =
            await sessionHelper.getElementDeclaration(getter.variable);
        var variable = declarationResult.node;
        if (variable is VariableDeclaration &&
            variable.parent is VariableDeclarationList &&
            variable.parent.parent is FieldDeclaration) {
          VariableDeclarationList declarationList = variable.parent;
          var keywordToken = declarationList.keyword;
          if (declarationList.variables.length == 1 &&
              keywordToken.keyword == Keyword.FINAL) {
            var changeBuilder = _newDartChangeBuilder();
            await changeBuilder.addFileEdit(file,
                (DartFileEditBuilder builder) {
              if (declarationList.type != null) {
                builder.addReplacement(
                    range.startStart(keywordToken, declarationList.type),
                    (DartEditBuilder builder) {});
              } else {
                builder.addReplacement(range.startStart(keywordToken, variable),
                    (DartEditBuilder builder) {
                  builder.write('var ');
                });
              }
            });
            var fieldName = getter.variable.displayName;
            _addFixFromBuilder(changeBuilder, DartFixKind.MAKE_FIELD_NOT_FINAL,
                args: [fieldName]);
          }
        }
      }
    }
  }

  Future<void> _addFix_makeVariableFinal() async {
    var node = this.node;
    if (node is SimpleIdentifier && node.parent is VariableDeclaration) {
      VariableDeclaration declaration = node.parent;
      VariableDeclarationList list = declaration.parent;
      if (list.variables.length == 1) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          if (list.keyword == null) {
            builder.addSimpleInsertion(list.offset, 'final ');
          } else if (list.keyword.keyword == Keyword.VAR) {
            builder.addSimpleReplacement(range.token(list.keyword), 'final');
          }
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.MAKE_FINAL);
      }
    }
  }

  Future<void> _addFix_makeVariableNotFinal() async {
    var node = this.node;
    if (node is SimpleIdentifier &&
        node.staticElement is LocalVariableElement) {
      LocalVariableElement variable = node.staticElement;
      var id = NodeLocator(variable.nameOffset).searchWithin(unit);
      var decl = id?.parent;
      if (decl is VariableDeclaration &&
          decl.parent is VariableDeclarationList) {
        VariableDeclarationList declarationList = decl.parent;
        var keywordToken = declarationList.keyword;
        if (declarationList.variables.length == 1 &&
            keywordToken.keyword == Keyword.FINAL) {
          var changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            if (declarationList.type != null) {
              builder.addDeletion(
                  range.startStart(keywordToken, declarationList.type));
            } else {
              builder.addSimpleReplacement(range.token(keywordToken), 'var');
            }
          });
          declarationList.variables[0].name.name;
          var varName = declarationList.variables[0].name.name;
          _addFixFromBuilder(changeBuilder, DartFixKind.MAKE_VARIABLE_NOT_FINAL,
              args: [varName]);
        }
      }
    }
  }

  Future<void> _addFix_moveTypeArgumentsToClass() async {
    if (coveredNode is TypeArgumentList) {
      TypeArgumentList typeArguments = coveredNode;
      if (typeArguments.parent is! InstanceCreationExpression) {
        return;
      }
      InstanceCreationExpression creation = typeArguments.parent;
      var typeName = creation.constructorName.type;
      if (typeName.typeArguments != null) {
        return;
      }
      var element = typeName.type.element;
      if (element is ClassElement &&
          element.typeParameters != null &&
          element.typeParameters.length == typeArguments.arguments.length) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          var argumentText = utils.getNodeText(typeArguments);
          builder.addSimpleInsertion(typeName.end, argumentText);
          builder.addDeletion(range.node(typeArguments));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.MOVE_TYPE_ARGUMENTS_TO_CLASS);
      }
    }
  }

  Future<void> _addFix_nonBoolCondition_addNotNull() async {
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(error.offset + error.length, ' != null');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.ADD_NE_NULL);
  }

  Future<void> _addFix_qualifyReference() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier memberName = node;
    var parent = node.parent;
    AstNode target;
    if (parent is MethodInvocation && node == parent.methodName) {
      target = parent.target;
    } else if (parent is PropertyAccess && node == parent.propertyName) {
      target = parent.target;
    }
    if (target != null) {
      return;
    }
    var enclosingElement = memberName.staticElement.enclosingElement;
    if (enclosingElement.library != unitLibraryElement) {
      // TODO(brianwilkerson) Support qualifying references to members defined
      //  in other libraries. `DartEditBuilder` currently defines the method
      //  `writeType`, which is close, but we also need to handle extensions,
      //  which don't have a type.
      return;
    }
    var containerName = enclosingElement.name;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(node.offset, '$containerName.');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.QUALIFY_REFERENCE,
        args: ['$containerName.${memberName.name}']);
  }

  Future<void> _addFix_removeAnnotation() async {
    void addFix(Annotation node) async {
      if (node == null) {
        return;
      }
      var followingToken = node.endToken.next;
      followingToken = followingToken.precedingComments ?? followingToken;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(node, followingToken));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_ANNOTATION,
          args: [node.name.name]);
    }

    Annotation findAnnotation(
        NodeList<Annotation> metadata, String targetName) {
      return metadata.firstWhere(
          (annotation) => annotation.name.name == targetName,
          orElse: () => null);
    }

    var node = coveredNode;
    if (node is Annotation) {
      await addFix(node);
    } else if (node is DefaultFormalParameter) {
      await addFix(findAnnotation(node.parameter.metadata, 'required'));
    } else if (node is NormalFormalParameter) {
      await addFix(findAnnotation(node.metadata, 'required'));
    } else if (node is DeclaredSimpleIdentifier) {
      var parent = node.parent;
      if (parent is MethodDeclaration) {
        await addFix(findAnnotation(parent.metadata, 'override'));
      } else if (parent is VariableDeclaration) {
        var fieldDeclaration = parent.thisOrAncestorOfType<FieldDeclaration>();
        if (fieldDeclaration != null) {
          await addFix(findAnnotation(fieldDeclaration.metadata, 'override'));
        }
      }
    }
  }

  Future<void> _addFix_removeArgument() async {
    var arg = node;
    if (arg.parent is NamedExpression) {
      arg = arg.parent;
    }

    var argumentList = arg.parent.thisOrAncestorOfType<ArgumentList>();
    if (argumentList != null) {
      final changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        final sourceRange = range.nodeInList(argumentList.arguments, arg);
        builder.addDeletion(sourceRange);
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_ARGUMENT);
    }
  }

  Future<void> _addFix_removeAwait() async {
    final awaitExpression = node;
    if (awaitExpression is AwaitExpression) {
      final awaitToken = awaitExpression.awaitKeyword;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(awaitToken, awaitToken.next));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_AWAIT);
    }
  }

  Future<void> _addFix_removeCaseStatement() async {
    if (coveredNode is SwitchCase) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(utils.getLinesRange(range.node(coveredNode)));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DUPLICATE_CASE);
    }
  }

  Future<void> _addFix_removeConstKeyword(FixKind kind) async {
    final expression = node;
    if (expression is InstanceCreationExpression) {
      final constToken = expression.keyword;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(constToken, constToken.next));
      });
      _addFixFromBuilder(changeBuilder, kind);
    } else if (expression is TypedLiteralImpl) {
      final constToken = expression.constKeyword;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(constToken, constToken.next));
      });
      _addFixFromBuilder(changeBuilder, kind);
    }
  }

  Future<void> _addFix_removeDeadCode() async {
    var coveringNode = coveredNode;
    if (coveringNode is Expression) {
      var parent = coveredNode.parent;
      if (parent is BinaryExpression) {
        if (parent.rightOperand == coveredNode) {
          var changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            builder.addDeletion(range.endEnd(parent.leftOperand, coveredNode));
          });
          _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
        }
      }
    } else if (coveringNode is Block) {
      var block = coveringNode;
      var statementsToRemove = <Statement>[];
      var errorRange = SourceRange(errorOffset, errorLength);
      for (var statement in block.statements) {
        if (range.node(statement).intersects(errorRange)) {
          statementsToRemove.add(statement);
        }
      }
      if (statementsToRemove.isNotEmpty) {
        var rangeToRemove = utils.getLinesRangeStatements(statementsToRemove);
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addDeletion(rangeToRemove);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
      }
    } else if (coveringNode is Statement) {
      var rangeToRemove =
          utils.getLinesRangeStatements(<Statement>[coveringNode]);
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(rangeToRemove);
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
    } else if (coveringNode is CatchClause) {
      TryStatement tryStatement = coveringNode.parent;
      var catchClauses = tryStatement.catchClauses;
      var index = catchClauses.indexOf(coveringNode);
      var previous = index == 0 ? tryStatement.body : catchClauses[index - 1];
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.endEnd(previous, coveringNode));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_DEAD_CODE);
    }
  }

  Future<void> _addFix_removeEmptyCatch() async {
    if (node.parent is! CatchClause) {
      return;
    }
    var catchClause = node.parent as CatchClause;

    var tryStatement = catchClause.parent as TryStatement;
    if (tryStatement.catchClauses.length == 1 &&
        tryStatement.finallyBlock == null) {
      return;
    }

    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(utils.getLinesRange(range.node(catchClause)));
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_EMPTY_CATCH);
  }

  Future<void> _addFix_removeEmptyConstructorBody() async {
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          utils.getLinesRange(range.node(node.parent)), ';');
    });
    _addFixFromBuilder(
        changeBuilder, DartFixKind.REMOVE_EMPTY_CONSTRUCTOR_BODY);
  }

  Future<void> _addFix_removeEmptyElse() async {
    IfStatement ifStatement = node.parent;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(utils.getLinesRange(
          range.startEnd(ifStatement.elseKeyword, ifStatement.elseStatement)));
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_EMPTY_ELSE);
  }

  Future<void> _addFix_removeEmptyStatement() async {
    EmptyStatement emptyStatement = node;
    if (emptyStatement.parent is Block) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(utils.getLinesRange(range.node(emptyStatement)));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_EMPTY_STATEMENT);
    } else {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        var previous = emptyStatement.findPrevious(emptyStatement.beginToken);
        if (previous != null) {
          builder.addSimpleReplacement(
              range.endEnd(previous, emptyStatement), ' {}');
        }
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_BRACKETS);
    }
  }

  Future<void> _addFix_removeInitializer() async {
    // Handle formal parameters with default values.
    var parameter = node.thisOrAncestorOfType<DefaultFormalParameter>();
    if (parameter != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(
            range.endEnd(parameter.identifier, parameter.defaultValue));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_INITIALIZER);
      return;
    }
    // Handle variable declarations with default values.
    var variable = node.thisOrAncestorOfType<VariableDeclaration>();
    if (variable != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.endEnd(variable.name, variable.initializer));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_INITIALIZER);
    }
  }

  Future<void> _addFix_removeInterpolationBraces() async {
    var node = this.node;
    if (node is InterpolationExpression) {
      var right = node.rightBracket;
      if (node.expression != null && right != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(
              range.startStart(node, node.expression), r'$');
          builder.addDeletion(range.token(right));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_INTERPOLATION_BRACES);
      } else {}
    }
  }

  Future<void> _addFix_removeMethodDeclaration() async {
    var declaration = node.thisOrAncestorOfType<MethodDeclaration>();
    if (declaration != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(utils.getLinesRange(range.node(declaration)));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_METHOD_DECLARATION);
    }
  }

  Future<void> _addFix_removeNameFromCombinator() async {
    SourceRange rangeForCombinator(Combinator combinator) {
      var parent = combinator.parent;
      if (parent is NamespaceDirective) {
        var combinators = parent.combinators;
        if (combinators.length == 1) {
          var previousToken =
              combinator.parent.findPrevious(combinator.beginToken);
          if (previousToken != null) {
            return range.endEnd(previousToken, combinator);
          }
          return null;
        }
        var index = combinators.indexOf(combinator);
        if (index < 0) {
          return null;
        } else if (index == combinators.length - 1) {
          return range.endEnd(combinators[index - 1], combinator);
        }
        return range.startStart(combinator, combinators[index + 1]);
      }
      return null;
    }

    SourceRange rangeForNameInCombinator(
        Combinator combinator, SimpleIdentifier name) {
      NodeList<SimpleIdentifier> names;
      if (combinator is HideCombinator) {
        names = combinator.hiddenNames;
      } else if (combinator is ShowCombinator) {
        names = combinator.shownNames;
      } else {
        return null;
      }
      if (names.length == 1) {
        return rangeForCombinator(combinator);
      }
      var index = names.indexOf(name);
      if (index < 0) {
        return null;
      } else if (index == names.length - 1) {
        return range.endEnd(names[index - 1], name);
      }
      return range.startStart(name, names[index + 1]);
    }

    var node = coveredNode;
    if (node is SimpleIdentifier) {
      var parent = coveredNode.parent;
      if (parent is Combinator) {
        var rangeToRemove = rangeForNameInCombinator(parent, node);
        if (rangeToRemove == null) {
          return;
        }
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addDeletion(rangeToRemove);
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_NAME_FROM_COMBINATOR,
            args: [parent is HideCombinator ? 'hide' : 'show']);
      }
    }
  }

  Future<void> _addFix_removeNewKeyword() async {
    final instanceCreationExpression = node;
    if (instanceCreationExpression is InstanceCreationExpression) {
      final newToken = instanceCreationExpression.keyword;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(newToken, newToken.next));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNNECESSARY_NEW);
    }
  }

  Future<void> _addFix_removeOperator() async {
    if (node is BinaryExpression) {
      var expression = node as BinaryExpression;
      var operator = expression.operator;
      var rightOperand = expression.rightOperand;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(operator, rightOperand));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_OPERATOR);
    }
  }

  Future<void> _addFix_removeParameters_inGetterDeclaration() async {
    if (node is MethodDeclaration) {
      // Support for the analyzer error.
      var method = node as MethodDeclaration;
      var name = method.name;
      var body = method.body;
      if (name != null && body != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(range.endStart(name, body), ' ');
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION);
      }
    } else if (node is FormalParameterList) {
      // Support for the fasta error.
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.node(node));
      });
      _addFixFromBuilder(
          changeBuilder, DartFixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION);
    }
  }

  Future<void> _addFix_removeParentheses_inGetterInvocation() async {
    var invocation = coveredNode?.parent;
    if (invocation is FunctionExpressionInvocation) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.node(invocation.argumentList));
      });
      _addFixFromBuilder(
          changeBuilder, DartFixKind.REMOVE_PARENTHESIS_IN_GETTER_INVOCATION);
    }
  }

  Future<void> _addFix_removeThisExpression() async {
    if (node is ConstructorFieldInitializer) {
      var initializer = node as ConstructorFieldInitializer;
      var thisKeyword = initializer.thisKeyword;
      if (thisKeyword != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          var fieldName = initializer.fieldName;
          builder.addDeletion(range.startStart(thisKeyword, fieldName));
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_THIS_EXPRESSION);
      }
      return;
    }
    final thisExpression = node is ThisExpression
        ? node
        : node.thisOrAncestorOfType<ThisExpression>();
    final parent = thisExpression?.parent;
    if (parent is PropertyAccess) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startEnd(parent, parent.operator));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_THIS_EXPRESSION);
    } else if (parent is MethodInvocation) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startEnd(parent, parent.operator));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_THIS_EXPRESSION);
    }
  }

  Future<void> _addFix_removeTypeAnnotation() async {
    var type = node.thisOrAncestorOfType<TypeAnnotation>();
    if (type != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(type, type.endToken.next));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_TYPE_ANNOTATION);
    }
  }

  Future<void> _addFix_removeTypeArguments() async {
    if (coveredNode is TypeArgumentList) {
      TypeArgumentList typeArguments = coveredNode;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.node(typeArguments));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_TYPE_ARGUMENTS);
    }
  }

  Future<void> _addFix_removeUnnecessaryCast() async {
    if (coveredNode is! AsExpression) {
      return;
    }
    var asExpression = coveredNode as AsExpression;
    var expression = asExpression.expression;
    var expressionPrecedence = getExpressionPrecedence(expression);
    // remove 'as T' from 'e as T'
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(range.endEnd(expression, asExpression));
      _removeEnclosingParentheses(builder, asExpression, expressionPrecedence);
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNNECESSARY_CAST);
  }

  Future<void> _addFix_removeUnusedCatchClause() async {
    if (node is SimpleIdentifier) {
      var catchClause = node.parent;
      if (catchClause is CatchClause &&
          catchClause.exceptionParameter == node) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addDeletion(
              range.startStart(catchClause.catchKeyword, catchClause.body));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_UNUSED_CATCH_CLAUSE);
      }
    }
  }

  Future<void> _addFix_removeUnusedCatchStack() async {
    if (node is SimpleIdentifier) {
      var catchClause = node.parent;
      if (catchClause is CatchClause &&
          catchClause.stackTraceParameter == node &&
          catchClause.exceptionParameter != null) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder
              .addDeletion(range.endEnd(catchClause.exceptionParameter, node));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REMOVE_UNUSED_CATCH_STACK);
      }
    }
  }

  Future<void> _addFix_removeUnusedImport() async {
    // prepare ImportDirective
    var importDirective = node.thisOrAncestorOfType<ImportDirective>();
    if (importDirective == null) {
      return;
    }
    // remove the whole line with import
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(utils.getLinesRange(range.node(importDirective)));
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNUSED_IMPORT);
  }

  Future<void> _addFix_removeUnusedLabel() async {
    final parent = node.parent;
    if (parent is Label) {
      var nextToken = parent.endToken.next;
      final changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addDeletion(range.startStart(parent, nextToken));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REMOVE_UNUSED_LABEL);
    }
  }

  Future<void> _addFix_renameToCamelCase() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier identifier = node;

    // Prepare the new name.
    var words = identifier.name.split('_');
    if (words.length < 2) {
      return;
    }
    var newName = words.first + words.skip(1).map((w) => capitalize(w)).join();

    // Find references to the identifier.
    List<SimpleIdentifier> references;
    var element = identifier.staticElement;
    if (element is LocalVariableElement) {
      AstNode root = node.thisOrAncestorOfType<Block>();
      references = findLocalElementReferences(root, element);
    } else if (element is ParameterElement) {
      if (!element.isNamed) {
        var root = node.thisOrAncestorMatching((node) =>
            node.parent is ClassOrMixinDeclaration ||
            node.parent is CompilationUnit);
        references = findLocalElementReferences(root, element);
      }
    }
    if (references == null) {
      return;
    }

    // Compute the change.
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      for (var reference in references) {
        builder.addSimpleReplacement(range.node(reference), newName);
      }
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.RENAME_TO_CAMEL_CASE,
        args: [newName]);
  }

  Future<void> _addFix_replaceColonWithEquals() async {
    if (node is DefaultFormalParameter) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(
            range.token((node as DefaultFormalParameter).separator), ' =');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_COLON_WITH_EQUALS);
    }
  }

  Future<void> _addFix_replaceFinalWithConst() async {
    if (node is VariableDeclarationList) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(
            range.token((node as VariableDeclarationList).keyword), 'const');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_FINAL_WITH_CONST);
    }
  }

  Future<void> _addFix_replaceNullWithClosure() async {
    var nodeToFix;
    var parameters = const <ParameterElement>[];
    if (coveredNode is NamedExpression) {
      NamedExpression namedExpression = coveredNode;
      var expression = namedExpression.expression;
      if (expression is NullLiteral) {
        var element = namedExpression.element;
        if (element is ParameterElement) {
          var type = element.type;
          if (type is FunctionType) {
            parameters = type.parameters;
          }
        }
        nodeToFix = expression;
      }
    } else if (coveredNode is NullLiteral) {
      nodeToFix = coveredNode;
    }

    if (nodeToFix != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(range.node(nodeToFix),
            (DartEditBuilder builder) {
          builder.writeParameters(parameters);
          builder.write(' => null');
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_NULL_WITH_CLOSURE);
    }
  }

  Future<void> _addFix_replaceVarWithDynamic() async {
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.error(error), 'dynamic');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_VAR_WITH_DYNAMIC);
  }

  Future<void> _addFix_replaceWithConditionalAssignment() async {
    IfStatement ifStatement =
        node is IfStatement ? node : node.thisOrAncestorOfType<IfStatement>();
    if (ifStatement == null) {
      return;
    }
    var thenStatement = ifStatement.thenStatement;
    Statement uniqueStatement(Statement statement) {
      if (statement is Block) {
        return uniqueStatement(statement.statements.first);
      }
      return statement;
    }

    thenStatement = uniqueStatement(thenStatement);
    if (thenStatement is ExpressionStatement) {
      final expression = thenStatement.expression.unParenthesized;
      if (expression is AssignmentExpression) {
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addReplacement(range.node(ifStatement),
              (DartEditBuilder builder) {
            builder.write(utils.getNodeText(expression.leftHandSide));
            builder.write(' ??= ');
            builder.write(utils.getNodeText(expression.rightHandSide));
            builder.write(';');
          });
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT);
      }
    }
  }

  Future<void> _addFix_replaceWithConstInstanceCreation() async {
    if (coveredNode is InstanceCreationExpression) {
      var instanceCreation = coveredNode as InstanceCreationExpression;
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        if (instanceCreation.keyword == null) {
          builder.addSimpleInsertion(
              instanceCreation.constructorName.offset, 'const');
        } else {
          builder.addSimpleReplacement(
              range.token(instanceCreation.keyword), 'const');
        }
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.USE_CONST);
    }
  }

  Future<void> _addFix_replaceWithExtensionName() async {
    if (node is! SimpleIdentifier) {
      return;
    }
    var parent = node.parent;
    AstNode target;
    if (parent is MethodInvocation && node == parent.methodName) {
      target = parent.target;
    } else if (parent is PropertyAccess && node == parent.propertyName) {
      target = parent.target;
    }
    if (target is! ExtensionOverride) {
      return;
    }
    ExtensionOverride override = target;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
          range.node(override), utils.getNodeText(override.extensionName));
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_EXTENSION_NAME,
        args: [override.extensionName.name]);
  }

  Future<void> _addFix_replaceWithIdentifier() async {
    var functionTyped =
        node.thisOrAncestorOfType<FunctionTypedFormalParameter>();
    if (functionTyped != null) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(range.node(functionTyped),
            utils.getNodeText(functionTyped.identifier));
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_IDENTIFIER);
    } else {
      await _addFix_removeTypeAnnotation();
    }
  }

  Future<void> _addFix_replaceWithIsEmpty() async {
    /// Return the value of an integer literal or prefix expression with a
    /// minus and then an integer literal. For anything else, returns `null`.
    int getIntValue(Expression expressions) {
      // Copied from package:linter/src/rules/prefer_is_empty.dart.
      if (expressions is IntegerLiteral) {
        return expressions.value;
      } else if (expressions is PrefixExpression) {
        var operand = expressions.operand;
        if (expressions.operator.type == TokenType.MINUS &&
            operand is IntegerLiteral) {
          return -operand.value;
        }
      }
      return null;
    }

    /// Return the expression producing the object on which `length` is being
    /// invoked, or `null` if there is no such expression.
    Expression getLengthTarget(Expression expression) {
      if (expression is PropertyAccess &&
          expression.propertyName.name == 'length') {
        return expression.target;
      } else if (expression is PrefixedIdentifier &&
          expression.identifier.name == 'length') {
        return expression.prefix;
      }
      return null;
    }

    var binary = node.thisOrAncestorOfType<BinaryExpression>();
    var operator = binary.operator.type;
    String getter;
    FixKind kind;
    Expression lengthTarget;
    var rightValue = getIntValue(binary.rightOperand);
    if (rightValue != null) {
      lengthTarget = getLengthTarget(binary.leftOperand);
      if (rightValue == 0) {
        if (operator == TokenType.EQ_EQ || operator == TokenType.LT_EQ) {
          getter = 'isEmpty';
          kind = DartFixKind.REPLACE_WITH_IS_EMPTY;
        } else if (operator == TokenType.GT || operator == TokenType.BANG_EQ) {
          getter = 'isNotEmpty';
          kind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
        }
      } else if (rightValue == 1) {
        // 'length >= 1' is same as 'isNotEmpty',
        // and 'length < 1' is same as 'isEmpty'
        if (operator == TokenType.GT_EQ) {
          getter = 'isNotEmpty';
          kind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
        } else if (operator == TokenType.LT) {
          getter = 'isEmpty';
          kind = DartFixKind.REPLACE_WITH_IS_EMPTY;
        }
      }
    } else {
      var leftValue = getIntValue(binary.leftOperand);
      if (leftValue != null) {
        lengthTarget = getLengthTarget(binary.rightOperand);
        if (leftValue == 0) {
          if (operator == TokenType.EQ_EQ || operator == TokenType.GT_EQ) {
            getter = 'isEmpty';
            kind = DartFixKind.REPLACE_WITH_IS_EMPTY;
          } else if (operator == TokenType.LT ||
              operator == TokenType.BANG_EQ) {
            getter = 'isNotEmpty';
            kind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
          }
        } else if (leftValue == 1) {
          // '1 <= length' is same as 'isNotEmpty',
          // and '1 > length' is same as 'isEmpty'
          if (operator == TokenType.LT_EQ) {
            getter = 'isNotEmpty';
            kind = DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;
          } else if (operator == TokenType.GT) {
            getter = 'isEmpty';
            kind = DartFixKind.REPLACE_WITH_IS_EMPTY;
          }
        }
      }
    }
    if (lengthTarget == null || getter == null || kind == null) {
      return;
    }
    var target = utils.getNodeText(lengthTarget);
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.node(binary), '$target.$getter');
    });
    _addFixFromBuilder(changeBuilder, kind);
  }

  Future<void> _addFix_replaceWithRethrow() async {
    if (coveredNode is ThrowExpression) {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(range.node(coveredNode), 'rethrow');
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.USE_RETHROW);
    }
  }

  Future<void> _addFix_replaceWithTearOff() async {
    var ancestor = node.thisOrAncestorOfType<FunctionExpression>();
    if (ancestor == null) {
      return;
    }
    Future<void> addFixOfExpression(InvocationExpression expression) async {
      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addReplacement(range.node(ancestor), (DartEditBuilder builder) {
          if (expression is MethodInvocation && expression.target != null) {
            builder.write(utils.getNodeText(expression.target));
            builder.write('.');
          }
          builder.write(utils.getNodeText(expression.function));
        });
      });
      _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_WITH_TEAR_OFF);
    }

    final body = ancestor.body;
    if (body is ExpressionFunctionBody) {
      final expression = body.expression;
      await addFixOfExpression(expression.unParenthesized);
    } else if (body is BlockFunctionBody) {
      final statement = body.block.statements.first;
      if (statement is ExpressionStatement) {
        final expression = statement.expression;
        await addFixOfExpression(expression.unParenthesized);
      } else if (statement is ReturnStatement) {
        final expression = statement.expression;
        await addFixOfExpression(expression.unParenthesized);
      }
    }
  }

  Future<void> _addFix_sortDirectives() async {
    var organizer =
        DirectiveOrganizer(resolvedResult.content, unit, resolvedResult.errors);

    var changeBuilder = _newDartChangeBuilder();
    // todo (pq): consider restructuring organizer to allow a passed-in change builder
    for (var edit in organizer.organize()) {
      await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
        builder.addSimpleReplacement(
            SourceRange(edit.offset, edit.length), edit.replacement);
      });
    }
    _addFixFromBuilder(changeBuilder, DartFixKind.SORT_DIRECTIVES);
  }

  Future<void> _addFix_undefinedClass_useSimilar() async {
    var node = this.node;
    // Prepare the optional import prefix name.
    String prefixName;
    if (node is SimpleIdentifier && node.staticElement is PrefixElement) {
      var parent = node.parent;
      if (parent is PrefixedIdentifier &&
          parent.prefix == node &&
          parent.parent is TypeName) {
        prefixName = (node as SimpleIdentifier).name;
        node = parent.identifier;
      }
    }
    // Process if looks like a type.
    if (_mayBeTypeIdentifier(node)) {
      // Prepare for selecting the closest element.
      var name = (node as SimpleIdentifier).name;
      var finder = _ClosestElementFinder(
          name,
          (Element element) => element is ClassElement,
          MAX_LEVENSHTEIN_DISTANCE);
      // Check elements of this library.
      if (prefixName == null) {
        for (var unit in unitLibraryElement.units) {
          finder._updateList(unit.types);
        }
      }
      // Check elements from imports.
      for (var importElement in unitLibraryElement.imports) {
        if (importElement.prefix?.name == prefixName) {
          var namespace = getImportNamespace(importElement);
          finder._updateList(namespace.values);
        }
      }
      // If we have a close enough element, suggest to use it.
      if (finder._element != null) {
        var closestName = finder._element.name;
        if (closestName != null) {
          var changeBuilder = _newDartChangeBuilder();
          await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
            builder.addSimpleReplacement(range.node(node), closestName);
          });
          _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_TO,
              args: [closestName]);
        }
      }
    }
  }

  Future<void> _addFix_undefinedClassAccessor_useSimilar() async {
    var node = this.node;
    if (node is SimpleIdentifier) {
      // prepare target
      Expression target;
      if (node.parent is PrefixedIdentifier) {
        target = (node.parent as PrefixedIdentifier).prefix;
      } else if (node.parent is PropertyAccess) {
        target = (node.parent as PropertyAccess).target;
      }
      // find getter
      if (node.inGetterContext()) {
        await _addFix_undefinedClassMember_useSimilar(target,
            (Element element) {
          return element is PropertyAccessorElement && element.isGetter ||
              element is FieldElement && element.getter != null;
        });
      }
      // find setter
      if (node.inSetterContext()) {
        await _addFix_undefinedClassMember_useSimilar(target,
            (Element element) {
          return element is PropertyAccessorElement && element.isSetter ||
              element is FieldElement && element.setter != null;
        });
      }
    }
  }

  Future<void> _addFix_undefinedClassMember_useSimilar(
      Expression target, ElementPredicate predicate) async {
    if (node is SimpleIdentifier) {
      var name = (node as SimpleIdentifier).name;
      var finder =
          _ClosestElementFinder(name, predicate, MAX_LEVENSHTEIN_DISTANCE);
      // unqualified invocation
      if (target == null) {
        var clazz = node.thisOrAncestorOfType<ClassDeclaration>();
        if (clazz != null) {
          var classElement = clazz.declaredElement;
          _updateFinderWithClassMembers(finder, classElement);
        }
      } else if (target is ExtensionOverride) {
        _updateFinderWithExtensionMembers(finder, target.staticElement);
      } else if (target is Identifier &&
          target.staticElement is ExtensionElement) {
        _updateFinderWithExtensionMembers(finder, target.staticElement);
      } else {
        var classElement = _getTargetClassElement(target);
        if (classElement != null) {
          _updateFinderWithClassMembers(finder, classElement);
        }
      }
      // if we have close enough element, suggest to use it
      if (finder._element != null) {
        var closestName = finder._element.displayName;
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(range.node(node), closestName);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_TO,
            args: [closestName]);
      }
    }
  }

  Future<void> _addFix_undefinedFunction_create() async {
    // should be the name of the invocation
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
    } else {
      return;
    }
    var name = (node as SimpleIdentifier).name;
    var invocation = node.parent as MethodInvocation;
    // function invocation has no target
    var target = invocation.realTarget;
    if (target != null) {
      return;
    }
    // prepare environment
    int insertOffset;
    String sourcePrefix;
    AstNode enclosingMember =
        node.thisOrAncestorOfType<CompilationUnitMember>();
    insertOffset = enclosingMember.end;
    sourcePrefix = '$eol$eol';
    utils.targetClassElement = null;
    // build method source
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addInsertion(insertOffset, (DartEditBuilder builder) {
        builder.write(sourcePrefix);
        // append return type
        {
          var type = _inferUndefinedExpressionType(invocation);
          if (builder.writeType(type, groupName: 'RETURN_TYPE')) {
            builder.write(' ');
          }
        }
        // append name
        builder.addLinkedEdit('NAME', (DartLinkedEditBuilder builder) {
          builder.write(name);
        });
        builder.write('(');
        builder.writeParametersMatchingArguments(invocation.argumentList);
        builder.write(') {$eol}');
      });
      builder.addLinkedPosition(range.node(node), 'NAME');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FUNCTION,
        args: [name]);
  }

  Future<void> _addFix_undefinedFunction_useSimilar() async {
    var node = this.node;
    if (node is SimpleIdentifier) {
      // Prepare the optional import prefix name.
      String prefixName;
      {
        var invocation = node.parent;
        if (invocation is MethodInvocation && invocation.methodName == node) {
          var target = invocation.target;
          if (target is SimpleIdentifier &&
              target.staticElement is PrefixElement) {
            prefixName = target.name;
          }
        }
      }
      // Prepare for selecting the closest element.
      var finder = _ClosestElementFinder(
          node.name,
          (Element element) => element is FunctionElement,
          MAX_LEVENSHTEIN_DISTANCE);
      // Check to this library units.
      if (prefixName == null) {
        for (var unit in unitLibraryElement.units) {
          finder._updateList(unit.functions);
        }
      }
      // Check unprefixed imports.
      for (var importElement in unitLibraryElement.imports) {
        if (importElement.prefix?.name == prefixName) {
          var namespace = getImportNamespace(importElement);
          finder._updateList(namespace.values);
        }
      }
      // If we have a close enough element, suggest to use it.
      if (finder._element != null) {
        var closestName = finder._element.name;
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          builder.addSimpleReplacement(range.node(node), closestName);
        });
        _addFixFromBuilder(changeBuilder, DartFixKind.CHANGE_TO,
            args: [closestName]);
      }
    }
  }

  Future<void> _addFix_undefinedMethod_useSimilar() async {
    if (node.parent is MethodInvocation) {
      var invocation = node.parent as MethodInvocation;
      await _addFix_undefinedClassMember_useSimilar(invocation.realTarget,
          (Element element) => element is MethodElement && !element.isOperator);
    }
  }

  Future<void> _addFix_updateSdkConstraints(String minimumVersion) async {
    var context = resourceProvider.pathContext;
    File pubspecFile;
    var folder = resourceProvider.getFolder(context.dirname(file));
    while (folder != null) {
      pubspecFile = folder.getChildAssumingFile('pubspec.yaml');
      if (pubspecFile.exists) {
        break;
      }
      pubspecFile = null;
      folder = folder.parent;
    }
    if (pubspecFile == null) {
      return;
    }
    var extractor = SdkConstraintExtractor(pubspecFile);
    var text = extractor.constraintText();
    var offset = extractor.constraintOffset();
    if (text == null || offset < 0) {
      return;
    }
    var length = text.length;
    String newText;
    var spaceOffset = text.indexOf(' ');
    if (spaceOffset >= 0) {
      length = spaceOffset;
    }
    if (text == 'any') {
      newText = '^$minimumVersion';
    } else if (text.startsWith('^')) {
      newText = '^$minimumVersion';
    } else if (text.startsWith('>=')) {
      newText = '>=$minimumVersion';
    } else if (text.startsWith('>')) {
      newText = '>=$minimumVersion';
    }
    if (newText == null) {
      return;
    }
    var changeBuilder = ChangeBuilder();
    await changeBuilder.addFileEdit(pubspecFile.path, (builder) {
      builder.addSimpleReplacement(SourceRange(offset, length), newText);
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.UPDATE_SDK_CONSTRAINTS);
  }

  Future<void> _addFix_useEffectiveIntegerDivision() async {
    for (var n = node; n != null; n = n.parent) {
      if (n is MethodInvocation &&
          n.offset == errorOffset &&
          n.length == errorLength) {
        var target = (n as MethodInvocation).target.unParenthesized;
        var changeBuilder = _newDartChangeBuilder();
        await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
          // replace "/" with "~/"
          var binary = target as BinaryExpression;
          builder.addSimpleReplacement(range.token(binary.operator), '~/');
          // remove everything before and after
          builder.addDeletion(range.startStart(n, binary.leftOperand));
          builder.addDeletion(range.endEnd(binary.rightOperand, n));
        });
        _addFixFromBuilder(
            changeBuilder, DartFixKind.USE_EFFECTIVE_INTEGER_DIVISION);
        // done
        break;
      }
    }
  }

  /// Adds a fix that replaces [target] with a reference to the class declaring
  /// the given [element].
  Future<void> _addFix_useStaticAccess(AstNode target, Element element) async {
    var declaringElement = element.enclosingElement;
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(target), (DartEditBuilder builder) {
        builder.writeReference(declaringElement);
      });
    });
    _addFixFromBuilder(
      changeBuilder,
      DartFixKind.CHANGE_TO_STATIC_ACCESS,
      args: [declaringElement.name],
    );
  }

  Future<void> _addFix_useStaticAccess_method() async {
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      var invocation = node.parent as MethodInvocation;
      if (invocation.methodName == node) {
        var target = invocation.target;
        var invokedElement = invocation.methodName.staticElement;
        await _addFix_useStaticAccess(target, invokedElement);
      }
    }
  }

  Future<void> _addFix_useStaticAccess_property() async {
    if (node is SimpleIdentifier && node.parent is PrefixedIdentifier) {
      var prefixed = node.parent as PrefixedIdentifier;
      if (prefixed.identifier == node) {
        Expression target = prefixed.prefix;
        var invokedElement = prefixed.identifier.staticElement;
        await _addFix_useStaticAccess(target, invokedElement);
      }
    }
  }

  void _addFixFromBuilder(ChangeBuilder builder, FixKind kind,
      {List<Object> args, bool importsOnly = false}) {
    if (builder == null) return;
    var change = builder.sourceChange;
    if (change.edits.isEmpty && !importsOnly) {
      return;
    }
    change.id = kind.id;
    change.message = formatList(kind.message, args);
    fixes.add(Fix(kind, change));
  }

  Future<void> _addFromProducers() async {
    var context = CorrectionProducerContext(
      diagnostic: error,
      resolvedResult: resolvedResult,
      selectionOffset: errorOffset,
      selectionLength: errorLength,
      workspace: workspace,
    );

    var setupSuccess = context.setupCompute();
    if (!setupSuccess) {
      return;
    }

    Future<void> compute(CorrectionProducer producer) async {
      producer.configure(context);
      var builder = _newDartChangeBuilder();
      await producer.compute(builder);
      _addFixFromBuilder(builder, producer.fixKind,
          args: producer.fixArguments);
    }

    var errorCode = error.errorCode;
    if (errorCode is LintCode) {
      var generators = lintProducerMap[errorCode.name];
      if (generators != null) {
        for (var generator in generators) {
          await compute(generator());
        }
      }
    } else {
      var generators = nonLintProducerMap[errorCode];
      if (generators != null) {
        for (var generator in generators) {
          await compute(generator());
        }
      }
      var multiGenerators = nonLintMultiProducerMap[errorCode];
      if (multiGenerators != null) {
        for (var multiGenerator in multiGenerators) {
          var multiProducer = multiGenerator();
          multiProducer.configure(context);
          for (var producer in multiProducer.producers) {
            await compute(producer);
          }
        }
      }
    }
  }

  /// Prepares proposal for creating function corresponding to the given
  /// [FunctionType].
  Future<DartChangeBuilder> _addProposal_createFunction(
      FunctionType functionType,
      String name,
      String targetFile,
      int insertOffset,
      bool isStatic,
      String prefix,
      String sourcePrefix,
      String sourceSuffix,
      Element target) async {
    // build method source
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(targetFile, (DartFileEditBuilder builder) {
      builder.addInsertion(insertOffset, (DartEditBuilder builder) {
        builder.write(sourcePrefix);
        builder.write(prefix);
        // may be static
        if (isStatic) {
          builder.write('static ');
        }
        // append return type
        if (builder.writeType(functionType.returnType,
            groupName: 'RETURN_TYPE')) {
          builder.write(' ');
        }
        // append name
        builder.addLinkedEdit('NAME', (DartLinkedEditBuilder builder) {
          builder.write(name);
        });
        // append parameters
        builder.writeParameters(functionType.parameters);
        // close method
        builder.write(' {$eol$prefix}');
        builder.write(sourceSuffix);
      });
      if (targetFile == file) {
        builder.addLinkedPosition(range.node(node), 'NAME');
      }
    });
    return changeBuilder;
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] in the given [ClassElement].
  Future<void> _addProposal_createFunction_function(
      FunctionType functionType) async {
    var name = (node as SimpleIdentifier).name;
    // prepare environment
    var insertOffset = unit.end;
    // prepare prefix
    var prefix = '';
    var sourcePrefix = '$eol';
    var sourceSuffix = eol;
    var changeBuilder = await _addProposal_createFunction(
        functionType,
        name,
        file,
        insertOffset,
        false,
        prefix,
        sourcePrefix,
        sourceSuffix,
        unit.declaredElement);
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_FUNCTION,
        args: [name]);
  }

  /// Adds proposal for creating method corresponding to the given
  /// [FunctionType] in the given [ClassElement].
  Future<void> _addProposal_createFunction_method(
      ClassElement targetClassElement, FunctionType functionType) async {
    var name = (node as SimpleIdentifier).name;
    // prepare environment
    var targetSource = targetClassElement.source;
    // prepare insert offset
    var targetNode = await _getClassDeclaration(targetClassElement);
    if (targetNode == null) {
      return;
    }
    var insertOffset = targetNode.end - 1;
    // prepare prefix
    var prefix = '  ';
    String sourcePrefix;
    if (targetNode.members.isEmpty) {
      sourcePrefix = '';
    } else {
      sourcePrefix = eol;
    }
    var sourceSuffix = eol;
    var changeBuilder = await _addProposal_createFunction(
        functionType,
        name,
        targetSource.fullName,
        insertOffset,
        _inStaticContext(),
        prefix,
        sourcePrefix,
        sourceSuffix,
        targetClassElement);
    _addFixFromBuilder(changeBuilder, DartFixKind.CREATE_METHOD, args: [name]);
  }

  /// Return the class, enum or mixin declaration for the given [element].
  Future<ClassOrMixinDeclaration> _getClassDeclaration(
      ClassElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    if (result.node is ClassOrMixinDeclaration) {
      return result.node;
    }
    return null;
  }

  /// Return the string to display as the name of the given constructor in a
  /// proposal name.
  String _getConstructorProposalName(ConstructorElement constructor) {
    var buffer = StringBuffer();
    buffer.write('super');
    var constructorName = constructor.displayName;
    if (constructorName.isNotEmpty) {
      buffer.write('.');
      buffer.write(constructorName);
    }
    buffer.write('(...)');
    return buffer.toString();
  }

  /// Return the extension declaration for the given [element].
  Future<ExtensionDeclaration> _getExtensionDeclaration(
      ExtensionElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    if (result.node is ExtensionDeclaration) {
      return result.node;
    }
    return null;
  }

  /// Return the relative uri from the passed [library] to the given [path].
  /// If the [path] is not in the LibraryElement, `null` is returned.
  String _getRelativeURIFromLibrary(LibraryElement library, String path) {
    var librarySource = library?.librarySource;
    if (librarySource == null) {
      return null;
    }
    var pathCtx = resourceProvider.pathContext;
    var libraryDirectory = pathCtx.dirname(librarySource.fullName);
    var sourceDirectory = pathCtx.dirname(path);
    if (pathCtx.isWithin(libraryDirectory, path) ||
        pathCtx.isWithin(sourceDirectory, libraryDirectory)) {
      var relativeFile = pathCtx.relative(path, from: libraryDirectory);
      return pathCtx.split(relativeFile).join('/');
    }
    return null;
  }

  /// Returns an expected [DartType] of [expression], may be `null` if cannot be
  /// inferred.
  DartType _inferUndefinedExpressionType(Expression expression) {
    var parent = expression.parent;
    // myFunction();
    if (parent is ExpressionStatement) {
      if (expression is MethodInvocation) {
        return VoidTypeImpl.instance;
      }
    }
    // return myFunction();
    if (parent is ReturnStatement) {
      var executable = getEnclosingExecutableElement(expression);
      return executable?.returnType;
    }
    // int v = myFunction();
    if (parent is VariableDeclaration) {
      var variableDeclaration = parent;
      if (variableDeclaration.initializer == expression) {
        var variableElement = variableDeclaration.declaredElement;
        if (variableElement != null) {
          return variableElement.type;
        }
      }
    }
    // myField = 42;
    if (parent is AssignmentExpression) {
      var assignment = parent;
      if (assignment.leftHandSide == expression) {
        var rhs = assignment.rightHandSide;
        if (rhs != null) {
          return rhs.staticType;
        }
      }
    }
    // v = myFunction();
    if (parent is AssignmentExpression) {
      var assignment = parent;
      if (assignment.rightHandSide == expression) {
        if (assignment.operator.type == TokenType.EQ) {
          // v = myFunction();
          var lhs = assignment.leftHandSide;
          if (lhs != null) {
            return lhs.staticType;
          }
        } else {
          // v += myFunction();
          var method = assignment.staticElement;
          if (method != null) {
            var parameters = method.parameters;
            if (parameters.length == 1) {
              return parameters[0].type;
            }
          }
        }
      }
    }
    // v + myFunction();
    if (parent is BinaryExpression) {
      var binary = parent;
      var method = binary.staticElement;
      if (method != null) {
        if (binary.rightOperand == expression) {
          var parameters = method.parameters;
          return parameters.length == 1 ? parameters[0].type : null;
        }
      }
    }
    // foo( myFunction() );
    if (parent is ArgumentList) {
      var parameter = expression.staticParameterElement;
      return parameter?.type;
    }
    // bool
    {
      // assert( myFunction() );
      if (parent is AssertStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // if ( myFunction() ) {}
      if (parent is IfStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // while ( myFunction() ) {}
      if (parent is WhileStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // do {} while ( myFunction() );
      if (parent is DoStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // !myFunction()
      if (parent is PrefixExpression) {
        var prefixExpression = parent;
        if (prefixExpression.operator.type == TokenType.BANG) {
          return coreTypeBool;
        }
      }
      // binary expression '&&' or '||'
      if (parent is BinaryExpression) {
        var binaryExpression = parent;
        var operatorType = binaryExpression.operator.type;
        if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
            operatorType == TokenType.BAR_BAR) {
          return coreTypeBool;
        }
      }
    }
    // we don't know
    return null;
  }

  /// Returns `true` if [node] is in static context.
  bool _inStaticContext() {
    // constructor initializer cannot reference "this"
    if (node.thisOrAncestorOfType<ConstructorInitializer>() != null) {
      return true;
    }
    // field initializer cannot reference "this"
    if (node.thisOrAncestorOfType<FieldDeclaration>() != null) {
      return true;
    }
    // static method
    var method = node.thisOrAncestorOfType<MethodDeclaration>();
    return method != null && method.isStatic;
  }

  bool _isAwaitNode() {
    var node = this.node;
    return node is SimpleIdentifier && node.name == 'await';
  }

  bool _isLibSrcPath(String path) {
    var parts = resourceProvider.pathContext.split(path);
    for (var i = 0; i < parts.length - 2; i++) {
      if (parts[i] == 'lib' && parts[i + 1] == 'src') {
        return true;
      }
    }
    return false;
  }

  DartChangeBuilder _newDartChangeBuilder() {
    return DartChangeBuilderImpl.forWorkspace(context.workspace);
  }

  /// Removes any [ParenthesizedExpression] enclosing [expr].
  ///
  /// [exprPrecedence] - the effective precedence of [expr].
  void _removeEnclosingParentheses(
      DartFileEditBuilder builder, Expression expr, Precedence exprPrecedence) {
    while (expr.parent is ParenthesizedExpression) {
      var parenthesized = expr.parent as ParenthesizedExpression;
      if (getExpressionParentPrecedence(parenthesized) > exprPrecedence) {
        break;
      }
      builder.addDeletion(range.token(parenthesized.leftParenthesis));
      builder.addDeletion(range.token(parenthesized.rightParenthesis));
      expr = parenthesized;
    }
  }

  void _updateFinderWithClassMembers(
      _ClosestElementFinder finder, ClassElement clazz) {
    if (clazz != null) {
      var members = getMembers(clazz);
      finder._updateList(members);
    }
  }

  void _updateFinderWithExtensionMembers(
      _ClosestElementFinder finder, ExtensionElement element) {
    if (element != null) {
      finder._updateList(getExtensionMembers(element));
    }
  }

  static ClassElement _getTargetClassElement(Expression target) {
    var type = target.staticType;
    if (type is InterfaceType) {
      return type.element;
    } else if (target is Identifier) {
      var element = target.staticElement;
      if (element is ClassElement) {
        return element;
      }
    }
    return null;
  }

  static bool _isNameOfType(String name) {
    if (name.isEmpty) {
      return false;
    }
    var firstLetter = name.substring(0, 1);
    if (firstLetter.toUpperCase() != firstLetter) {
      return false;
    }
    return true;
  }

  /// Return `true` if the given [node] is in a location where an implicit
  /// constructor invocation would be allowed.
  static bool _mayBeImplicitConstructor(AstNode node) {
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is MethodInvocation) {
        return parent.realTarget == null;
      }
    }
    return false;
  }

  /// Returns `true` if [node] is a type name.
  static bool _mayBeTypeIdentifier(AstNode node) {
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is TypeName) {
        return true;
      }
      return _isNameOfType(node.name);
    }
    return false;
  }
}

/// Helper for finding [Element] with name closest to the given.
class _ClosestElementFinder {
  final String _targetName;
  final ElementPredicate _predicate;

  Element _element;
  int _distance;

  _ClosestElementFinder(this._targetName, this._predicate, this._distance);

  void _update(Element element) {
    if (_predicate(element)) {
      var memberDistance = levenshtein(element.name, _targetName, _distance);
      if (memberDistance < _distance) {
        _element = element;
        _distance = memberDistance;
      }
    }
  }

  void _updateList(Iterable<Element> elements) {
    for (var element in elements) {
      _update(element);
    }
  }
}

/// [ExecutableElement], its parameters, and operations on them.
class _ExecutableParameters {
  final AnalysisSessionHelper sessionHelper;
  final ExecutableElement executable;

  final List<ParameterElement> required = [];
  final List<ParameterElement> optionalPositional = [];
  final List<ParameterElement> named = [];

  factory _ExecutableParameters(
      AnalysisSessionHelper sessionHelper, AstNode invocation) {
    Element element;
    // This doesn't handle FunctionExpressionInvocation.
    if (invocation is Annotation) {
      element = invocation.element;
    } else if (invocation is InstanceCreationExpression) {
      element = invocation.staticElement;
    } else if (invocation is MethodInvocation) {
      element = invocation.methodName.staticElement;
    } else if (invocation is ConstructorReferenceNode) {
      element = invocation.staticElement;
    }
    if (element is ExecutableElement && !element.isSynthetic) {
      return _ExecutableParameters._(sessionHelper, element);
    } else {
      return null;
    }
  }

  _ExecutableParameters._(this.sessionHelper, this.executable) {
    for (var parameter in executable.parameters) {
      if (parameter.isRequiredPositional) {
        required.add(parameter);
      } else if (parameter.isOptionalPositional) {
        optionalPositional.add(parameter);
      } else if (parameter.isNamed) {
        named.add(parameter);
      }
    }
  }

  String get file => executable.source.fullName;

  List<String> get namedNames {
    return named.map((parameter) => parameter.name).toList();
  }

  /// Return the [FormalParameterList] of the [executable], or `null` is cannot
  /// be found.
  Future<FormalParameterList> getParameterList() async {
    var result = await sessionHelper.getElementDeclaration(executable);
    var targetDeclaration = result.node;
    if (targetDeclaration is ConstructorDeclaration) {
      return targetDeclaration.parameters;
    } else if (targetDeclaration is FunctionDeclaration) {
      var function = targetDeclaration.functionExpression;
      return function.parameters;
    } else if (targetDeclaration is MethodDeclaration) {
      return targetDeclaration.parameters;
    }
    return null;
  }

  /// Return the [FormalParameter] of the [element] in [FormalParameterList],
  /// or `null` is cannot be found.
  Future<FormalParameter> getParameterNode(ParameterElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    var declaration = result.node;
    for (var node = declaration; node != null; node = node.parent) {
      if (node is FormalParameter && node.parent is FormalParameterList) {
        return node;
      }
    }
    return null;
  }
}
