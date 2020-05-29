// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:core';

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
import 'package:analysis_server/src/services/correction/dart/add_missing_parameter_named.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_required_argument.dart';
import 'package:analysis_server/src/services/correction/dart/add_ne_null.dart';
import 'package:analysis_server/src/services/correction/dart/add_override.dart';
import 'package:analysis_server/src/services/correction/dart/add_required.dart';
import 'package:analysis_server/src/services/correction/dart/add_required_keyword.dart';
import 'package:analysis_server/src/services/correction/dart/add_return_type.dart';
import 'package:analysis_server/src/services/correction/dart/add_static.dart';
import 'package:analysis_server/src/services/correction/dart/add_super_constructor_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/add_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/change_argument_name.dart';
import 'package:analysis_server/src/services/correction/dart/change_to_nearest_precise_value.dart';
import 'package:analysis_server/src/services/correction/dart/change_to_static_access.dart';
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
import 'package:analysis_server/src/services/correction/dart/create_class.dart';
import 'package:analysis_server/src/services/correction/dart/create_constructor_for_final_fields.dart';
import 'package:analysis_server/src/services/correction/dart/create_constructor_super.dart';
import 'package:analysis_server/src/services/correction/dart/create_getter.dart';
import 'package:analysis_server/src/services/correction/dart/create_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/create_method.dart';
import 'package:analysis_server/src/services/correction/dart/create_missing_overrides.dart';
import 'package:analysis_server/src/services/correction/dart/create_mixin.dart';
import 'package:analysis_server/src/services/correction/dart/create_no_such_method.dart';
import 'package:analysis_server/src/services/correction/dart/create_setter.dart';
import 'package:analysis_server/src/services/correction/dart/extend_class_for_mixin.dart';
import 'package:analysis_server/src/services/correction/dart/inline_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/inline_typedef.dart';
import 'package:analysis_server/src/services/correction/dart/insert_semicolon.dart';
import 'package:analysis_server/src/services/correction/dart/make_class_abstract.dart';
import 'package:analysis_server/src/services/correction/dart/make_field_not_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_variable_not_final.dart';
import 'package:analysis_server/src/services/correction/dart/move_type_arguments_to_class.dart';
import 'package:analysis_server/src/services/correction/dart/qualify_reference.dart';
import 'package:analysis_server/src/services/correction/dart/remove_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_argument.dart';
import 'package:analysis_server/src/services/correction/dart/remove_await.dart';
import 'package:analysis_server/src/services/correction/dart/remove_const.dart';
import 'package:analysis_server/src/services/correction/dart/remove_dead_code.dart';
import 'package:analysis_server/src/services/correction/dart/remove_dead_if_null.dart';
import 'package:analysis_server/src/services/correction/dart/remove_duplicate_case.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_catch.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_constructor_body.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_else.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_statement.dart';
import 'package:analysis_server/src/services/correction/dart/remove_if_null_operator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_initializer.dart';
import 'package:analysis_server/src/services/correction/dart/remove_interpolation_braces.dart';
import 'package:analysis_server/src/services/correction/dart/remove_method_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/remove_name_from_combinator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_operator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_parameters_in_getter_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/remove_parentheses_in_getter_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_question_mark.dart';
import 'package:analysis_server/src/services/correction/dart/remove_this_expression.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_arguments.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_cast.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_new.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_catch_clause.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_catch_stack.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_import.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_label.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/rename_to_camel_case.dart';
import 'package:analysis_server/src/services/correction/dart/replace_boolean_with_bool.dart';
import 'package:analysis_server/src/services/correction/dart/replace_colon_with_equals.dart';
import 'package:analysis_server/src/services/correction/dart/replace_final_with_const.dart';
import 'package:analysis_server/src/services/correction/dart/replace_new_with_const.dart';
import 'package:analysis_server/src/services/correction/dart/replace_null_with_closure.dart';
import 'package:analysis_server/src/services/correction/dart/replace_return_type_future.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_brackets.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_conditional_assignment.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_eight_digit_hex.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_extension_name.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_identifier.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_interpolation.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_is_empty.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_tear_off.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/sort_child_property_last.dart';
import 'package:analysis_server/src/services/correction/dart/sort_directives.dart';
import 'package:analysis_server/src/services/correction/dart/use_const.dart';
import 'package:analysis_server/src/services/correction/dart/use_curly_braces.dart';
import 'package:analysis_server/src/services/correction/dart/use_effective_integer_division.dart';
import 'package:analysis_server/src/services/correction/dart/use_eq_eq_null.dart';
import 'package:analysis_server/src/services/correction/dart/use_is_not_empty.dart';
import 'package:analysis_server/src/services/correction/dart/use_not_eq_null.dart';
import 'package:analysis_server/src/services/correction/dart/use_rethrow.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_future.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_text.dart';
import 'package:analysis_server/src/services/correction/executable_parameters.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/levenshtein.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError, Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
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
    LintNames.avoid_annotating_with_dynamic: [
      RemoveTypeAnnotation.newInstance,
    ],
    LintNames.avoid_empty_else: [
      RemoveEmptyElse.newInstance,
    ],
    LintNames.avoid_init_to_null: [
      RemoveInitializer.newInstance,
    ],
    LintNames.avoid_private_typedef_functions: [
      InlineTypedef.newInstance,
    ],
    LintNames.avoid_redundant_argument_values: [
      RemoveArgument.newInstance,
    ],
    LintNames.avoid_relative_lib_imports: [
      ConvertToPackageImport.newInstance,
    ],
    LintNames.avoid_return_types_on_setters: [
      RemoveTypeAnnotation.newInstance,
    ],
    LintNames.avoid_returning_null_for_future: [
      AddSync.newInstance,
      WrapInFuture.newInstance,
    ],
    LintNames.avoid_types_as_parameter_names: [
      ConvertToOnType.newInstance,
    ],
    LintNames.avoid_types_on_closure_parameters: [
      ReplaceWithIdentifier.newInstance,
      RemoveTypeAnnotation.newInstance,
    ],
    LintNames.avoid_unused_constructor_parameters: [
      RemoveUnusedParameter.newInstance,
    ],
    LintNames.await_only_futures: [
      RemoveAwait.newInstance,
    ],
    LintNames.curly_braces_in_flow_control_structures: [
      UseCurlyBraces.newInstance,
    ],
    LintNames.diagnostic_describe_all_properties: [
      AddDiagnosticPropertyReference.newInstance,
    ],
    LintNames.directives_ordering: [
      SortDirectives.newInstance,
    ],
    LintNames.empty_catches: [
      RemoveEmptyCatch.newInstance,
    ],
    LintNames.empty_constructor_bodies: [
      RemoveEmptyConstructorBody.newInstance,
    ],
    LintNames.empty_statements: [
      RemoveEmptyStatement.newInstance,
      ReplaceWithBrackets.newInstance,
    ],
    LintNames.hash_and_equals: [
      CreateMethod.newInstance,
    ],
    LintNames.no_duplicate_case_values: [
      RemoveDuplicateCase.newInstance,
    ],
    LintNames.non_constant_identifier_names: [
      RenameToCamelCase.newInstance,
    ],
    LintNames.null_closures: [
      ReplaceNullWithClosure.newInstance,
    ],
    LintNames.omit_local_variable_types: [
      ReplaceWithVar.newInstance,
    ],
    LintNames.prefer_adjacent_string_concatenation: [
      RemoveOperator.newInstance,
    ],
    LintNames.prefer_collection_literals: [
      ConvertToListLiteral.newInstance,
      ConvertToMapLiteral.newInstance,
      ConvertToSetLiteral.newInstance,
    ],
    LintNames.prefer_conditional_assignment: [
      ReplaceWithConditionalAssignment.newInstance,
    ],
    LintNames.prefer_const_constructors: [
      AddConst.newInstance,
      ReplaceNewWithConst.newInstance,
    ],
    LintNames.prefer_const_constructors_in_immutables: [
      AddConst.newInstance,
    ],
    LintNames.prefer_const_declarations: [
      ReplaceFinalWithConst.newInstance,
    ],
    LintNames.prefer_contains: [
      ConvertToContains.newInstance,
    ],
    LintNames.prefer_equal_for_default_values: [
      ReplaceColonWithEquals.newInstance,
    ],
    LintNames.prefer_expression_function_bodies: [
      ConvertToExpressionFunctionBody.newInstance,
    ],
    LintNames.prefer_final_fields: [
      MakeFinal.newInstance,
    ],
    LintNames.prefer_final_locals: [
      MakeFinal.newInstance,
    ],
    LintNames.prefer_for_elements_to_map_fromIterable: [
      ConvertMapFromIterableToForLiteral.newInstance,
    ],
    LintNames.prefer_generic_function_type_aliases: [
      ConvertToGenericFunctionSyntax.newInstance,
    ],
    LintNames.prefer_if_elements_to_conditional_expressions: [
      ConvertConditionalExpressionToIfElement.newInstance,
    ],
    LintNames.prefer_is_empty: [
      ReplaceWithIsEmpty.newInstance,
    ],
    LintNames.prefer_is_not_empty: [
      UesIsNotEmpty.newInstance,
    ],
    LintNames.prefer_if_null_operators: [
      ConvertToIfNull.newInstance,
    ],
    LintNames.prefer_inlined_adds: [
      ConvertAddAllToSpread.newInstance,
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
    LintNames.type_init_formals: [
      RemoveTypeAnnotation.newInstance,
    ],
    LintNames.unawaited_futures: [
      AddAwait.newInstance,
    ],
    LintNames.unnecessary_brace_in_string_interps: [
      RemoveInterpolationBraces.newInstance,
    ],
    LintNames.unnecessary_const: [
      RemoveUnnecesaryConst.newInstance,
    ],
    LintNames.unnecessary_lambdas: [
      ReplaceWithTearOff.newInstance,
    ],
    LintNames.unnecessary_new: [
      RemoveUnnecessaryNew.newInstance,
    ],
    LintNames.unnecessary_null_in_if_null_operators: [
      RemoveIfNullOperator.newInstance,
    ],
    LintNames.unnecessary_overrides: [
      RemoveMethodDeclaration.newInstance,
    ],
    LintNames.unnecessary_this: [
      RemoveThisExpression.newInstance,
    ],
    LintNames.use_full_hex_values_for_flutter_colors: [
      ReplaceWithEightDigitHex.newInstance,
    ],
    LintNames.use_function_type_syntax_for_parameters: [
      ConvertToGenericFunctionSyntax.newInstance,
    ],
    LintNames.use_rethrow_when_possible: [
      UseRethrow.newInstance,
    ],
  };

  /// A map from error codes to a list of generators used to create multiple
  /// correction producers used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintMultiProducerMap].
  static const Map<ErrorCode, List<MultiProducerGenerator>>
      nonLintMultiProducerMap = {
    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT: [
      AddSuperConstructorInvocation.newInstance,
    ],
    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT: [
      AddSuperConstructorInvocation.newInstance,
      CreateConstructorSuper.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT: [
      AddSuperConstructorInvocation.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      ChangeArgumentName.newInstance,
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
    CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE: [
      UseConst.newInstance,
    ],
    CompileTimeErrorCode.CONST_INSTANCE_FIELD: [
      AddStatic.newInstance,
    ],
    CompileTimeErrorCode.CONST_WITH_NON_CONST: [
      RemoveConst.newInstance,
    ],
    CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER: [
      ReplaceWithExtensionName.newInstance,
    ],
//    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS : [],
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
      ConvertToNamedArguments.newInstance,
    ],
//    CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD : [],
    CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE: [
      ChangeToNearestPreciseValue.newInstance,
    ],
    CompileTimeErrorCode.INVALID_ANNOTATION: [
      CreateClass.newInstance,
    ],
    CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER: [
      AddRequiredKeyword.newInstance,
    ],
    CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE: [
      ExtendClassForMixin.newInstance,
    ],
//    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT : [],
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
    CompileTimeErrorCode.UNDEFINED_ANNOTATION: [
      CreateClass.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_CLASS: [
      CreateClass.newInstance,
      CreateMixin.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER: [
      CreateGetter.newInstance,
    ],
//    CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD : [],
    CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER: [
      CreateSetter.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      AddMissingParameterNamed.newInstance,
      ConvertFlutterChild.newInstance,
      ConvertFlutterChildren.newInstance,
    ],
    CompileTimeErrorCode
        .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE: [
      // TODO(brianwilkerson) Consider adding fixes to create a field, getter,
      //  method or setter. The existing _addFix methods would need to be
      //  updated so that only the appropriate subset is generated.
      QualifyReference.newInstance,
    ],
//    CompileTimeErrorCode.URI_DOES_NOT_EXIST : [],

    HintCode.CAN_BE_NULL_AFTER_NULL_AWARE: [
      ReplaceWithNullAware.newInstance,
    ],
    HintCode.DEAD_CODE: [
      RemoveDeadCode.newInstance,
    ],
    HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH: [
      // TODO(brianwilkerson) Add a fix to move the unreachable catch clause to
      //  a place where it can be reached (when possible).
      RemoveDeadCode.newInstance,
    ],
    HintCode.DEAD_CODE_ON_CATCH_SUBTYPE: [
      // TODO(brianwilkerson) Add a fix to move the unreachable catch clause to
      //  a place where it can be reached (when possible).
      RemoveDeadCode.newInstance,
    ],
    HintCode.DIVISION_OPTIMIZATION: [
      UseEffectiveIntegerDivision.newInstance,
    ],
    HintCode.DUPLICATE_HIDDEN_NAME: [
      RemoveNameFromCombinator.newInstance,
    ],
    HintCode.DUPLICATE_IMPORT: [
      RemoveUnusedImport.newInstance,
    ],
    HintCode.DUPLICATE_SHOWN_NAME: [
      RemoveNameFromCombinator.newInstance,
    ],
    HintCode.INVALID_FACTORY_ANNOTATION: [
      RemoveAnnotation.newInstance,
    ],
    HintCode.INVALID_IMMUTABLE_ANNOTATION: [
      RemoveAnnotation.newInstance,
    ],
    HintCode.INVALID_LITERAL_ANNOTATION: [
      RemoveAnnotation.newInstance,
    ],
    HintCode.INVALID_REQUIRED_NAMED_PARAM: [
      RemoveAnnotation.newInstance,
    ],
    HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM: [
      RemoveAnnotation.newInstance,
    ],
    HintCode.INVALID_REQUIRED_POSITIONAL_PARAM: [
      RemoveAnnotation.newInstance,
    ],
    HintCode.INVALID_SEALED_ANNOTATION: [
      RemoveAnnotation.newInstance,
    ],
    HintCode.MISSING_REQUIRED_PARAM: [
      AddMissingRequiredArgument.newInstance,
    ],
    HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS: [
      AddMissingRequiredArgument.newInstance,
    ],
    HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE: [
      RemoveQuestionMark.newInstance,
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD: [
      RemoveAnnotation.newInstance,
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER: [
      RemoveAnnotation.newInstance,
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD: [
      RemoveAnnotation.newInstance,
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER: [
      RemoveAnnotation.newInstance,
    ],
//    HintCode.SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT : [],
//    HintCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE : [],
//    HintCode.SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT : [],
//    HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT : [],
//    HintCode.SDK_VERSION_EXTENSION_METHODS : [],
//    HintCode.SDK_VERSION_GT_GT_GT_OPERATOR : [],
//    HintCode.SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT : [],
//    HintCode.SDK_VERSION_SET_LITERAL : [],
//    HintCode.SDK_VERSION_UI_AS_CODE : [],
    HintCode.TYPE_CHECK_IS_NOT_NULL: [
      UseNotEqNull.newInstance,
    ],
    HintCode.TYPE_CHECK_IS_NULL: [
      UseEqEqNull.newInstance,
    ],
    HintCode.UNDEFINED_HIDDEN_NAME: [
      RemoveNameFromCombinator.newInstance,
    ],
    HintCode.UNDEFINED_SHOWN_NAME: [
      RemoveNameFromCombinator.newInstance,
    ],
    HintCode.UNNECESSARY_CAST: [
      RemoveUnnecessaryCast.newInstance,
    ],
    HintCode.UNUSED_CATCH_CLAUSE: [
      RemoveUnusedCatchClause.newInstance,
    ],
    HintCode.UNUSED_CATCH_STACK: [
      RemoveUnusedCatchStack.newInstance,
    ],
    HintCode.UNUSED_ELEMENT: [
      RemoveUnusedElement.newInstance,
    ],
    HintCode.UNUSED_FIELD: [
      RemoveUnusedField.newInstance,
    ],
    HintCode.UNUSED_IMPORT: [
      RemoveUnusedImport.newInstance,
    ],
    HintCode.UNUSED_LABEL: [
      RemoveUnusedLabel.newInstance,
    ],
    HintCode.UNUSED_LOCAL_VARIABLE: [
      RemoveUnusedLocalVariable.newInstance,
    ],
    HintCode.UNUSED_SHOWN_NAME: [
      RemoveNameFromCombinator.newInstance,
    ],

    ParserErrorCode.EXPECTED_TOKEN: [
      InsertSemicolon.newInstance,
    ],
    ParserErrorCode.GETTER_WITH_PARAMETERS: [
      RemoveParametersInGetterDeclaration.newInstance,
    ],
    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE: [
      AddTypeAnnotation.newInstance,
    ],
//    ParserErrorCode.VAR_AS_TYPE_NAME : [],

    StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE: [
      ReplaceReturnTypeFuture.newInstance,
    ],
    StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER: [
      ChangeToStaticAccess.newInstance,
    ],
    StaticTypeWarningCode.INVALID_ASSIGNMENT: [
      AddExplicitCast.newInstance,
      ChangeTypeAnnotation.newInstance,
    ],
    StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION: [
      RemoveParenthesesInGetterInvocation.newInstance,
    ],
    StaticTypeWarningCode.NON_BOOL_CONDITION: [
      AddNeNull.newInstance,
    ],
    StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT: [
      CreateClass.newInstance,
      CreateMixin.newInstance,
    ],
    StaticTypeWarningCode.UNDEFINED_FUNCTION: [
      CreateClass.newInstance,
    ],
    StaticTypeWarningCode.UNDEFINED_GETTER: [
      CreateClass.newInstance,
      CreateGetter.newInstance,
      CreateLocalVariable.newInstance,
      CreateMixin.newInstance,
    ],
    StaticTypeWarningCode.UNDEFINED_METHOD: [
      CreateClass.newInstance,
    ],
    StaticTypeWarningCode.UNDEFINED_SETTER: [
      CreateSetter.newInstance,
    ],
    StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR: [
      MoveTypeArgumentsToClass.newInstance,
      RemoveTypeArguments.newInstance,
    ],
    StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER: [
      // TODO(brianwilkerson) Consider adding fixes to create a field, getter,
      //  method or setter. The existing _addFix methods would need to be
      //  updated so that only the appropriate subset is generated.
      QualifyReference.newInstance,
    ],

    StaticWarningCode.ASSIGNMENT_TO_FINAL: [
      MakeFieldNotFinal.newInstance,
    ],
    StaticWarningCode.ASSIGNMENT_TO_FINAL_LOCAL: [
      MakeVariableNotFinal.newInstance,
    ],
    StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE: [
      WrapInText.newInstance,
    ],
    StaticWarningCode.CAST_TO_NON_TYPE: [
      CreateClass.newInstance,
      CreateMixin.newInstance,
    ],
    StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER: [
      CreateMissingOverrides.newInstance,
      CreateNoSuchMethod.newInstance,
      MakeClassAbstract.newInstance,
    ],
    StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION: [
      RemoveDeadIfNull.newInstance,
    ],
    StaticWarningCode.FINAL_NOT_INITIALIZED: [
      CreateConstructorForFinalFields.newInstance,
    ],
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
    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS: [
      CreateMissingOverrides.newInstance,
      CreateNoSuchMethod.newInstance,
      MakeClassAbstract.newInstance,
    ],
    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR: [
      CreateMissingOverrides.newInstance,
      CreateNoSuchMethod.newInstance,
      MakeClassAbstract.newInstance,
    ],
    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE: [
      CreateMissingOverrides.newInstance,
      CreateNoSuchMethod.newInstance,
      MakeClassAbstract.newInstance,
    ],
    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE: [
      CreateMissingOverrides.newInstance,
      CreateNoSuchMethod.newInstance,
      MakeClassAbstract.newInstance,
    ],
    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO: [
      CreateMissingOverrides.newInstance,
      CreateNoSuchMethod.newInstance,
      MakeClassAbstract.newInstance,
    ],
//    StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE : [],
    StaticWarningCode.NOT_A_TYPE: [
      CreateClass.newInstance,
      CreateMixin.newInstance,
    ],
    StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME: [
      CreateClass.newInstance,
      CreateMixin.newInstance,
    ],
    StaticWarningCode.UNDEFINED_CLASS_BOOLEAN: [
      ReplaceBooleanWithBool.newInstance,
    ],
    StaticWarningCode.UNDEFINED_IDENTIFIER: [
      CreateClass.newInstance,
      CreateGetter.newInstance,
      CreateLocalVariable.newInstance,
      CreateMixin.newInstance,
      CreateSetter.newInstance,
    ],
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

  Future<List<Fix>> compute() async {
    node = NodeLocator2(errorOffset).searchWithin(unit);

    // analyze ErrorCode
    var errorCode = error.errorCode;
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
            await _addFix_undefinedClass_useSimilar();
          }
        }
      }
    }
    if (errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST) {
      await _addFix_createImportUri();
      await _addFix_createPartUri();
    }
    // TODO(brianwilkerson) Define a syntax for deprecated members to indicate
    //  how to update the code and implement a fix to apply the update.
//    if (errorCode == HintCode.DEPRECATED_MEMBER_USE ||
//        errorCode == HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE) {
//      await _addFix_replaceDeprecatedMemberUse();
//    }
    // TODO(brianwilkerson) Add a fix to convert the path to a package: import.
//    if (errorCode == HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE) {
//      await _addFix_convertPathToPackageUri();
//    }
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
    // TODO(brianwilkerson) Add a fix to remove the method.
//    if (errorCode == HintCode.UNNECESSARY_NO_SUCH_METHOD) {
//      await _addFix_removeMethodDeclaration();
//    }
    // TODO(brianwilkerson) Add a fix to remove the type check.
//    if (errorCode == HintCode.UNNECESSARY_TYPE_CHECK_FALSE ||
//        errorCode == HintCode.UNNECESSARY_TYPE_CHECK_TRUE) {
//      await _addFix_removeUnnecessaryTypeCheck();
//    }
    if (errorCode == ParserErrorCode.VAR_AS_TYPE_NAME) {
      await _addFix_replaceVarWithDynamic();
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
    if (errorCode == CompileTimeErrorCode.CONST_WITH_NON_TYPE ||
        errorCode == CompileTimeErrorCode.MIXIN_OF_NON_CLASS ||
        errorCode == CompileTimeErrorCode.UNDEFINED_CLASS ||
        errorCode == StaticWarningCode.CAST_TO_NON_TYPE ||
        errorCode == StaticWarningCode.NEW_WITH_NON_TYPE ||
        errorCode == StaticWarningCode.NOT_A_TYPE ||
        errorCode == StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME) {
      await _addFix_importLibrary_withType();
      await _addFix_undefinedClass_useSimilar();
    }
    if (errorCode == StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE) {
      await _addFix_importLibrary_withType();
    }
    if (errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createField();
      await _addFix_createFunction_forFunctionType();
      await _addFix_importLibrary_withType();
      await _addFix_importLibrary_withExtension();
      await _addFix_importLibrary_withFunction();
      await _addFix_importLibrary_withTopLevelVariable();
    }
    if (errorCode == StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT) {
      await _addFix_importLibrary_withType();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_FUNCTION) {
      await _addFix_importLibrary_withExtension();
      await _addFix_importLibrary_withFunction();
      await _addFix_importLibrary_withType();
      await _addFix_undefinedFunction_useSimilar();
      await _addFix_undefinedFunction_create();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_GETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
      await _addFix_createField();
      await _addFix_createFunction_forFunctionType();
      await _addFix_importLibrary_withTopLevelVariable();
      await _addFix_importLibrary_withType();
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
    }
    if (errorCode == StaticTypeWarningCode.UNDEFINED_METHOD) {
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
    }
    if (errorCode == CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER) {
      await _addFix_undefinedClassAccessor_useSimilar();
    }
    if (errorCode ==
        CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD) {
      await _addFix_createField_initializingFormal();
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

  Future<void> _addFix_addMissingParameter() async {
    // The error is reported on ArgumentList.
    if (node is! ArgumentList) {
      return;
    }
    ArgumentList argumentList = node;
    List<Expression> arguments = argumentList.arguments;

    // Prepare the invoked element.
    var context = ExecutableParameters(sessionHelper, node.parent);
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

  Future<void> _addFix_replaceVarWithDynamic() async {
    var changeBuilder = _newDartChangeBuilder();
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(range.error(error), 'dynamic');
    });
    _addFixFromBuilder(changeBuilder, DartFixKind.REPLACE_VAR_WITH_DYNAMIC);
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
