// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
import 'package:analysis_server/src/services/correction/dart/add_late.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_enum_case_clauses.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_parameter_named.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_required_argument.dart';
import 'package:analysis_server/src/services/correction/dart/add_ne_null.dart';
import 'package:analysis_server/src/services/correction/dart/add_null_check.dart';
import 'package:analysis_server/src/services/correction/dart/add_override.dart';
import 'package:analysis_server/src/services/correction/dart/add_required.dart';
import 'package:analysis_server/src/services/correction/dart/add_required_keyword.dart';
import 'package:analysis_server/src/services/correction/dart/add_return_type.dart';
import 'package:analysis_server/src/services/correction/dart/add_static.dart';
import 'package:analysis_server/src/services/correction/dart/add_super_constructor_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/add_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/change_argument_name.dart';
import 'package:analysis_server/src/services/correction/dart/change_to.dart';
import 'package:analysis_server/src/services/correction/dart/change_to_nearest_precise_value.dart';
import 'package:analysis_server/src/services/correction/dart/change_to_static_access.dart';
import 'package:analysis_server/src/services/correction/dart/change_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/convert_add_all_to_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_conditional_expression_to_if_element.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_line.dart';
import 'package:analysis_server/src/services/correction/dart/convert_flutter_child.dart';
import 'package:analysis_server/src/services/correction/dart/convert_flutter_children.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_is_not.dart';
import 'package:analysis_server/src/services/correction/dart/convert_map_from_iterable_to_for_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_quotes.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_contains.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_expression_function_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_for_loop.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_generic_function_syntax.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_if_null.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_int_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_list_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_named_arguments.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_on_type.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_package_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_relative_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_set_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_where_type.dart';
import 'package:analysis_server/src/services/correction/dart/create_class.dart';
import 'package:analysis_server/src/services/correction/dart/create_constructor.dart';
import 'package:analysis_server/src/services/correction/dart/create_constructor_for_final_fields.dart';
import 'package:analysis_server/src/services/correction/dart/create_constructor_super.dart';
import 'package:analysis_server/src/services/correction/dart/create_field.dart';
import 'package:analysis_server/src/services/correction/dart/create_file.dart';
import 'package:analysis_server/src/services/correction/dart/create_function.dart';
import 'package:analysis_server/src/services/correction/dart/create_getter.dart';
import 'package:analysis_server/src/services/correction/dart/create_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/create_method.dart';
import 'package:analysis_server/src/services/correction/dart/create_method_or_function.dart';
import 'package:analysis_server/src/services/correction/dart/create_missing_overrides.dart';
import 'package:analysis_server/src/services/correction/dart/create_mixin.dart';
import 'package:analysis_server/src/services/correction/dart/create_no_such_method.dart';
import 'package:analysis_server/src/services/correction/dart/create_setter.dart';
import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/dart/extend_class_for_mixin.dart';
import 'package:analysis_server/src/services/correction/dart/import_library.dart';
import 'package:analysis_server/src/services/correction/dart/inline_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/inline_typedef.dart';
import 'package:analysis_server/src/services/correction/dart/insert_semicolon.dart';
import 'package:analysis_server/src/services/correction/dart/make_class_abstract.dart';
import 'package:analysis_server/src/services/correction/dart/make_field_not_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_return_type_nullable.dart';
import 'package:analysis_server/src/services/correction/dart/make_variable_not_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_variable_nullable.dart';
import 'package:analysis_server/src/services/correction/dart/move_type_arguments_to_class.dart';
import 'package:analysis_server/src/services/correction/dart/organize_imports.dart';
import 'package:analysis_server/src/services/correction/dart/qualify_reference.dart';
import 'package:analysis_server/src/services/correction/dart/remove_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_argument.dart';
import 'package:analysis_server/src/services/correction/dart/remove_await.dart';
import 'package:analysis_server/src/services/correction/dart/remove_comparison.dart';
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
import 'package:analysis_server/src/services/correction/dart/remove_non_null_assertion.dart';
import 'package:analysis_server/src/services/correction/dart/remove_operator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_parameters_in_getter_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/remove_parentheses_in_getter_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_question_mark.dart';
import 'package:analysis_server/src/services/correction/dart/remove_returned_value.dart';
import 'package:analysis_server/src/services/correction/dart/remove_this_expression.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_arguments.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_cast.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_new.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_parentheses.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_string_interpolation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_catch_clause.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_catch_stack.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_import.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_label.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/rename_to_camel_case.dart';
import 'package:analysis_server/src/services/correction/dart/replace_boolean_with_bool.dart';
import 'package:analysis_server/src/services/correction/dart/replace_cascade_with_dot.dart';
import 'package:analysis_server/src/services/correction/dart/replace_colon_with_equals.dart';
import 'package:analysis_server/src/services/correction/dart/replace_final_with_const.dart';
import 'package:analysis_server/src/services/correction/dart/replace_final_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/replace_new_with_const.dart';
import 'package:analysis_server/src/services/correction/dart/replace_null_with_closure.dart';
import 'package:analysis_server/src/services/correction/dart/replace_return_type_future.dart';
import 'package:analysis_server/src/services/correction/dart/replace_var_with_dynamic.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_brackets.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_conditional_assignment.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_eight_digit_hex.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_extension_name.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_filled.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_identifier.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_interpolation.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_is_empty.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_not_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_tear_off.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/sort_child_property_last.dart';
import 'package:analysis_server/src/services/correction/dart/update_sdk_constraints.dart';
import 'package:analysis_server/src/services/correction/dart/use_const.dart';
import 'package:analysis_server/src/services/correction/dart/use_curly_braces.dart';
import 'package:analysis_server/src/services/correction/dart/use_effective_integer_division.dart';
import 'package:analysis_server/src/services/correction/dart/use_eq_eq_null.dart';
import 'package:analysis_server/src/services/correction/dart/use_is_not_empty.dart';
import 'package:analysis_server/src/services/correction/dart/use_not_eq_null.dart';
import 'package:analysis_server/src/services/correction/dart/use_rethrow.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_future.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_text.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart' hide FixContributor;

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
      var fixInFileProcessor = FixInFileProcessor(context);
      var fixInFileFixes = await fixInFileProcessor.compute();
      fixes.addAll(fixInFileFixes);
      return fixes;
    } on CancelCorrectionException {
      return const <Fix>[];
    }
  }
}

/// Computer for Dart "fix all in file" fixes.
class FixInFileProcessor {
  final DartFixContext context;
  FixInFileProcessor(this.context);

  Future<List<Fix>> compute() async {
    var error = context.error;
    var errors = context.resolveResult.errors
        .where((e) => error.errorCode.name == e.errorCode.name);
    if (errors.length < 2) {
      return const <Fix>[];
    }

    var instrumentationService = context.instrumentationService;
    var workspace = context.workspace;
    var resolveResult = context.resolveResult;

    var correctionContext = CorrectionProducerContext.create(
      dartFixContext: context,
      diagnostic: error,
      resolvedResult: resolveResult,
      selectionOffset: context.error.offset,
      selectionLength: context.error.length,
      workspace: workspace,
    );
    if (correctionContext == null) {
      return const <Fix>[];
    }

    var generators = _getGenerators(error.errorCode, correctionContext);

    var fixes = <Fix>[];
    for (var generator in generators) {
      _FixState fixState = _EmptyFixState(
        ChangeBuilder(workspace: workspace),
      );
      for (var error in errors) {
        var fixContext = DartFixContextImpl(
          instrumentationService,
          workspace,
          resolveResult,
          error,
          (name) => [],
        );
        fixState = await _fixError(fixContext, fixState, generator(), error);
      }
      if (fixState is _NotEmptyFixState) {
        var sourceChange = fixState.builder.sourceChange;
        if (sourceChange.edits.isNotEmpty && fixState.fixCount > 1) {
          var fixKind = fixState.fixKind;
          sourceChange.message = fixKind.message;
          fixes.add(Fix(fixKind, sourceChange));
        }
      }
    }
    return fixes;
  }

  Future<_FixState> _fixError(DartFixContext fixContext, _FixState fixState,
      CorrectionProducer producer, AnalysisError diagnostic) async {
    var context = CorrectionProducerContext.create(
      applyingBulkFixes: true,
      dartFixContext: fixContext,
      diagnostic: diagnostic,
      resolvedResult: fixContext.resolveResult,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
      workspace: fixContext.workspace,
    );
    if (context == null) {
      return fixState;
    }

    producer.configure(context);

    try {
      var localBuilder = fixState.builder.copy();
      await producer.compute(localBuilder);

      var multiFixKind = producer.multiFixKind;
      if (multiFixKind == null) {
        return fixState;
      }

      // todo (pq): consider discarding the change if the producer's fixKind
      // doesn't match a previously cached one.
      return _NotEmptyFixState(
        builder: localBuilder,
        fixKind: multiFixKind,
        fixCount: fixState.fixCount + 1,
      );
    } on ConflictingEditException {
      // If a conflicting edit was added in [compute], then the [localBuilder]
      // is discarded and we revert to the previous state of the builder.
      return fixState;
    }
  }

  List<ProducerGenerator> _getGenerators(
      ErrorCode errorCode, CorrectionProducerContext context) {
    var producers = <ProducerGenerator>[];
    if (errorCode is LintCode) {
      var fixInfos = FixProcessor.lintProducerMap[errorCode.name] ?? [];
      for (var fixInfo in fixInfos) {
        if (fixInfo.canBeAppliedToFile) {
          producers.addAll(fixInfo.generators);
        }
      }
    } else {
      var fixInfos = FixProcessor.nonLintProducerMap[errorCode] ?? [];
      for (var fixInfo in fixInfos) {
        if (fixInfo.canBeAppliedToFile) {
          producers.addAll(fixInfo.generators);
        }
      }
      // todo (pq): consider support for multiGenerators
    }
    return producers;
  }
}

class FixInfo {
  final bool canBeAppliedToFile;

  final bool canBeBulkApplied;

  final List<ProducerGenerator> generators;

  const FixInfo({
    required this.canBeAppliedToFile,
    required this.canBeBulkApplied,
    required this.generators,
  });

  const FixInfo.single(this.generators)
      : canBeAppliedToFile = false,
        canBeBulkApplied = false;
}

/// The computer for Dart fixes.
class FixProcessor extends BaseProcessor {
  /// A map from the names of lint rules to a list of generators used to create
  /// the correction producers used to build fixes for those diagnostics. The
  /// generators used for non-lint diagnostics are in the [nonLintProducerMap].
  static const Map<String, List<FixInfo>> lintProducerMap = {
    LintNames.always_declare_return_types: [
      FixInfo(
        // todo (pq): enable when tested
        canBeAppliedToFile: false,
        // not currently supported; TODO(pq): consider adding
        canBeBulkApplied: false,
        generators: [
          AddReturnType.newInstance,
        ],
      )
    ],
    LintNames.always_require_non_null_named_parameters: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          AddRequired.newInstance,
        ],
      )
    ],
    LintNames.always_specify_types: [
      FixInfo(
        // todo (pq): enable when tested
        canBeAppliedToFile: false,
        // not currently supported; TODO(pq): consider adding
        canBeBulkApplied: false,
        generators: [
          AddTypeAnnotation.newInstance,
        ],
      )
    ],
    LintNames.annotate_overrides: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          AddOverride.newInstance,
        ],
      )
    ],
    LintNames.avoid_annotating_with_dynamic: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveTypeAnnotation.newInstance,
        ],
      )
    ],
    LintNames.avoid_empty_else: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveEmptyElse.newInstance,
        ],
      )
    ],
    LintNames.avoid_function_literals_in_foreach_calls: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertForEachToForLoop.newInstance,
        ],
      )
    ],
    LintNames.avoid_init_to_null: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveInitializer.newInstance,
        ],
      )
    ],
    LintNames.avoid_private_typedef_functions: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          InlineTypedef.newInstance,
        ],
      )
    ],
    LintNames.avoid_redundant_argument_values: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveArgument.newInstance,
        ],
      )
    ],
    LintNames.avoid_relative_lib_imports: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToPackageImport.newInstance,
        ],
      )
    ],
    LintNames.avoid_return_types_on_setters: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveTypeAnnotation.newInstance,
        ],
      )
    ],
    LintNames.avoid_returning_null_for_future: [
      FixInfo(
        canBeAppliedToFile: false,
        // not currently supported; TODO(pq): consider adding
        canBeBulkApplied: false,
        generators: [
          AddAsync.newInstance,
          WrapInFuture.newInstance,
        ],
      )
    ],
    LintNames.avoid_returning_null_for_void: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveReturnedValue.newInstance,
        ],
      )
    ],
    LintNames.avoid_single_cascade_in_expression_statements: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          // TODO(brianwilkerson) This fix should be applied to some non-lint
          //  diagnostics and should also be available as an assist.
          ReplaceCascadeWithDot.newInstance,
        ],
      )
    ],
    LintNames.avoid_types_as_parameter_names: [
      FixInfo(
        canBeAppliedToFile: false,
        canBeBulkApplied: false,
        generators: [
          ConvertToOnType.newInstance,
        ],
      )
    ],
    LintNames.avoid_types_on_closure_parameters: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceWithIdentifier.newInstance,
          RemoveTypeAnnotation.newInstance,
        ],
      )
    ],
    LintNames.avoid_unused_constructor_parameters: [
      FixInfo(
        // todo (pq): enable when tested
        canBeAppliedToFile: false,
        canBeBulkApplied: false,
        generators: [
          RemoveUnusedParameter.newInstance,
        ],
      )
    ],
    LintNames.await_only_futures: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveAwait.newInstance,
        ],
      )
    ],
    LintNames.curly_braces_in_flow_control_structures: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          UseCurlyBraces.newInstance,
        ],
      )
    ],
    LintNames.diagnostic_describe_all_properties: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          AddDiagnosticPropertyReference.newInstance,
        ],
      )
    ],
    LintNames.directives_ordering: [
      FixInfo(
        canBeAppliedToFile: false, // Fix will sort all directives.
        canBeBulkApplied: true,
        generators: [
          OrganizeImports.newInstance,
        ],
      )
    ],
    LintNames.empty_catches: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveEmptyCatch.newInstance,
        ],
      )
    ],
    LintNames.empty_constructor_bodies: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveEmptyConstructorBody.newInstance,
        ],
      )
    ],
    LintNames.empty_statements: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveEmptyStatement.newInstance,
          ReplaceWithBrackets.newInstance,
        ],
      )
    ],
    LintNames.hash_and_equals: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          CreateMethod.equalsOrHashCode,
        ],
      )
    ],
    LintNames.no_duplicate_case_values: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveDuplicateCase.newInstance,
        ],
      )
    ],
    LintNames.non_constant_identifier_names: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RenameToCamelCase.newInstance,
        ],
      )
    ],
    LintNames.null_closures: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceNullWithClosure.newInstance,
        ],
      )
    ],
    LintNames.omit_local_variable_types: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceWithVar.newInstance,
        ],
      )
    ],
    LintNames.prefer_adjacent_string_concatenation: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveOperator.newInstance,
        ],
      )
    ],
    LintNames.prefer_collection_literals: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToListLiteral.newInstance,
          ConvertToMapLiteral.newInstance,
          ConvertToSetLiteral.newInstance,
        ],
      )
    ],
    LintNames.prefer_conditional_assignment: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceWithConditionalAssignment.newInstance,
        ],
      )
    ],
    LintNames.prefer_const_constructors: [
      FixInfo(
        canBeAppliedToFile: false,
        // Can produce results incompatible w/ `unnecessary_const`
        canBeBulkApplied: false,
        generators: [
          AddConst.newInstance,
          ReplaceNewWithConst.newInstance,
        ],
      )
    ],
    LintNames.prefer_const_constructors_in_immutables: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          AddConst.newInstance,
        ],
      )
    ],
    LintNames.prefer_const_declarations: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceFinalWithConst.newInstance,
        ],
      )
    ],
    LintNames.prefer_contains: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToContains.newInstance,
        ],
      )
    ],
    LintNames.prefer_equal_for_default_values: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceColonWithEquals.newInstance,
        ],
      )
    ],
    LintNames.prefer_expression_function_bodies: [
      FixInfo(
        // todo (pq): enable when tested
        canBeAppliedToFile: false,
        // not currently supported; TODO(pq): consider adding
        canBeBulkApplied: false,
        generators: [
          ConvertToExpressionFunctionBody.newInstance,
        ],
      )
    ],
    LintNames.prefer_final_fields: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          MakeFinal.newInstance,
        ],
      )
    ],
    LintNames.prefer_final_in_for_each: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          MakeFinal.newInstance,
        ],
      )
    ],
    LintNames.prefer_final_locals: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          MakeFinal.newInstance,
        ],
      )
    ],
    LintNames.prefer_for_elements_to_map_fromIterable: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertMapFromIterableToForLiteral.newInstance,
        ],
      )
    ],
    LintNames.prefer_generic_function_type_aliases: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToGenericFunctionSyntax.newInstance,
        ],
      )
    ],
    LintNames.prefer_if_elements_to_conditional_expressions: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertConditionalExpressionToIfElement.newInstance,
        ],
      )
    ],
    LintNames.prefer_is_empty: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceWithIsEmpty.newInstance,
        ],
      )
    ],
    LintNames.prefer_is_not_empty: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          UseIsNotEmpty.newInstance,
        ],
      )
    ],
    LintNames.prefer_if_null_operators: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToIfNull.newInstance,
        ],
      )
    ],
    LintNames.prefer_inlined_adds: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertAddAllToSpread.newInstance,
          InlineInvocation.newInstance,
        ],
      )
    ],
    LintNames.prefer_int_literals: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToIntLiteral.newInstance,
        ],
      )
    ],
    LintNames.prefer_interpolation_to_compose_strings: [
      FixInfo(
        // todo (pq): enable when tested
        canBeAppliedToFile: false,
        // not currently supported; TODO(pq): consider adding
        canBeBulkApplied: false,
        generators: [
          ReplaceWithInterpolation.newInstance,
        ],
      )
    ],
    LintNames.prefer_is_not_operator: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertIntoIsNot.newInstance,
        ],
      )
    ],
    LintNames.prefer_iterable_whereType: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToWhereType.newInstance,
        ],
      )
    ],
    LintNames.prefer_null_aware_operators: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToNullAware.newInstance,
        ],
      )
    ],
    LintNames.prefer_relative_imports: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToRelativeImport.newInstance,
        ],
      )
    ],
    LintNames.prefer_single_quotes: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToSingleQuotes.newInstance,
        ],
      )
    ],
    LintNames.prefer_spread_collections: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertAddAllToSpread.newInstance,
        ],
      )
    ],
    LintNames.slash_for_doc_comments: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertDocumentationIntoLine.newInstance,
        ],
      )
    ],
    LintNames.sort_child_properties_last: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          SortChildPropertyLast.newInstance,
        ],
      )
    ],
    LintNames.type_annotate_public_apis: [
      FixInfo(
        // todo (pq): enable when tested
        canBeAppliedToFile: false,
        // not currently supported; TODO(pq): consider adding
        canBeBulkApplied: false,
        generators: [
          AddTypeAnnotation.newInstance,
        ],
      )
    ],
    LintNames.type_init_formals: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveTypeAnnotation.newInstance,
        ],
      )
    ],
    LintNames.unawaited_futures: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          AddAwait.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_brace_in_string_interps: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveInterpolationBraces.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_const: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveUnnecessaryConst.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_final: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceFinalWithVar.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_lambdas: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceWithTearOff.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_new: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveUnnecessaryNew.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_null_in_if_null_operators: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveIfNullOperator.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_nullable_for_final_variable_declarations: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveQuestionMark.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_overrides: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveMethodDeclaration.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_parenthesis: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveUnnecessaryParentheses.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_string_interpolations: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveUnnecessaryStringInterpolation.newInstance,
        ],
      )
    ],
    LintNames.unnecessary_this: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveThisExpression.newInstance,
        ],
      )
    ],
    LintNames.use_full_hex_values_for_flutter_colors: [
      FixInfo(
        // todo (pq): enable when tested
        canBeAppliedToFile: false,
        // not currently supported; TODO(pq): consider adding
        canBeBulkApplied: false,
        generators: [
          ReplaceWithEightDigitHex.newInstance,
        ],
      )
    ],
    LintNames.use_function_type_syntax_for_parameters: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ConvertToGenericFunctionSyntax.newInstance,
        ],
      )
    ],
    LintNames.use_rethrow_when_possible: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          UseRethrow.newInstance,
        ],
      )
    ],
  };

  /// A map from error codes to a list of generators used to create multiple
  /// correction producers used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintMultiProducerMap].
  static const Map<ErrorCode, List<MultiProducerGenerator>>
      nonLintMultiProducerMap = {
    CompileTimeErrorCode.CAST_TO_NON_TYPE: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.CONST_WITH_NON_TYPE: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.EXTENDS_NON_CLASS: [
      DataDriven.newInstance,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS: [
      AddMissingParameter.newInstance,
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
      AddMissingParameter.newInstance,
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.IMPLEMENTS_NON_CLASS: [
      DataDriven.newInstance,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.INVALID_ANNOTATION: [
      ImportLibrary.forTopLevelVariable,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.INVALID_OVERRIDE: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.MIXIN_OF_NON_CLASS: [
      DataDriven.newInstance,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.NEW_WITH_NON_TYPE: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT: [
      AddSuperConstructorInvocation.newInstance,
    ],
    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT: [
      AddSuperConstructorInvocation.newInstance,
      CreateConstructorSuper.newInstance,
    ],
    CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.NOT_A_TYPE: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_ANNOTATION: [
      ImportLibrary.forTopLevelVariable,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_CLASS: [
      DataDriven.newInstance,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT: [
      AddSuperConstructorInvocation.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_FUNCTION: [
      DataDriven.newInstance,
      ImportLibrary.forExtension,
      ImportLibrary.forFunction,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_GETTER: [
      DataDriven.newInstance,
      ImportLibrary.forTopLevelVariable,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_IDENTIFIER: [
      DataDriven.newInstance,
      ImportLibrary.forExtension,
      ImportLibrary.forFunction,
      ImportLibrary.forTopLevelVariable,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_METHOD: [
      DataDriven.newInstance,
      ImportLibrary.forFunction,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      ChangeArgumentName.newInstance,
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_SETTER: [
      DataDriven.newInstance,
      // TODO(brianwilkerson) Support ImportLibrary
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
    HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE: [
      DataDriven.newInstance,
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD: [
      DataDriven.newInstance,
    ],
    HintCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE: [
      ImportLibrary.dartAsync,
    ],
  };

  /// A map from error codes to a list of generators used to create the
  /// correction producers used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintProducerMap].
  static const Map<ErrorCode, List<FixInfo>> nonLintProducerMap = {
    CompileTimeErrorCode.ASSIGNMENT_TO_FINAL: [
      FixInfo.single([MakeFieldNotFinal.newInstance]),
      FixInfo.single([AddLate.newInstance]),
    ],
    CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL: [
      FixInfo.single([MakeVariableNotFinal.newInstance]),
    ],
    CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE: [
      FixInfo.single([AddNullCheck.newInstance]),
      FixInfo.single([WrapInText.newInstance]),
    ],
    CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT: [
      FixInfo.single([AddAsync.newInstance]),
    ],
    CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT: [
      FixInfo.single([AddAsync.newInstance]),
    ],
    CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY: [
      FixInfo.single([AddAsync.missingReturn]),
    ],
    CompileTimeErrorCode.CAST_TO_NON_TYPE: [
      FixInfo.single([ChangeTo.classOrMixin]),
      FixInfo.single([CreateClass.newInstance]),
      FixInfo.single([CreateMixin.newInstance]),
    ],
    CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER: [
      FixInfo.single([CreateMissingOverrides.newInstance]),
      FixInfo.single([CreateNoSuchMethod.newInstance]),
      FixInfo.single([MakeClassAbstract.newInstance]),
    ],
    CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE: [
      FixInfo.single([UseConst.newInstance]),
    ],
    CompileTimeErrorCode.CONST_INSTANCE_FIELD: [
      FixInfo.single([AddStatic.newInstance]),
    ],
    CompileTimeErrorCode.CONST_WITH_NON_CONST: [
      FixInfo.single([RemoveConst.newInstance]),
    ],
    CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR: [
      FixInfo.single([ReplaceWithFilled.newInstance]),
    ],
    CompileTimeErrorCode.CONST_WITH_NON_TYPE: [
      FixInfo.single([ChangeTo.classOrMixin]),
    ],
    CompileTimeErrorCode.EXTENDS_NON_CLASS: [
      FixInfo.single([ChangeTo.classOrMixin]),
      FixInfo.single([CreateClass.newInstance]),
    ],
    CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER: [
      FixInfo.single([ReplaceWithExtensionName.newInstance]),
    ],
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS: [
      FixInfo.single([CreateConstructor.newInstance]),
    ],
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
      FixInfo.single([CreateConstructor.newInstance]),
      FixInfo.single([ConvertToNamedArguments.newInstance]),
    ],
    CompileTimeErrorCode.FINAL_NOT_INITIALIZED: [
      FixInfo.single([AddLate.newInstance]),
      FixInfo.single([CreateConstructorForFinalFields.newInstance]),
    ],
    CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1: [
      FixInfo.single([AddFieldFormalParameters.newInstance]),
    ],
    CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2: [
      FixInfo.single([AddFieldFormalParameters.newInstance]),
    ],
    CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS: [
      FixInfo.single([AddFieldFormalParameters.newInstance]),
    ],
    CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE: [
      FixInfo.single([ReplaceReturnTypeFuture.newInstance]),
    ],
    CompileTimeErrorCode.IMPLEMENTS_NON_CLASS: [
      FixInfo.single([ChangeTo.classOrMixin]),
      FixInfo.single([CreateClass.newInstance]),
    ],
    CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD: [
      FixInfo.single([CreateField.newInstance]),
    ],
    CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER: [
      FixInfo.single([ChangeToStaticAccess.newInstance]),
    ],
    CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE: [
      FixInfo.single([ChangeToNearestPreciseValue.newInstance]),
    ],
    CompileTimeErrorCode.INVALID_ANNOTATION: [
      FixInfo.single([ChangeTo.annotation]),
      FixInfo.single([CreateClass.newInstance]),
    ],
    CompileTimeErrorCode.INVALID_ASSIGNMENT: [
      FixInfo.single([AddExplicitCast.newInstance]),
      FixInfo.single([AddNullCheck.newInstance]),
      FixInfo.single([ChangeTypeAnnotation.newInstance]),
      FixInfo.single([MakeVariableNullable.newInstance]),
    ],
    CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION: [
      FixInfo.single([RemoveParenthesesInGetterInvocation.newInstance]),
    ],
    CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER: [
      FixInfo.single([AddRequiredKeyword.newInstance]),
      FixInfo.single([MakeVariableNullable.newInstance]),
    ],
    CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT: [
      FixInfo.single([AddMissingRequiredArgument.newInstance]),
    ],
    CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE: [
      FixInfo.single([ExtendClassForMixin.newInstance]),
    ],
    CompileTimeErrorCode.MIXIN_OF_NON_CLASS: [
      FixInfo.single([ChangeTo.classOrMixin]),
      FixInfo.single([CreateClass.newInstance]),
    ],
    CompileTimeErrorCode.NEW_WITH_NON_TYPE: [
      FixInfo.single([ChangeTo.classOrMixin]),
    ],
    CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR: [
      FixInfo.single([CreateConstructor.newInstance]),
    ],
    CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS:
        [
      FixInfo.single([CreateMissingOverrides.newInstance]),
      FixInfo.single([CreateNoSuchMethod.newInstance]),
      FixInfo.single([MakeClassAbstract.newInstance]),
    ],
    CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR: [
      FixInfo.single([CreateMissingOverrides.newInstance]),
      FixInfo.single([CreateNoSuchMethod.newInstance]),
      FixInfo.single([MakeClassAbstract.newInstance]),
    ],
    CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE: [
      FixInfo.single([CreateMissingOverrides.newInstance]),
      FixInfo.single([CreateNoSuchMethod.newInstance]),
      FixInfo.single([MakeClassAbstract.newInstance]),
    ],
    CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE: [
      FixInfo.single([CreateMissingOverrides.newInstance]),
      FixInfo.single([CreateNoSuchMethod.newInstance]),
      FixInfo.single([MakeClassAbstract.newInstance]),
    ],
    CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO: [
      FixInfo.single([CreateMissingOverrides.newInstance]),
      FixInfo.single([CreateNoSuchMethod.newInstance]),
      FixInfo.single([MakeClassAbstract.newInstance]),
    ],
    CompileTimeErrorCode.NON_BOOL_CONDITION: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: false,
        generators: [
          AddNeNull.newInstance,
        ],
      ),
    ],
    CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT: [
      FixInfo.single([CreateClass.newInstance]),
      FixInfo.single([CreateMixin.newInstance]),
    ],
    CompileTimeErrorCode.NOT_A_TYPE: [
      FixInfo.single([ChangeTo.classOrMixin]),
      FixInfo.single([CreateClass.newInstance]),
      FixInfo.single([CreateMixin.newInstance]),
    ],
    CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD: [
      FixInfo.single([AddLate.newInstance]),
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE: [
      FixInfo.single([RemoveQuestionMark.newInstance]),
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE: [
      FixInfo.single([RemoveQuestionMark.newInstance]),
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE: [
      FixInfo.single([RemoveQuestionMark.newInstance]),
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE: [
      FixInfo.single([RemoveQuestionMark.newInstance]),
    ],
    CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION: [
      FixInfo.single([MakeReturnTypeNullable.newInstance]),
    ],
    CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD: [
      FixInfo.single([MakeReturnTypeNullable.newInstance]),
    ],
    CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME: [
      FixInfo.single([ChangeTo.classOrMixin]),
      FixInfo.single([CreateClass.newInstance]),
      FixInfo.single([CreateMixin.newInstance]),
    ],
    CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE: [
      FixInfo.single([AddNullCheck.newInstance]),
    ],
    CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE: [
      FixInfo.single([AddNullCheck.newInstance]),
    ],
    CompileTimeErrorCode.UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE: [
      FixInfo.single([AddNullCheck.newInstance]),
    ],
    CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE: [
      FixInfo.single([AddNullCheck.newInstance]),
    ],
    CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE: [
      FixInfo.single([AddNullCheck.newInstance]),
    ],
    CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION: [
      FixInfo.single([AddNullCheck.newInstance]),
    ],
    CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR: [
      FixInfo.single([AddNullCheck.newInstance]),
    ],
    CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD: [
      FixInfo.single([AddNullCheck.newInstance]),
      FixInfo.single([ConvertToNullAwareSpread.newInstance]),
    ],
    CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH: [
      FixInfo.single([AddNullCheck.newInstance]),
    ],
    CompileTimeErrorCode.UNDEFINED_ANNOTATION: [
      FixInfo.single([ChangeTo.annotation]),
      FixInfo.single([CreateClass.newInstance]),
    ],
    CompileTimeErrorCode.UNDEFINED_CLASS: [
      FixInfo.single([ChangeTo.classOrMixin]),
      FixInfo.single([CreateClass.newInstance]),
      FixInfo.single([CreateMixin.newInstance]),
    ],
    CompileTimeErrorCode.UNDEFINED_CLASS_BOOLEAN: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: false,
        generators: [
          ReplaceBooleanWithBool.newInstance,
        ],
      ),
    ],
    CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER: [
      FixInfo.single([ChangeTo.getterOrSetter]),
      FixInfo.single([CreateGetter.newInstance]),
    ],
    CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD: [
      FixInfo.single([ChangeTo.method]),
      FixInfo.single([CreateMethod.method]),
    ],
    CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER: [
      FixInfo.single([ChangeTo.getterOrSetter]),
      FixInfo.single([CreateSetter.newInstance]),
    ],
    CompileTimeErrorCode.UNDEFINED_FUNCTION: [
      FixInfo.single([ChangeTo.function]),
      FixInfo.single([CreateClass.newInstance]),
      FixInfo.single([CreateFunction.newInstance]),
    ],
    CompileTimeErrorCode.UNDEFINED_GETTER: [
      FixInfo.single([ChangeTo.getterOrSetter]),
      FixInfo.single([CreateClass.newInstance]),
      FixInfo.single([CreateField.newInstance]),
      FixInfo.single([CreateGetter.newInstance]),
      FixInfo.single([CreateLocalVariable.newInstance]),
      FixInfo.single([CreateMethodOrFunction.newInstance]),
      FixInfo.single([CreateMixin.newInstance]),
    ],
    CompileTimeErrorCode.UNDEFINED_IDENTIFIER: [
      FixInfo.single([ChangeTo.getterOrSetter]),
      FixInfo.single([CreateClass.newInstance]),
      FixInfo.single([CreateField.newInstance]),
      FixInfo.single([CreateGetter.newInstance]),
      FixInfo.single([CreateLocalVariable.newInstance]),
      FixInfo.single([CreateMethodOrFunction.newInstance]),
      FixInfo.single([CreateMixin.newInstance]),
      FixInfo.single([CreateSetter.newInstance]),
    ],
    CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT: [
      FixInfo.single([AddAsync.newInstance]),
    ],
    CompileTimeErrorCode.UNDEFINED_METHOD: [
      FixInfo.single([ChangeTo.method]),
      FixInfo.single([CreateClass.newInstance]),
      FixInfo.single([CreateFunction.newInstance]),
      FixInfo.single([CreateMethod.method]),
    ],
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      FixInfo.single([AddMissingParameterNamed.newInstance]),
      FixInfo.single([ConvertFlutterChild.newInstance]),
      FixInfo.single([ConvertFlutterChildren.newInstance]),
    ],
    CompileTimeErrorCode.UNDEFINED_SETTER: [
      FixInfo.single([ChangeTo.getterOrSetter]),
      FixInfo.single([CreateField.newInstance]),
      FixInfo.single([CreateSetter.newInstance]),
    ],
    CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER: [
      // TODO(brianwilkerson) Consider adding fixes to create a field, getter,
      //  method or setter. The existing _addFix methods would need to be
      //  updated so that only the appropriate subset is generated.
      FixInfo.single([QualifyReference.newInstance]),
    ],
    CompileTimeErrorCode
        .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE: [
      // TODO(brianwilkerson) Consider adding fixes to create a field, getter,
      //  method or setter. The existing producers would need to be updated so
      //  that only the appropriate subset is generated.
      FixInfo.single([QualifyReference.newInstance]),
    ],
    CompileTimeErrorCode.URI_DOES_NOT_EXIST: [
      FixInfo.single([CreateFile.newInstance]),
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR: [
      FixInfo.single([MoveTypeArgumentsToClass.newInstance]),
      FixInfo.single([RemoveTypeArguments.newInstance]),
    ],
    CompileTimeErrorCode.YIELD_OF_INVALID_TYPE: [
      FixInfo.single([MakeReturnTypeNullable.newInstance]),
    ],

    HintCode.CAN_BE_NULL_AFTER_NULL_AWARE: [
      FixInfo.single([ReplaceWithNullAware.newInstance]),
    ],
    HintCode.DEAD_CODE: [
      FixInfo.single([RemoveDeadCode.newInstance]),
    ],
    HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH: [
      // TODO(brianwilkerson) Add a fix to move the unreachable catch clause to
      //  a place where it can be reached (when possible).
      FixInfo.single([RemoveDeadCode.newInstance]),
    ],
    HintCode.DEAD_CODE_ON_CATCH_SUBTYPE: [
      // TODO(brianwilkerson) Add a fix to move the unreachable catch clause to
      //  a place where it can be reached (when possible).
      FixInfo.single([RemoveDeadCode.newInstance]),
    ],
    HintCode.DIVISION_OPTIMIZATION: [
      FixInfo.single([UseEffectiveIntegerDivision.newInstance]),
    ],
    HintCode.DUPLICATE_HIDDEN_NAME: [
      FixInfo.single([RemoveNameFromCombinator.newInstance]),
    ],
    HintCode.DUPLICATE_IMPORT: [
      FixInfo.single([RemoveUnusedImport.newInstance]),
    ],
    HintCode.DUPLICATE_SHOWN_NAME: [
      FixInfo.single([RemoveNameFromCombinator.newInstance]),
    ],
    // TODO(brianwilkerson) Add a fix to convert the path to a package: import.
//    HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE: [],
    HintCode.INVALID_FACTORY_ANNOTATION: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    HintCode.INVALID_IMMUTABLE_ANNOTATION: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    HintCode.INVALID_LITERAL_ANNOTATION: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    HintCode.INVALID_REQUIRED_NAMED_PARAM: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    HintCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    HintCode.INVALID_REQUIRED_POSITIONAL_PARAM: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    HintCode.INVALID_SEALED_ANNOTATION: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    HintCode.MISSING_REQUIRED_PARAM: [
      FixInfo.single([AddMissingRequiredArgument.newInstance]),
    ],
    HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS: [
      FixInfo.single([AddMissingRequiredArgument.newInstance]),
    ],
    HintCode.MISSING_RETURN: [
      FixInfo.single([AddAsync.missingReturn]),
    ],
    HintCode.NULLABLE_TYPE_IN_CATCH_CLAUSE: [
      FixInfo.single([RemoveQuestionMark.newInstance]),
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER: [
      FixInfo.single([RemoveAnnotation.newInstance]),
    ],
    // TODO(brianwilkerson) Add a fix to normalize the path.
//    HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT: [],
    HintCode.SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT: [
      FixInfo.single([UpdateSdkConstraints.version_2_2_2]),
    ],
    HintCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE: [
      FixInfo.single([UpdateSdkConstraints.version_2_1_0]),
    ],
    HintCode.SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT: [
      FixInfo.single([UpdateSdkConstraints.version_2_2_2]),
    ],
    HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT: [
      FixInfo.single([UpdateSdkConstraints.version_2_2_2]),
    ],
    HintCode.SDK_VERSION_EXTENSION_METHODS: [
      FixInfo.single([UpdateSdkConstraints.version_2_6_0]),
    ],
    HintCode.SDK_VERSION_GT_GT_GT_OPERATOR: [
      FixInfo.single([UpdateSdkConstraints.version_2_2_2]),
    ],
    HintCode.SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT: [
      FixInfo.single([UpdateSdkConstraints.version_2_2_2]),
    ],
    HintCode.SDK_VERSION_SET_LITERAL: [
      FixInfo.single([UpdateSdkConstraints.version_2_2_0]),
    ],
    HintCode.SDK_VERSION_UI_AS_CODE: [
      FixInfo.single([UpdateSdkConstraints.version_2_2_2]),
    ],
    HintCode.TYPE_CHECK_IS_NOT_NULL: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: false,
        generators: [
          UseNotEqNull.newInstance,
        ],
      ),
    ],
    HintCode.TYPE_CHECK_IS_NULL: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: false,
        generators: [
          UseEqEqNull.newInstance,
        ],
      ),
    ],
    HintCode.UNDEFINED_HIDDEN_NAME: [
      FixInfo.single([RemoveNameFromCombinator.newInstance]),
    ],
    HintCode.UNDEFINED_SHOWN_NAME: [
      FixInfo.single([RemoveNameFromCombinator.newInstance]),
    ],
    HintCode.UNNECESSARY_CAST: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: false,
        generators: [
          RemoveUnnecessaryCast.newInstance,
        ],
      ),
    ],
//    HintCode.UNNECESSARY_NO_SUCH_METHOD: [
// TODO(brianwilkerson) Add a fix to remove the method.
//    ],
    HintCode.UNNECESSARY_NULL_COMPARISON_FALSE: [
      FixInfo.single([RemoveComparison.newInstance]),
    ],
    HintCode.UNNECESSARY_NULL_COMPARISON_TRUE: [
      FixInfo.single([RemoveComparison.newInstance]),
    ],
//    HintCode.UNNECESSARY_TYPE_CHECK_FALSE: [
// TODO(brianwilkerson) Add a fix to remove the type check.
//    ],
//    HintCode.UNNECESSARY_TYPE_CHECK_TRUE: [
// TODO(brianwilkerson) Add a fix to remove the type check.
//    ],
    HintCode.UNUSED_CATCH_CLAUSE: [
      FixInfo.single([RemoveUnusedCatchClause.newInstance]),
    ],
    HintCode.UNUSED_CATCH_STACK: [
      FixInfo.single([RemoveUnusedCatchStack.newInstance]),
    ],
    HintCode.UNUSED_ELEMENT: [
      FixInfo.single([RemoveUnusedElement.newInstance]),
    ],
    HintCode.UNUSED_FIELD: [
      FixInfo.single([RemoveUnusedField.newInstance]),
    ],
    HintCode.UNUSED_IMPORT: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: false,
        generators: [
          RemoveUnusedImport.newInstance,
        ],
      ),
    ],
    HintCode.UNUSED_LABEL: [
      FixInfo.single([RemoveUnusedLabel.newInstance]),
    ],
    HintCode.UNUSED_LOCAL_VARIABLE: [
      FixInfo.single([RemoveUnusedLocalVariable.newInstance]),
    ],
    HintCode.UNUSED_SHOWN_NAME: [
      FixInfo.single([RemoveNameFromCombinator.newInstance]),
    ],
    ParserErrorCode.EXPECTED_TOKEN: [
      FixInfo.single([InsertSemicolon.newInstance]),
    ],
    ParserErrorCode.GETTER_WITH_PARAMETERS: [
      FixInfo.single([RemoveParametersInGetterDeclaration.newInstance]),
    ],
    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE: [
      FixInfo.single([AddTypeAnnotation.newInstance]),
    ],
    ParserErrorCode.VAR_AS_TYPE_NAME: [
      FixInfo.single([ReplaceVarWithDynamic.newInstance]),
    ],
    StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION: [
      FixInfo.single([RemoveDeadIfNull.newInstance]),
    ],
    StaticWarningCode.INVALID_NULL_AWARE_OPERATOR: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceWithNotNullAware.newInstance,
        ],
      ),
    ],
    StaticWarningCode.INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          ReplaceWithNotNullAware.newInstance,
        ],
      ),
    ],
    StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH: [
      FixInfo.single([AddMissingEnumCaseClauses.newInstance]),
    ],
    StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION: [
      FixInfo(
        canBeAppliedToFile: true,
        canBeBulkApplied: true,
        generators: [
          RemoveNonNullAssertion.newInstance,
        ],
      ),
    ],
  };

  final DartFixContext fixContext;

  final List<Fix> fixes = <Fix>[];

  FixProcessor(this.fixContext)
      : super(
          resolvedResult: fixContext.resolveResult,
          workspace: fixContext.workspace,
        );

  Future<List<Fix>> compute() async {
    await _addFromProducers();
    return fixes;
  }

  Future<Fix?> computeFix() async {
    await _addFromProducers();
    fixes.sort(Fix.SORT_BY_RELEVANCE);
    return fixes.isNotEmpty ? fixes.first : null;
  }

  void _addFixFromBuilder(ChangeBuilder builder, CorrectionProducer producer) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }

    var kind = producer.fixKind;
    if (kind == null) {
      return;
    }

    change.id = kind.id;
    change.message = formatList(kind.message, producer.fixArguments);
    fixes.add(Fix(kind, change));
  }

  Future<void> _addFromProducers() async {
    var error = fixContext.error;
    var context = CorrectionProducerContext.create(
      dartFixContext: fixContext,
      diagnostic: error,
      resolvedResult: resolvedResult,
      selectionOffset: fixContext.error.offset,
      selectionLength: fixContext.error.length,
      workspace: workspace,
    );
    if (context == null) {
      return;
    }

    Future<void> compute(CorrectionProducer producer) async {
      producer.configure(context);
      var builder = ChangeBuilder(
          workspace: context.workspace, eol: context.utils.endOfLine);
      try {
        await producer.compute(builder);
        _addFixFromBuilder(builder, producer);
      } on ConflictingEditException catch (exception, stackTrace) {
        // Handle the exception by (a) not adding a fix based on the producer
        // and (b) logging the exception.
        fixContext.instrumentationService.logException(exception, stackTrace);
      }
    }

    var errorCode = error.errorCode;
    if (errorCode is LintCode) {
      var fixes = lintProducerMap[errorCode.name] ?? [];
      for (var fix in fixes) {
        for (var generator in fix.generators) {
          await compute(generator());
        }
      }
    } else {
      var fixes = nonLintProducerMap[errorCode] ?? [];
      for (var fix in fixes) {
        for (var generator in fix.generators) {
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
}

/// [_FixState] that is still empty.
class _EmptyFixState implements _FixState {
  @override
  final ChangeBuilder builder;

  _EmptyFixState(this.builder);

  @override
  int get fixCount => 0;
}

/// State associated with producing fix-all-in-file fixes.
abstract class _FixState {
  ChangeBuilder get builder;

  int get fixCount;
}

/// [_FixState] that has a fix, so knows its kind.
class _NotEmptyFixState implements _FixState {
  @override
  final ChangeBuilder builder;

  final FixKind fixKind;

  @override
  final int fixCount;

  _NotEmptyFixState({
    required this.builder,
    required this.fixKind,
    required this.fixCount,
  });
}
