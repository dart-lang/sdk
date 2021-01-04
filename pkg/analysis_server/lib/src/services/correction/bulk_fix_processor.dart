// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
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
import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
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
import 'package:analysis_server/src/services/correction/dart/remove_non_null_assertion.dart';
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
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// A fix producer that produces changes to fix multiple diagnostics.
class BulkFixProcessor {
  /// A map from the name of a lint rule to a list of generators used to create
  /// the correction producer used to build a fix for that diagnostic. The
  /// generators used for non-lint diagnostics are in the [nonLintProducerMap].
  ///
  /// Most entries will have only one generator. In cases where there is more
  /// than one, they will be applied in series and the expectation is that only
  /// one will produce a change for a given fix. If more than one change is
  /// produced the result will almost certainly be invalid code.
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
    LintNames.hash_and_equals: [
      CreateMethod.equalsOrHashCode,
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

  /// A map from an error code to a list of generators used to create multiple
  /// correction producers used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintMultiProducerMap].
  ///
  /// The expectation is that only one of the correction producers will produce
  /// a change for a given fix. If more than one change is produced the result
  /// will almost certainly be invalid code.
  static const Map<ErrorCode, List<MultiProducerGenerator>>
      nonLintMultiProducerMap = {
    CompileTimeErrorCode.EXTENDS_NON_CLASS: [
      DataDriven.newInstance,
    ],
    // TODO(brianwilkerson) The following fix fails if an invocation of the
    //  function is the argument that needs to be removed.
    // CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS: [
    //   DataDriven.newInstance,
    // ],
    // TODO(brianwilkerson) The following fix fails if an invocation of the
    //  function is the argument that needs to be updated.
    // CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
    //   DataDriven.newInstance,
    // ],
    CompileTimeErrorCode.IMPLEMENTS_NON_CLASS: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.INVALID_OVERRIDE: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.MIXIN_OF_NON_CLASS: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_CLASS: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_FUNCTION: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_GETTER: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_IDENTIFIER: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_METHOD: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_SETTER: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD: [
      DataDriven.newInstance,
    ],
    HintCode.DEPRECATED_MEMBER_USE: [
      DataDriven.newInstance,
    ],
    HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE: [
      DataDriven.newInstance,
    ],
    HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE: [
      DataDriven.newInstance,
    ],
    HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE: [
      DataDriven.newInstance,
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD: [
      DataDriven.newInstance,
    ],
  };

  /// A map from an error code to a generator used to create the correction
  /// producer used to build a fix for that diagnostic. The generators used for
  /// lint rules are in the [lintProducerMap].
  static const Map<ErrorCode, ProducerGenerator> nonLintProducerMap = {
    StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION:
        RemoveNonNullAssertion.newInstance,
  };

  /// The service used to report errors when building fixes.
  final InstrumentationService instrumentationService;

  /// Information about the workspace containing the libraries in which changes
  /// will be produced.
  final DartChangeWorkspace workspace;

  /// The change builder used to build the changes required to fix the
  /// diagnostics.
  ChangeBuilder builder;

  /// A map associating libraries to fixes with change counts.
  final ChangeMap changeMap = ChangeMap();

  /// Initialize a newly created processor to create fixes for diagnostics in
  /// libraries in the [workspace].
  BulkFixProcessor(this.instrumentationService, this.workspace)
      : builder = ChangeBuilder(workspace: workspace);

  List<BulkFix> get fixDetails {
    var details = <BulkFix>[];
    for (var change in changeMap.libraryMap.entries) {
      var fixes = <BulkFixDetail>[];
      for (var codeEntry in change.value.entries) {
        fixes.add(BulkFixDetail(codeEntry.key, codeEntry.value));
      }
      details.add(BulkFix(change.key, fixes));
    }
    return details;
  }

  /// Return a change builder that has been used to create fixes for the
  /// diagnostics in the libraries in the given [contexts].
  Future<ChangeBuilder> fixErrors(List<AnalysisContext> contexts) async {
    for (var context in contexts) {
      for (var path in context.contextRoot.analyzedFiles()) {
        if (!AnalysisEngine.isDartFileName(path)) {
          continue;
        }
        var kind = await context.currentSession.getSourceKind(path);
        if (kind != SourceKind.LIBRARY) {
          continue;
        }
        var library = await context.currentSession.getResolvedLibrary(path);
        await _fixErrorsInLibrary(library);
      }
    }

    return builder;
  }

  /// Return a change builder that has been used to create all fixes for a
  /// specific diagnostic code in the given [unit].
  Future<ChangeBuilder> fixOfTypeInUnit(
    ResolvedUnitResult unit,
    String errorCode,
  ) async {
    final errorCodeLowercase = errorCode.toLowerCase();
    final errors = unit.errors.where(
      (error) => error.errorCode.name.toLowerCase() == errorCodeLowercase,
    );

    final analysisOptions = unit.session.analysisContext.analysisOptions;
    final fixContext = DartFixContextImpl(
      instrumentationService,
      workspace,
      unit,
      null,
      (name) => [],
    );

    for (var error in errors) {
      final processor = ErrorProcessor.getProcessor(analysisOptions, error);
      // Only fix errors not filtered out in analysis options.
      if (processor == null || processor.severity != null) {
        await _fixSingleError(fixContext, unit, error);
      }
    }

    return builder;
  }

  /// Returns the potential [FixKind]s that may be available for a given diagnostic.
  ///
  /// The presence of a kind does not guarantee a fix will be produced, nor does
  /// the absence of a kind mean that it definitely will not (some producers
  /// do not provide FixKinds up-front). These results are intended as a hint
  /// for populating something like a quick-fix menu with possible apply-all fixes.
  Iterable<FixKind> producableFixesForError(
    ResolvedUnitResult result,
    AnalysisError diagnostic,
  ) sync* {
    final errorCode = diagnostic.errorCode;
    if (errorCode is LintCode) {
      final generators = lintProducerMap[errorCode.name];
      if (generators != null) {
        yield* generators.map((g) => g().fixKind).where((k) => k != null);
      }
      return;
    }

    final generator = nonLintProducerMap[errorCode];
    if (generator != null) {
      final kind = generator().fixKind;
      if (kind != null) yield kind;
    }

    final multiGenerators = nonLintMultiProducerMap[errorCode];
    if (multiGenerators != null) {
      final fixContext = DartFixContextImpl(
        instrumentationService,
        workspace,
        result,
        null,
        (name) => [],
      );

      var context = CorrectionProducerContext(
        applyingBulkFixes: true,
        dartFixContext: fixContext,
        diagnostic: diagnostic,
        resolvedResult: result,
        selectionOffset: diagnostic.offset,
        selectionLength: diagnostic.length,
        workspace: workspace,
      );

      for (final multiGenerator in multiGenerators) {
        final multiProducer = multiGenerator();
        multiProducer.configure(context);
        yield* multiProducer.producers
            .map((p) => p.fixKind)
            .where((k) => k != null);
      }
    }
  }

  /// Use the change [builder] to create fixes for the diagnostics in the
  /// library associated with the analysis [result].
  Future<void> _fixErrorsInLibrary(ResolvedLibraryResult result) async {
    var analysisOptions = result.session.analysisContext.analysisOptions;
    for (var unitResult in result.units) {
      final fixContext = DartFixContextImpl(
        instrumentationService,
        workspace,
        unitResult,
        null,
        (name) => [],
      );
      for (var error in unitResult.errors) {
        var processor = ErrorProcessor.getProcessor(analysisOptions, error);
        // Only fix errors not filtered out in analysis options.
        if (processor == null || processor.severity != null) {
          await _fixSingleError(fixContext, unitResult, error);
        }
      }
    }
  }

  /// Use the change [builder] and the [fixContext] to create a fix for the
  /// given [diagnostic] in the compilation unit associated with the analysis
  /// [result].
  Future<void> _fixSingleError(DartFixContext fixContext,
      ResolvedUnitResult result, AnalysisError diagnostic) async {
    var context = CorrectionProducerContext(
      applyingBulkFixes: true,
      dartFixContext: fixContext,
      diagnostic: diagnostic,
      resolvedResult: result,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
      workspace: workspace,
    );

    var setupSuccess = context.setupCompute();
    if (!setupSuccess) {
      return;
    }

    Future<void> compute(CorrectionProducer producer) async {
      producer.configure(context);
      try {
        var localBuilder = builder.copy();
        await producer.compute(localBuilder);
        builder = localBuilder;
      } on ConflictingEditException {
        // If a conflicting edit was added in [compute], then the [localBuilder]
        // is discarded and we revert to the previous state of the builder.
      }
    }

    int computeChangeHash() {
      var hash = 0;
      var edits = builder.sourceChange.edits;
      for (var i = 0; i < edits.length; ++i) {
        hash = JenkinsSmiHash.combine(hash, edits[i].hashCode);
      }
      return JenkinsSmiHash.finish(hash);
    }

    Future<void> generate(CorrectionProducer producer, String code) async {
      var oldHash = computeChangeHash();
      await compute(producer);
      var newHash = computeChangeHash();
      if (newHash != oldHash) {
        changeMap.add(result.path, code);
      }
    }

    var errorCode = diagnostic.errorCode;
    try {
      var codeName = errorCode.name;
      if (errorCode is LintCode) {
        var generators = lintProducerMap[codeName];
        if (generators != null) {
          for (var generator in generators) {
            await generate(generator(), codeName);
          }
        }
      } else {
        var generator = nonLintProducerMap[errorCode];
        if (generator != null) {
          await generate(generator(), codeName);
        }
        var multiGenerators = nonLintMultiProducerMap[errorCode];
        if (multiGenerators != null) {
          for (var multiGenerator in multiGenerators) {
            var multiProducer = multiGenerator();
            multiProducer.configure(context);
            for (var producer in multiProducer.producers) {
              await generate(producer, codeName);
            }
          }
        }
      }
    } catch (e, s) {
      throw CaughtException.withMessage(
          'Exception generating fix for ${errorCode.name} in ${result.path}',
          e,
          s);
    }
  }
}

/// Maps changes to library paths.
class ChangeMap {
  /// Map of paths to maps of codes to counts.
  final Map<String, Map<String, int>> libraryMap = {};

  /// Add an entry for the given [code] in the given [libraryPath].
  void add(String libraryPath, String code) {
    var changes = libraryMap.putIfAbsent(libraryPath, () => {});
    changes.update(code, (value) => value + 1, ifAbsent: () => 1);
  }
}
