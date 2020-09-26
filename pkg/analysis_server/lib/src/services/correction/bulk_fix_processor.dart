// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/add_await.dart';
import 'package:analysis_server/src/services/correction/dart/add_const.dart';
import 'package:analysis_server/src/services/correction/dart/add_diagnostic_property_reference.dart';
import 'package:analysis_server/src/services/correction/dart/add_override.dart';
import 'package:analysis_server/src/services/correction/dart/convert_add_all_to_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_conditional_expression_to_if_element.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_line.dart';
import 'package:analysis_server/src/services/correction/dart/convert_map_from_iterable_to_for_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_quotes.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_contains.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_generic_function_syntax.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_if_null.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_int_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_list_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_relative_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_set_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_where_type.dart';
import 'package:analysis_server/src/services/correction/dart/create_method.dart';
import 'package:analysis_server/src/services/correction/dart/inline_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/make_final.dart';
import 'package:analysis_server/src/services/correction/dart/remove_argument.dart';
import 'package:analysis_server/src/services/correction/dart/remove_await.dart';
import 'package:analysis_server/src/services/correction/dart/remove_const.dart';
import 'package:analysis_server/src/services/correction/dart/remove_duplicate_case.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_catch.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_constructor_body.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_else.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_statement.dart';
import 'package:analysis_server/src/services/correction/dart/remove_initializer.dart';
import 'package:analysis_server/src/services/correction/dart/remove_interpolation_braces.dart';
import 'package:analysis_server/src/services/correction/dart/remove_method_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/remove_operator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_this_expression.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_new.dart';
import 'package:analysis_server/src/services/correction/dart/rename_to_camel_case.dart';
import 'package:analysis_server/src/services/correction/dart/replace_cascade_with_dot.dart';
import 'package:analysis_server/src/services/correction/dart/replace_colon_with_equals.dart';
import 'package:analysis_server/src/services/correction/dart/replace_final_with_const.dart';
import 'package:analysis_server/src/services/correction/dart/replace_null_with_closure.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_conditional_assignment.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_is_empty.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_tear_off.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/sort_child_property_last.dart';
import 'package:analysis_server/src/services/correction/dart/use_curly_braces.dart';
import 'package:analysis_server/src/services/correction/dart/use_is_not_empty.dart';
import 'package:analysis_server/src/services/correction/dart/use_rethrow.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// A fix producer that produces changes to fix multiple diagnostics.
class BulkFixProcessor {
  /// A map from the name of a lint rule to a list of generators used to create
  /// the correction producer used to build a fix for that diagnostic. Most
  /// entries will have only one generator.  In cases where there is more than
  /// one, they will be applied in series and the expectation is that only one
  /// will produce a change for a given fix. If more than one change is produced
  /// the result will almost certainly be invalid code. The generators used for
  /// non-lint diagnostics are in the [nonLintProducerMap].
  static const Map<String, List<ProducerGenerator>> lintProducerMap = {
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
    LintNames.avoid_redundant_argument_values: [
      RemoveArgument.newInstance,
    ],
    LintNames.avoid_return_types_on_setters: [
      RemoveTypeAnnotation.newInstance,
    ],
    LintNames.avoid_single_cascade_in_expression_statements: [
      ReplaceCascadeWithDot.newInstance,
    ],
    LintNames.avoid_types_on_closure_parameters: [
      RemoveTypeAnnotation.newInstance,
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
    LintNames.empty_catches: [
      RemoveEmptyCatch.newInstance,
    ],
    LintNames.empty_constructor_bodies: [
      RemoveEmptyConstructorBody.newInstance,
    ],
    LintNames.empty_statements: [
      RemoveEmptyStatement.newInstance,
    ],
    LintNames.hash_and_equals: [CreateMethod.equalsOrHashCode],
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
    // TODO (pq): can produce results incompatible w/ `unnecessary_const`
    // LintNames.prefer_const_constructors: [
    //   AddConst.newInstance,
    //   ReplaceNewWithConst.newInstance,
    // ],
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
    LintNames.prefer_is_empty: [
      ReplaceWithIsEmpty.newInstance,
    ],
    LintNames.prefer_is_not_empty: [
      UesIsNotEmpty.newInstance,
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
      RemoveUnnecessaryConst.newInstance,
    ],
    LintNames.unnecessary_lambdas: [
      ReplaceWithTearOff.newInstance,
    ],
    LintNames.unnecessary_new: [
      RemoveUnnecessaryNew.newInstance,
    ],
    LintNames.unnecessary_overrides: [
      RemoveMethodDeclaration.newInstance,
    ],
    LintNames.unnecessary_this: [
      RemoveThisExpression.newInstance,
    ],
    LintNames.use_rethrow_when_possible: [
      UseRethrow.newInstance,
    ],
  };

  /// A map from an error code to a generator used to create the correction
  /// producer used to build a fix for that diagnostic. The generators used for
  /// lint rules are in the [lintProducerMap].
  static const Map<ErrorCode, ProducerGenerator> nonLintProducerMap = {};

  final DartChangeWorkspace workspace;

  /// The change builder used to build the changes required to fix the
  /// diagnostics.
  ChangeBuilder builder;

  BulkFixProcessor(this.workspace) {
    builder = ChangeBuilder(workspace: workspace);
  }

  Future<ChangeBuilder> fixErrorsInLibraries(List<String> libraryPaths) async {
    for (var path in libraryPaths) {
      var session = workspace.getSession(path);
      var kind = await session.getSourceKind(path);
      if (kind == SourceKind.LIBRARY) {
        var libraryResult = await session.getResolvedLibrary(path);
        await _fixErrorsInLibrary(libraryResult);
      }
    }
    return builder;
  }

  Future<void> _fixErrorsInLibrary(ResolvedLibraryResult libraryResult) async {
    for (var unitResult in libraryResult.units) {
      final fixContext = DartFixContextImpl(
        workspace,
        unitResult,
        null,
        (name) => [],
      );
      for (var error in unitResult.errors) {
        await _fixSingleError(fixContext, unitResult, error);
      }
    }
  }

  Future<void> _fixSingleError(DartFixContext fixContext,
      ResolvedUnitResult unitResult, AnalysisError error) async {
    var context = CorrectionProducerContext(
      dartFixContext: fixContext,
      diagnostic: error,
      resolvedResult: unitResult,
      selectionOffset: error.offset,
      selectionLength: error.length,
      workspace: workspace,
    );

    var setupSuccess = context.setupCompute();
    if (!setupSuccess) {
      return;
    }

    Future<void> compute(CorrectionProducer producer) async {
      producer.configure(context);
      await producer.compute(builder);
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
      var generator = nonLintProducerMap[errorCode];
      if (generator != null) {
        await compute(generator());
      }
    }
  }
}
