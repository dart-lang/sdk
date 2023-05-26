// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/correction/base_processor.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/add_async.dart';
import 'package:analysis_server/src/services/correction/dart/add_await.dart';
import 'package:analysis_server/src/services/correction/dart/add_call_super.dart';
import 'package:analysis_server/src/services/correction/dart/add_const.dart';
import 'package:analysis_server/src/services/correction/dart/add_diagnostic_property_reference.dart';
import 'package:analysis_server/src/services/correction/dart/add_enum_constant.dart';
import 'package:analysis_server/src/services/correction/dart/add_eol_at_end_of_file.dart';
import 'package:analysis_server/src/services/correction/dart/add_explicit_call.dart';
import 'package:analysis_server/src/services/correction/dart/add_explicit_cast.dart';
import 'package:analysis_server/src/services/correction/dart/add_extension_override.dart';
import 'package:analysis_server/src/services/correction/dart/add_field_formal_parameters.dart';
import 'package:analysis_server/src/services/correction/dart/add_key_to_constructors.dart';
import 'package:analysis_server/src/services/correction/dart/add_late.dart';
import 'package:analysis_server/src/services/correction/dart/add_leading_newline_to_string.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_enum_case_clauses.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_enum_like_case_clauses.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_parameter_named.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_required_argument.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_switch_cases.dart';
import 'package:analysis_server/src/services/correction/dart/add_ne_null.dart';
import 'package:analysis_server/src/services/correction/dart/add_null_check.dart';
import 'package:analysis_server/src/services/correction/dart/add_override.dart';
import 'package:analysis_server/src/services/correction/dart/add_reopen.dart';
import 'package:analysis_server/src/services/correction/dart/add_required.dart';
import 'package:analysis_server/src/services/correction/dart/add_required_keyword.dart';
import 'package:analysis_server/src/services/correction/dart/add_return_null.dart';
import 'package:analysis_server/src/services/correction/dart/add_return_type.dart';
import 'package:analysis_server/src/services/correction/dart/add_static.dart';
import 'package:analysis_server/src/services/correction/dart/add_super_constructor_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/add_super_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/add_switch_case_break.dart';
import 'package:analysis_server/src/services/correction/dart/add_trailing_comma.dart';
import 'package:analysis_server/src/services/correction/dart/add_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/change_argument_name.dart';
import 'package:analysis_server/src/services/correction/dart/change_to.dart';
import 'package:analysis_server/src/services/correction/dart/change_to_nearest_precise_value.dart';
import 'package:analysis_server/src/services/correction/dart/change_to_static_access.dart';
import 'package:analysis_server/src/services/correction/dart/change_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/convert_add_all_to_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_class_to_enum.dart';
import 'package:analysis_server/src/services/correction/dart/convert_conditional_expression_to_if_element.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_line.dart';
import 'package:analysis_server/src/services/correction/dart/convert_flutter_child.dart';
import 'package:analysis_server/src/services/correction/dart/convert_flutter_children.dart';
import 'package:analysis_server/src/services/correction/dart/convert_for_each_to_for_loop.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_block_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_is_not.dart';
import 'package:analysis_server/src/services/correction/dart/convert_map_from_iterable_to_for_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_quotes.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_boolean_expression.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_cascade.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_constant_pattern.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_contains.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_expression_function_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_function_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_generic_function_syntax.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_if_null.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_initializing_formal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_int_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_named_arguments.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_on_type.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_package_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_raw_string.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_relative_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_set_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_super_parameters.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_where_type.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_wildcard_pattern.dart';
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
import 'package:analysis_server/src/services/correction/dart/extract_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_remove_widget.dart';
import 'package:analysis_server/src/services/correction/dart/ignore_diagnostic.dart';
import 'package:analysis_server/src/services/correction/dart/import_library.dart';
import 'package:analysis_server/src/services/correction/dart/inline_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/inline_typedef.dart';
import 'package:analysis_server/src/services/correction/dart/insert_semicolon.dart';
import 'package:analysis_server/src/services/correction/dart/make_class_abstract.dart';
import 'package:analysis_server/src/services/correction/dart/make_conditional_on_debug_mode.dart';
import 'package:analysis_server/src/services/correction/dart/make_field_not_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_field_public.dart';
import 'package:analysis_server/src/services/correction/dart/make_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_required_named_parameters_first.dart';
import 'package:analysis_server/src/services/correction/dart/make_return_type_nullable.dart';
import 'package:analysis_server/src/services/correction/dart/make_super_invocation_last.dart';
import 'package:analysis_server/src/services/correction/dart/make_variable_not_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_variable_nullable.dart';
import 'package:analysis_server/src/services/correction/dart/move_annotation_to_library_directive.dart';
import 'package:analysis_server/src/services/correction/dart/move_doc_comment_to_library_directive.dart';
import 'package:analysis_server/src/services/correction/dart/move_type_arguments_to_class.dart';
import 'package:analysis_server/src/services/correction/dart/organize_imports.dart';
import 'package:analysis_server/src/services/correction/dart/qualify_reference.dart';
import 'package:analysis_server/src/services/correction/dart/remove_abstract.dart';
import 'package:analysis_server/src/services/correction/dart/remove_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_argument.dart';
import 'package:analysis_server/src/services/correction/dart/remove_assertion.dart';
import 'package:analysis_server/src/services/correction/dart/remove_assignment.dart';
import 'package:analysis_server/src/services/correction/dart/remove_await.dart';
import 'package:analysis_server/src/services/correction/dart/remove_break.dart';
import 'package:analysis_server/src/services/correction/dart/remove_character.dart';
import 'package:analysis_server/src/services/correction/dart/remove_comparison.dart';
import 'package:analysis_server/src/services/correction/dart/remove_const.dart';
import 'package:analysis_server/src/services/correction/dart/remove_constructor_name.dart';
import 'package:analysis_server/src/services/correction/dart/remove_dead_code.dart';
import 'package:analysis_server/src/services/correction/dart/remove_dead_if_null.dart';
import 'package:analysis_server/src/services/correction/dart/remove_default_value.dart';
import 'package:analysis_server/src/services/correction/dart/remove_deprecated_new_in_comment_reference.dart';
import 'package:analysis_server/src/services/correction/dart/remove_duplicate_case.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_catch.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_constructor_body.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_else.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_statement.dart';
import 'package:analysis_server/src/services/correction/dart/remove_if_null_operator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_initializer.dart';
import 'package:analysis_server/src/services/correction/dart/remove_interpolation_braces.dart';
import 'package:analysis_server/src/services/correction/dart/remove_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_late.dart';
import 'package:analysis_server/src/services/correction/dart/remove_leading_underscore.dart';
import 'package:analysis_server/src/services/correction/dart/remove_method_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/remove_name_from_combinator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_name_from_declaration_clause.dart';
import 'package:analysis_server/src/services/correction/dart/remove_non_null_assertion.dart';
import 'package:analysis_server/src/services/correction/dart/remove_operator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_parameters_in_getter_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/remove_parentheses_in_getter_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_print.dart';
import 'package:analysis_server/src/services/correction/dart/remove_question_mark.dart';
import 'package:analysis_server/src/services/correction/dart/remove_required.dart';
import 'package:analysis_server/src/services/correction/dart/remove_returned_value.dart';
import 'package:analysis_server/src/services/correction/dart/remove_set_literal.dart';
import 'package:analysis_server/src/services/correction/dart/remove_this_expression.dart';
import 'package:analysis_server/src/services/correction/dart/remove_to_list.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_arguments.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_cast.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_final.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_late.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_library_directive.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_new.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_parentheses.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_raw_string.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_string_escape.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_string_interpolation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_wildcard_pattern.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_catch_clause.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_catch_stack.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_import.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_label.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/remove_var.dart';
import 'package:analysis_server/src/services/correction/dart/rename_method_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/rename_to_camel_case.dart';
import 'package:analysis_server/src/services/correction/dart/replace_Null_with_void.dart';
import 'package:analysis_server/src/services/correction/dart/replace_boolean_with_bool.dart';
import 'package:analysis_server/src/services/correction/dart/replace_cascade_with_dot.dart';
import 'package:analysis_server/src/services/correction/dart/replace_colon_with_equals.dart';
import 'package:analysis_server/src/services/correction/dart/replace_container_with_sized_box.dart';
import 'package:analysis_server/src/services/correction/dart/replace_empty_map_pattern.dart';
import 'package:analysis_server/src/services/correction/dart/replace_final_with_const.dart';
import 'package:analysis_server/src/services/correction/dart/replace_final_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/replace_new_with_const.dart';
import 'package:analysis_server/src/services/correction/dart/replace_null_check_with_cast.dart';
import 'package:analysis_server/src/services/correction/dart/replace_null_with_closure.dart';
import 'package:analysis_server/src/services/correction/dart/replace_return_type.dart';
import 'package:analysis_server/src/services/correction/dart/replace_return_type_future.dart';
import 'package:analysis_server/src/services/correction/dart/replace_return_type_iterable.dart';
import 'package:analysis_server/src/services/correction/dart/replace_return_type_stream.dart';
import 'package:analysis_server/src/services/correction/dart/replace_var_with_dynamic.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_arrow.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_brackets.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_conditional_assignment.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_decorated_box.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_eight_digit_hex.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_extension_name.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_identifier.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_interpolation.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_is_empty.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_is_nan.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_not_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_part_of_uri.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_tear_off.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_unicode_escape.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_wildcard.dart';
import 'package:analysis_server/src/services/correction/dart/sort_child_property_last.dart';
import 'package:analysis_server/src/services/correction/dart/sort_combinators.dart';
import 'package:analysis_server/src/services/correction/dart/sort_constructor_first.dart';
import 'package:analysis_server/src/services/correction/dart/sort_unnamed_constructor_first.dart';
import 'package:analysis_server/src/services/correction/dart/split_multiple_declarations.dart';
import 'package:analysis_server/src/services/correction/dart/surround_with_parentheses.dart';
import 'package:analysis_server/src/services/correction/dart/update_sdk_constraints.dart';
import 'package:analysis_server/src/services/correction/dart/use_curly_braces.dart';
import 'package:analysis_server/src/services/correction/dart/use_effective_integer_division.dart';
import 'package:analysis_server/src/services/correction/dart/use_eq_eq_null.dart';
import 'package:analysis_server/src/services/correction/dart/use_is_not_empty.dart';
import 'package:analysis_server/src/services/correction/dart/use_not_eq_null.dart';
import 'package:analysis_server/src/services/correction/dart/use_rethrow.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_future.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_text.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_unawaited.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/ffi_code.g.dart';
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
      selectionOffset: error.offset,
      selectionLength: error.length,
      workspace: workspace,
    );
    if (correctionContext == null) {
      return const <Fix>[];
    }

    var generators = _getGenerators(error.errorCode);

    var fixes = <Fix>[];
    for (var generator in generators) {
      if (generator().canBeAppliedToFile) {
        _FixState fixState = _EmptyFixState(
          ChangeBuilder(workspace: workspace),
        );
        for (var error in errors) {
          var fixContext = DartFixContextImpl(
            instrumentationService,
            workspace,
            resolveResult,
            error,
          );
          fixState = await _fixError(fixContext, fixState, generator(), error);
        }
        if (fixState is _NotEmptyFixState) {
          var sourceChange = fixState.builder.sourceChange;
          if (sourceChange.edits.isNotEmpty && fixState.fixCount > 1) {
            var fixKind = fixState.fixKind;
            sourceChange.id = fixKind.id;
            sourceChange.message = fixKind.message;
            fixes.add(Fix(fixKind, sourceChange));
          }
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

  List<ProducerGenerator> _getGenerators(ErrorCode errorCode) {
    if (errorCode is LintCode) {
      return FixProcessor.lintProducerMap[errorCode.uniqueLintName] ?? [];
    } else {
      // todo (pq): consider support for multiGenerators
      return FixProcessor.nonLintProducerMap[errorCode] ?? [];
    }
  }
}

/// The computer for Dart fixes.
class FixProcessor extends BaseProcessor {
  static final Map<String, List<MultiProducerGenerator>> lintMultiProducerMap =
      {
    LintNames.deprecated_member_use_from_same_package: [
      DataDriven.new,
    ],
    LintNames.deprecated_member_use_from_same_package_with_message: [
      DataDriven.new,
    ],
  };

  /// A map from the names of lint rules to a list of the generators that are
  /// used to create correction producers. The generators are then used to build
  /// fixes for those diagnostics. The generators used for non-lint diagnostics
  /// are in the [nonLintProducerMap].
  ///
  /// The keys of the map are the unique names of the lint codes without the
  /// `LintCode.` prefix. Generally the unique name is the same as the name of
  /// the lint, so most of the keys are constants defined by [LintNames]. But
  /// when a lint produces multiple codes, each with a different unique name,
  /// the unique name must be used here.
  static final Map<String, List<ProducerGenerator>> lintProducerMap = {
    LintNames.always_declare_return_types: [
      AddReturnType.new,
    ],
    LintNames.always_put_control_body_on_new_line: [
      UseCurlyBraces.nonBulk,
    ],
    LintNames.always_put_required_named_parameters_first: [
      MakeRequiredNamedParametersFirst.new,
    ],
    LintNames.always_require_non_null_named_parameters: [
      AddRequired.new,
    ],
    LintNames.always_specify_types: [
      AddTypeAnnotation.bulkFixable,
    ],
    LintNames.always_use_package_imports: [
      ConvertToPackageImport.new,
    ],
    LintNames.annotate_overrides: [
      AddOverride.new,
    ],
    LintNames.avoid_annotating_with_dynamic: [
      RemoveTypeAnnotation.other,
    ],
    LintNames.avoid_empty_else: [
      RemoveEmptyElse.new,
    ],
    LintNames.avoid_escaping_inner_quotes: [
      ConvertQuotes.new,
    ],
    LintNames.avoid_function_literals_in_foreach_calls: [
      ConvertForEachToForLoop.new,
    ],
    LintNames.avoid_init_to_null: [
      RemoveInitializer.bulkFixable,
    ],
    LintNames.avoid_multiple_declarations_per_line: [
      SplitMultipleDeclarations.new,
    ],
    LintNames.avoid_null_checks_in_equality_operators: [
      RemoveComparison.new,
    ],
    LintNames.avoid_print: [
      MakeConditionalOnDebugMode.new,
      RemovePrint.new,
    ],
    LintNames.avoid_private_typedef_functions: [
      InlineTypedef.new,
    ],
    LintNames.avoid_redundant_argument_values: [
      RemoveArgument.new,
    ],
    LintNames.avoid_relative_lib_imports: [
      ConvertToPackageImport.new,
    ],
    LintNames.avoid_renaming_method_parameters: [
      RenameMethodParameter.new,
    ],
    LintNames.avoid_return_types_on_setters: [
      RemoveTypeAnnotation.other,
    ],
    LintNames.avoid_returning_null_for_future: [
      // TODO(brianwilkerson) Consider applying in bulk.
      AddAsync.new,
      WrapInFuture.new,
    ],
    LintNames.avoid_returning_null_for_void: [
      RemoveReturnedValue.new,
    ],
    LintNames.avoid_single_cascade_in_expression_statements: [
      // TODO(brianwilkerson) This fix should be applied to some non-lint
      //  diagnostics and should also be available as an assist.
      ReplaceCascadeWithDot.new,
    ],
    LintNames.avoid_types_as_parameter_names: [
      ConvertToOnType.new,
    ],
    LintNames.avoid_types_on_closure_parameters: [
      ReplaceWithIdentifier.new,
      RemoveTypeAnnotation.other,
    ],
    LintNames.avoid_unused_constructor_parameters: [
      RemoveUnusedParameter.new,
    ],
    LintNames.avoid_unnecessary_containers: [
      FlutterRemoveWidget.new,
    ],
    LintNames.avoid_void_async: [
      ReplaceReturnTypeFuture.new,
    ],
    LintNames.await_only_futures: [
      RemoveAwait.new,
    ],
    LintNames.cascade_invocations: [
      ConvertToCascade.new,
    ],
    LintNames.cast_nullable_to_non_nullable: [
      AddNullCheck.withoutAssignabilityCheck,
    ],
    LintNames.combinators_ordering: [
      SortCombinators.new,
    ],
    LintNames.curly_braces_in_flow_control_structures: [
      UseCurlyBraces.new,
    ],
    LintNames.dangling_library_doc_comments: [
      MoveDocCommentToLibraryDirective.new,
    ],
    LintNames.diagnostic_describe_all_properties: [
      AddDiagnosticPropertyReference.new,
    ],
    LintNames.directives_ordering: [
      OrganizeImports.new,
    ],
    LintNames.discarded_futures: [
      AddAsync.new,
      WrapInUnawaited.new,
    ],
    LintNames.empty_catches: [
      RemoveEmptyCatch.new,
    ],
    LintNames.empty_constructor_bodies: [
      RemoveEmptyConstructorBody.new,
    ],
    LintNames.empty_statements: [
      RemoveEmptyStatement.new,
      ReplaceWithBrackets.new,
    ],
    LintNames.eol_at_end_of_file: [
      AddEolAtEndOfFile.new,
    ],
    LintNames.exhaustive_cases: [
      AddMissingEnumLikeCaseClauses.new,
    ],
    LintNames.hash_and_equals: [
      CreateMethod.equalsOrHashCode,
    ],
    LintNames.implicit_call_tearoffs: [
      AddExplicitCall.new,
    ],
    LintNames.implicit_reopen: [
      AddReopen.new,
    ],
    LintNames.invalid_case_patterns: [
      AddConst.new,
    ],
    LintNames.leading_newlines_in_multiline_strings: [
      AddLeadingNewlineToString.new,
    ],
    LintNames.library_annotations: [
      MoveAnnotationToLibraryDirective.new,
    ],
    LintNames.no_duplicate_case_values: [
      RemoveDuplicateCase.new,
    ],
    LintNames.no_leading_underscores_for_library_prefixes: [
      RemoveLeadingUnderscore.new,
    ],
    LintNames.no_literal_bool_comparisons: [
      ConvertToBooleanExpression.new,
    ],
    LintNames.no_leading_underscores_for_local_identifiers: [
      RemoveLeadingUnderscore.new,
    ],
    LintNames.non_constant_identifier_names: [
      RenameToCamelCase.new,
    ],
    LintNames.noop_primitive_operations: [
      RemoveInvocation.new,
    ],
    LintNames.null_check_on_nullable_type_parameter: [
      ReplaceNullCheckWithCast.new,
    ],
    LintNames.null_closures: [
      ReplaceNullWithClosure.new,
    ],
    LintNames.omit_local_variable_types: [
      ReplaceWithVar.new,
    ],
    LintNames.prefer_adjacent_string_concatenation: [
      RemoveOperator.new,
    ],
    LintNames.prefer_collection_literals: [
      ConvertToMapLiteral.new,
      ConvertToSetLiteral.new,
    ],
    LintNames.prefer_conditional_assignment: [
      ReplaceWithConditionalAssignment.new,
    ],
    LintNames.prefer_const_constructors: [
      AddConst.new,
      ReplaceNewWithConst.new,
    ],
    LintNames.prefer_const_constructors_in_immutables: [
      AddConst.new,
    ],
    LintNames.prefer_const_declarations: [
      ReplaceFinalWithConst.new,
    ],
    LintNames.prefer_const_literals_to_create_immutables: [
      AddConst.new,
    ],
    LintNames.prefer_contains: [
      ConvertToContains.new,
    ],
    LintNames.prefer_double_quotes: [
      ConvertToDoubleQuotes.new,
    ],
    LintNames.prefer_expression_function_bodies: [
      ConvertToExpressionFunctionBody.new,
    ],
    LintNames.prefer_final_fields: [
      MakeFinal.new,
    ],
    LintNames.prefer_final_in_for_each: [
      MakeFinal.new,
    ],
    LintNames.prefer_final_locals: [
      MakeFinal.new,
    ],
    LintNames.prefer_final_parameters: [
      MakeFinal.new,
    ],
    LintNames.prefer_for_elements_to_map_fromIterable: [
      ConvertMapFromIterableToForLiteral.new,
    ],
    LintNames.prefer_function_declarations_over_variables: [
      ConvertToFunctionDeclaration.new,
    ],
    LintNames.prefer_generic_function_type_aliases: [
      ConvertToGenericFunctionSyntax.new,
    ],
    LintNames.prefer_if_elements_to_conditional_expressions: [
      ConvertConditionalExpressionToIfElement.new,
    ],
    LintNames.prefer_if_null_operators: [
      ConvertToIfNull.new,
    ],
    LintNames.prefer_initializing_formals: [
      ConvertToInitializingFormal.new,
    ],
    LintNames.prefer_inlined_adds: [
      ConvertAddAllToSpread.new,
      InlineInvocation.new,
    ],
    LintNames.prefer_int_literals: [
      ConvertToIntLiteral.new,
    ],
    LintNames.prefer_interpolation_to_compose_strings: [
      ReplaceWithInterpolation.new,
    ],
    LintNames.prefer_is_empty: [
      ReplaceWithIsEmpty.new,
    ],
    LintNames.prefer_is_not_empty: [
      UseIsNotEmpty.new,
    ],
    LintNames.prefer_is_not_operator: [
      ConvertIntoIsNot.new,
    ],
    LintNames.prefer_iterable_whereType: [
      ConvertToWhereType.new,
    ],
    LintNames.prefer_null_aware_operators: [
      ConvertToNullAware.new,
    ],
    LintNames.prefer_relative_imports: [
      ConvertToRelativeImport.new,
    ],
    LintNames.prefer_single_quotes: [
      ConvertToSingleQuotes.new,
    ],
    LintNames.prefer_spread_collections: [
      ConvertAddAllToSpread.new,
    ],
    LintNames.prefer_typing_uninitialized_variables: [
      AddTypeAnnotation.bulkFixable,
    ],
    LintNames.prefer_void_to_null: [
      ReplaceNullWithVoid.new,
    ],
    LintNames.require_trailing_commas: [
      AddTrailingComma.new,
    ],
    LintNames.sized_box_for_whitespace: [
      ReplaceContainerWithSizedBox.new,
    ],
    LintNames.slash_for_doc_comments: [
      ConvertDocumentationIntoLine.new,
    ],
    LintNames.sort_child_properties_last: [
      SortChildPropertyLast.new,
    ],
    LintNames.sort_constructors_first: [
      SortConstructorFirst.new,
    ],
    LintNames.sort_unnamed_constructors_first: [
      SortUnnamedConstructorFirst.new,
    ],
    LintNames.type_annotate_public_apis: [
      AddTypeAnnotation.bulkFixable,
    ],
    LintNames.type_init_formals: [
      RemoveTypeAnnotation.other,
    ],
    LintNames.type_literal_in_constant_pattern: [
      ConvertToConstantPattern.new,
      ConvertToWildcardPattern.new,
    ],
    LintNames.unawaited_futures: [
      AddAwait.unawaited,
      WrapInUnawaited.new,
    ],
    LintNames.unnecessary_brace_in_string_interps: [
      RemoveInterpolationBraces.new,
    ],
    LintNames.unnecessary_breaks: [
      RemoveBreak.new,
    ],
    LintNames.unnecessary_const: [
      RemoveUnnecessaryConst.new,
    ],
    LintNames.unnecessary_constructor_name: [
      RemoveConstructorName.new,
    ],
    LintNames.unnecessary_final: [
      ReplaceFinalWithVar.new,
    ],
    LintNames.unnecessary_getters_setters: [
      MakeFieldPublic.new,
    ],
    LintNames.unnecessary_lambdas: [
      ReplaceWithTearOff.new,
    ],
    LintNames.unnecessary_late: [
      RemoveUnnecessaryLate.new,
    ],
    LintNames.unnecessary_library_directive: [
      RemoveUnnecessaryLibraryDirective.new,
    ],
    LintNames.unnecessary_new: [
      RemoveUnnecessaryNew.new,
    ],
    LintNames.unnecessary_null_aware_assignments: [
      RemoveAssignment.new,
    ],
    LintNames.unnecessary_null_checks: [
      RemoveNonNullAssertion.new,
    ],
    LintNames.unnecessary_null_in_if_null_operators: [
      RemoveIfNullOperator.new,
    ],
    LintNames.unnecessary_nullable_for_final_variable_declarations: [
      RemoveQuestionMark.new,
    ],
    LintNames.unnecessary_overrides: [
      RemoveMethodDeclaration.new,
    ],
    LintNames.unnecessary_parenthesis: [
      RemoveUnnecessaryParentheses.new,
    ],
    LintNames.unnecessary_raw_strings: [
      RemoveUnnecessaryRawString.new,
    ],
    LintNames.unnecessary_string_escapes: [
      RemoveUnnecessaryStringEscape.new,
    ],
    LintNames.unnecessary_string_interpolations: [
      RemoveUnnecessaryStringInterpolation.new,
    ],
    LintNames.unnecessary_to_list_in_spreads: [
      RemoveToList.new,
    ],
    LintNames.unnecessary_this: [
      RemoveThisExpression.new,
    ],
    LintNames.use_decorated_box: [
      ReplaceWithDecoratedBox.new,
    ],
    LintNames.use_enums: [
      ConvertClassToEnum.new,
    ],
    LintNames.use_full_hex_values_for_flutter_colors: [
      ReplaceWithEightDigitHex.new,
    ],
    LintNames.use_function_type_syntax_for_parameters: [
      ConvertToGenericFunctionSyntax.new,
    ],
    LintNames.use_key_in_widget_constructors: [
      AddKeyToConstructors.new,
    ],
    LintNames.use_raw_strings: [
      ConvertToRawString.new,
    ],
    LintNames.use_rethrow_when_possible: [
      UseRethrow.new,
    ],
    LintNames.use_string_in_part_of_directives: [
      ReplaceWithPartOrUriEmpty.new,
    ],
    LintNames.use_super_parameters: [
      ConvertToSuperParameters.new,
    ],
  };

  /// A map from error codes to a list of generators used to create multiple
  /// correction producers used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintMultiProducerMap].
  static const Map<ErrorCode, List<MultiProducerGenerator>>
      nonLintMultiProducerMap = {
    CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS: [
      AddExtensionOverride.new,
    ],
    CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.CAST_TO_NON_TYPE: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.CONST_WITH_NON_TYPE: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.EXTENDS_NON_CLASS: [
      DataDriven.new,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS: [
      AddMissingParameter.new,
      DataDriven.new,
    ],
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
      AddMissingParameter.new,
      DataDriven.new,
    ],
    CompileTimeErrorCode.IMPLEMENTS_NON_CLASS: [
      DataDriven.new,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS: [
      AddSuperConstructorInvocation.new,
    ],
    CompileTimeErrorCode.INVALID_ANNOTATION: [
      ImportLibrary.forTopLevelVariable,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.INVALID_OVERRIDE: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.INVALID_OVERRIDE_SETTER: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.MIXIN_OF_NON_CLASS: [
      DataDriven.new,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.NEW_WITH_NON_TYPE: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT: [
      AddSuperConstructorInvocation.new,
    ],
    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT: [
      AddSuperConstructorInvocation.new,
      CreateConstructorSuper.new,
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
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_PLURAL: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_PLURAL: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_SINGULAR: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME: [
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_ANNOTATION: [
      ImportLibrary.forTopLevelVariable,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_CLASS: [
      DataDriven.new,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT: [
      AddSuperConstructorInvocation.new,
    ],
    CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_FUNCTION: [
      DataDriven.new,
      ImportLibrary.forExtension,
      ImportLibrary.forFunction,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_GETTER: [
      DataDriven.new,
      ImportLibrary.forExtensionMember,
      ImportLibrary.forTopLevelVariable,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_IDENTIFIER: [
      DataDriven.new,
      ImportLibrary.forExtension,
      ImportLibrary.forExtensionMember,
      ImportLibrary.forFunction,
      ImportLibrary.forTopLevelVariable,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_METHOD: [
      DataDriven.new,
      ImportLibrary.forExtensionMember,
      ImportLibrary.forFunction,
      ImportLibrary.forType,
    ],
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      ChangeArgumentName.new,
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_OPERATOR: [
      ImportLibrary.forExtensionMember,
    ],
    CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_SETTER: [
      DataDriven.new,
      // TODO(brianwilkerson) Support ImportLibrary for non-extension members.
      ImportLibrary.forExtensionMember,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD: [
      DataDriven.new,
    ],
    HintCode.DEPRECATED_MEMBER_USE: [
      DataDriven.new,
    ],
    HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE: [
      DataDriven.new,
    ],
    WarningCode.OVERRIDE_ON_NON_OVERRIDING_METHOD: [
      DataDriven.new,
    ],
    WarningCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE: [
      ImportLibrary.dartAsync,
    ],
  };

  /// A map from error codes to a list of the generators that are used to create
  /// correction producers. The generators are then used to build fixes for
  /// those diagnostics. The generators used for lint rules are in the
  /// [lintProducerMap].
  static const Map<ErrorCode, List<ProducerGenerator>> nonLintProducerMap = {
    CompileTimeErrorCode.ABSTRACT_FIELD_INITIALIZER: [
      RemoveAbstract.new,
      RemoveInitializer.new,
    ],
    CompileTimeErrorCode.ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER: [
      RemoveAbstract.new,
      RemoveInitializer.new,
    ],
    CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR: [
      RemoveAssertion.new,
    ],
    CompileTimeErrorCode.ASSIGNMENT_TO_FINAL: [
      MakeFieldNotFinal.new,
      AddLate.new,
    ],
    CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL: [
      MakeVariableNotFinal.new,
    ],
    CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE: [
      AddExplicitCast.new,
      AddNullCheck.new,
      WrapInText.new,
    ],
    CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT: [
      AddAsync.new,
    ],
    CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT: [
      AddAsync.new,
    ],
    CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY: [
      AddAsync.missingReturn,
    ],
    CompileTimeErrorCode.CAST_TO_NON_TYPE: [
      ChangeTo.classOrMixin,
      CreateClass.new,
      CreateMixin.new,
    ],
    CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER: [
      ConvertIntoBlockBody.new,
      CreateNoSuchMethod.new,
      MakeClassAbstract.new,
    ],
    CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE: [
      RemoveConst.new,
      RemoveNew.new,
    ],
    CompileTimeErrorCode.CONST_INSTANCE_FIELD: [
      AddStatic.new,
    ],
    CompileTimeErrorCode.CONST_WITH_NON_CONST: [
      RemoveConst.new,
    ],
    CompileTimeErrorCode.CONST_WITH_NON_TYPE: [
      ChangeTo.classOrMixin,
      CreateClass.new,
    ],
    CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION: [
      AddConst.new,
    ],
    CompileTimeErrorCode.DEFAULT_VALUE_ON_REQUIRED_PARAMETER: [
      RemoveDefaultValue.new,
      RemoveRequired.new,
    ],
    CompileTimeErrorCode.EMPTY_MAP_PATTERN: [
      ReplaceEmptyMapPattern.any,
      ReplaceEmptyMapPattern.empty,
    ],
    CompileTimeErrorCode.ENUM_WITH_ABSTRACT_MEMBER: [
      ConvertIntoBlockBody.new,
    ],
    CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.EXTENDS_NON_CLASS: [
      ChangeTo.classOrMixin,
      CreateClass.new,
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER: [
      ReplaceWithExtensionName.new,
    ],
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS: [
      CreateConstructor.new,
    ],
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
      CreateConstructor.new,
      ConvertToNamedArguments.new,
    ],
    CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.FINAL_NOT_INITIALIZED: [
      AddLate.new,
      CreateConstructorForFinalFields.new,
    ],
    CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1: [
      AddFieldFormalParameters.new,
    ],
    CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2: [
      AddFieldFormalParameters.new,
    ],
    CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS: [
      AddFieldFormalParameters.new,
    ],
    CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE: [
      ReplaceReturnTypeStream.new,
    ],
    CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE: [
      ReplaceReturnTypeFuture.new,
    ],
    CompileTimeErrorCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE: [
      ReplaceReturnTypeIterable.new,
    ],
    CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.IMPLEMENTS_NON_CLASS: [
      ChangeTo.classOrMixin,
      CreateClass.new,
    ],
    CompileTimeErrorCode.IMPLEMENTS_REPEATED: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS: [
      AddSuperParameter.new,
    ],
    CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD: [
      ChangeTo.field,
      CreateField.new,
    ],
    CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER: [
      ChangeToStaticAccess.new,
    ],
    CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE: [
      ChangeToNearestPreciseValue.new,
    ],
    CompileTimeErrorCode.INVALID_ANNOTATION: [
      ChangeTo.annotation,
      CreateClass.new,
    ],
    CompileTimeErrorCode.INVALID_ASSIGNMENT: [
      AddExplicitCast.new,
      AddNullCheck.new,
      ChangeTypeAnnotation.new,
      MakeVariableNullable.new,
    ],
    CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION: [
      RemoveParenthesesInGetterInvocation.new,
    ],
    CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER: [
      AddRequiredKeyword.new,
      MakeVariableNullable.new,
    ],
    CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL: [
      MakeVariableNullable.new,
    ],
    CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_WITH_ANNOTATION: [
      AddRequiredKeyword.new,
    ],
    CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT: [
      AddMissingRequiredArgument.new,
    ],
    CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE: [
      ExtendClassForMixin.new,
    ],
    CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.MIXIN_OF_NON_CLASS: [
      ChangeTo.classOrMixin,
      CreateClass.new,
    ],
    CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE: [
      RemoveNameFromDeclarationClause.new,
    ],
    CompileTimeErrorCode.NEW_WITH_NON_TYPE: [
      ChangeTo.classOrMixin,
      CreateClass.new,
    ],
    CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR: [
      CreateConstructor.new,
    ],
    CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS:
        [
      CreateMissingOverrides.new,
      CreateNoSuchMethod.new,
      MakeClassAbstract.new,
    ],
    CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR: [
      CreateMissingOverrides.new,
      CreateNoSuchMethod.new,
      MakeClassAbstract.new,
    ],
    CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE: [
      CreateMissingOverrides.new,
      CreateNoSuchMethod.new,
      MakeClassAbstract.new,
    ],
    CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE: [
      CreateMissingOverrides.new,
      CreateNoSuchMethod.new,
      MakeClassAbstract.new,
    ],
    CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO: [
      CreateMissingOverrides.new,
      CreateNoSuchMethod.new,
      MakeClassAbstract.new,
    ],
    CompileTimeErrorCode.NON_BOOL_CONDITION: [
      AddNeNull.new,
      AddAwait.nonBool,
    ],
    CompileTimeErrorCode.NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR: [
      AddConst.new,
    ],
    CompileTimeErrorCode.NON_CONSTANT_MAP_PATTERN_KEY: [
      AddConst.new,
    ],
    CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION: [
      AddConst.new,
    ],
    CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION: [
      AddMissingSwitchCases.new,
    ],
    CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT: [
      AddMissingSwitchCases.new,
    ],
    CompileTimeErrorCode.NON_FINAL_FIELD_IN_ENUM: [
      MakeFinal.new,
    ],
    CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT: [
      CreateClass.new,
      CreateMixin.new,
    ],
    CompileTimeErrorCode.NOT_A_TYPE: [
      ChangeTo.classOrMixin,
      CreateClass.new,
      CreateMixin.new,
    ],
    CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD: [
      AddLate.new,
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE: [
      RemoveQuestionMark.new,
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE: [
      RemoveQuestionMark.new,
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE: [
      RemoveQuestionMark.new,
    ],
    CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE: [
      RemoveQuestionMark.new,
    ],
    CompileTimeErrorCode.OBSOLETE_COLON_FOR_DEFAULT_VALUE: [
      ReplaceColonWithEquals.new
    ],
    CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION: [
      MakeReturnTypeNullable.new,
      ReplaceReturnType.new,
    ],
    CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD: [
      MakeReturnTypeNullable.new,
      ReplaceReturnType.new,
    ],
    CompileTimeErrorCode
        .SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED: [
      RemoveTypeAnnotation.other,
    ],
    CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED: [
      ChangeTo.superFormalParameter,
    ],
    CompileTimeErrorCode.SUPER_INVOCATION_NOT_LAST: [
      MakeSuperInvocationLast.new,
    ],
    CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY: [
      AddSwitchCaseBreak.new,
    ],
    CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME: [
      ChangeTo.classOrMixin,
      CreateClass.new,
      CreateMixin.new,
    ],
    CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE: [
      AddNullCheck.new,
    ],
    CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE: [
      AddNullCheck.new,
      ExtractLocalVariable.new,
      ReplaceWithNullAware.single,
    ],
    CompileTimeErrorCode.UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE: [
      AddNullCheck.new,
    ],
    CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE: [
      AddNullCheck.new,
      ExtractLocalVariable.new,
      ReplaceWithNullAware.single,
    ],
    CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION: [
      AddNullCheck.new,
    ],
    CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR: [
      AddNullCheck.new,
    ],
    CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD: [
      AddNullCheck.new,
      ConvertToNullAwareSpread.new,
    ],
    CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH: [
      AddNullCheck.new,
    ],
    CompileTimeErrorCode.UNDEFINED_ANNOTATION: [
      ChangeTo.annotation,
      CreateClass.new,
    ],
    CompileTimeErrorCode.UNDEFINED_CLASS: [
      ChangeTo.classOrMixin,
      CreateClass.new,
      CreateMixin.new,
    ],
    CompileTimeErrorCode.UNDEFINED_CLASS_BOOLEAN: [
      ReplaceBooleanWithBool.new,
    ],
    CompileTimeErrorCode.UNDEFINED_ENUM_CONSTANT: [
      AddEnumConstant.new,
      ChangeTo.getterOrSetter,
    ],
    CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_NAMED: [
      CreateConstructor.new,
    ],
    CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED: [
      CreateConstructor.new,
    ],
    CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER: [
      ChangeTo.getterOrSetter,
      CreateGetter.new,
    ],
    CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD: [
      ChangeTo.method,
      CreateMethod.method,
    ],
    CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER: [
      ChangeTo.getterOrSetter,
      CreateSetter.new,
    ],
    CompileTimeErrorCode.UNDEFINED_FUNCTION: [
      ChangeTo.function,
      CreateClass.new,
      CreateFunction.new,
    ],
    CompileTimeErrorCode.UNDEFINED_GETTER: [
      ChangeTo.getterOrSetter,
      CreateClass.new,
      CreateField.new,
      CreateGetter.new,
      CreateLocalVariable.new,
      CreateMethodOrFunction.new,
      CreateMixin.new,
    ],
    CompileTimeErrorCode.UNDEFINED_IDENTIFIER: [
      ChangeTo.getterOrSetter,
      CreateClass.new,
      CreateField.new,
      CreateGetter.new,
      CreateLocalVariable.new,
      CreateMethodOrFunction.new,
      CreateMixin.new,
      CreateSetter.new,
    ],
    CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT: [
      AddAsync.new,
    ],
    CompileTimeErrorCode.UNDEFINED_METHOD: [
      ChangeTo.method,
      CreateClass.new,
      CreateFunction.new,
      CreateMethod.method,
    ],
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      AddMissingParameterNamed.new,
      ConvertFlutterChild.new,
      ConvertFlutterChildren.new,
    ],
    CompileTimeErrorCode.UNDEFINED_SETTER: [
      ChangeTo.getterOrSetter,
      CreateField.new,
      CreateSetter.new,
    ],
    CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER: [
      // TODO(brianwilkerson) Consider adding fixes to create a field, getter,
      //  method or setter. The existing _addFix methods would need to be
      //  updated so that only the appropriate subset is generated.
      QualifyReference.new,
    ],
    CompileTimeErrorCode
        .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE: [
      // TODO(brianwilkerson) Consider adding fixes to create a field, getter,
      //  method or setter. The existing producers would need to be updated so
      //  that only the appropriate subset is generated.
      QualifyReference.new,
    ],
    CompileTimeErrorCode.URI_DOES_NOT_EXIST: [
      CreateFile.new,
    ],
    ParserErrorCode.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT: [
      RemoveVar.new,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR: [
      MoveTypeArgumentsToClass.new,
      RemoveTypeArguments.new,
    ],
    CompileTimeErrorCode.YIELD_OF_INVALID_TYPE: [
      MakeReturnTypeNullable.new,
    ],
    FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS: [
      RemoveNameFromDeclarationClause.new,
    ],
    FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS: [
      RemoveNameFromDeclarationClause.new,
    ],
    FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH: [
      RemoveNameFromDeclarationClause.new,
    ],
    HintCode.CAN_BE_NULL_AFTER_NULL_AWARE: [
      ReplaceWithNullAware.inChain,
    ],
    HintCode.DEPRECATED_COLON_FOR_DEFAULT_VALUE: [
      ReplaceColonWithEquals.new,
    ],
    HintCode.DIVISION_OPTIMIZATION: [
      UseEffectiveIntegerDivision.new,
    ],
    HintCode.UNNECESSARY_IMPORT: [
      RemoveUnusedImport.new,
    ],
    ParserErrorCode.ABSTRACT_CLASS_MEMBER: [
      RemoveAbstract.bulkFixable,
    ],
    ParserErrorCode.DEFAULT_IN_SWITCH_EXPRESSION: [
      ReplaceWithWildcard.new,
    ],
    ParserErrorCode.EXPECTED_TOKEN: [
      InsertSemicolon.new,
      ReplaceWithArrow.new,
    ],
    ParserErrorCode.GETTER_WITH_PARAMETERS: [
      RemoveParametersInGetterDeclaration.new,
    ],
    ParserErrorCode.INVALID_CONSTANT_PATTERN_BINARY: [
      AddConst.new,
    ],
    ParserErrorCode.INVALID_CONSTANT_PATTERN_GENERIC: [
      AddConst.new,
    ],
    ParserErrorCode.INVALID_CONSTANT_PATTERN_NEGATION: [
      AddConst.new,
    ],
    ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN: [
      SurroundWithParentheses.new,
    ],
    ParserErrorCode.LATE_PATTERN_VARIABLE_DECLARATION: [
      RemoveLate.new,
    ],
    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE: [
      AddTypeAnnotation.new,
    ],
    ParserErrorCode.MISSING_FUNCTION_BODY: [
      ConvertIntoBlockBody.new,
    ],
    ParserErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA: [
      AddTrailingComma.new,
    ],
    ParserErrorCode.RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA: [
      AddTrailingComma.new,
    ],
    ParserErrorCode.VAR_AND_TYPE: [
      RemoveTypeAnnotation.fixVarAndType,
      RemoveVar.new,
    ],
    ParserErrorCode.VAR_AS_TYPE_NAME: [
      ReplaceVarWithDynamic.new,
    ],
    ParserErrorCode.VAR_RETURN_TYPE: [
      RemoveVar.new,
    ],
    StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION: [
      RemoveDeadIfNull.new,
    ],
    StaticWarningCode.INVALID_NULL_AWARE_OPERATOR: [
      ReplaceWithNotNullAware.new,
    ],
    StaticWarningCode.INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT: [
      ReplaceWithNotNullAware.new,
    ],
    StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH: [
      AddMissingEnumCaseClauses.new,
    ],
    StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION: [
      RemoveNonNullAssertion.new,
    ],
    StaticWarningCode.UNNECESSARY_NULL_CHECK_PATTERN: [
      RemoveQuestionMark.new,
    ],
    StaticWarningCode.UNNECESSARY_NULL_ASSERT_PATTERN: [
      RemoveNonNullAssertion.new,
    ],
    WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE: [
      AddReturnNull.new,
    ],
    WarningCode.DEAD_CODE: [
      RemoveDeadCode.new,
    ],
    WarningCode.DEAD_CODE_CATCH_FOLLOWING_CATCH: [
      // TODO(brianwilkerson) Add a fix to move the unreachable catch clause to
      //  a place where it can be reached (when possible).
      RemoveDeadCode.new,
    ],
    WarningCode.DEAD_CODE_ON_CATCH_SUBTYPE: [
      // TODO(brianwilkerson) Add a fix to move the unreachable catch clause to
      //  a place where it can be reached (when possible).
      RemoveDeadCode.new,
    ],
    WarningCode.DEPRECATED_IMPLEMENTS_FUNCTION: [
      RemoveNameFromDeclarationClause.new,
    ],
    WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE: [
      RemoveDeprecatedNewInCommentReference.new,
    ],
    WarningCode.DUPLICATE_HIDDEN_NAME: [
      RemoveNameFromCombinator.new,
    ],
    WarningCode.DUPLICATE_IMPORT: [
      RemoveUnusedImport.new,
    ],
    WarningCode.DUPLICATE_SHOWN_NAME: [
      RemoveNameFromCombinator.new,
    ],
    WarningCode.INVALID_ANNOTATION_TARGET: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_FACTORY_ANNOTATION: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_IMMUTABLE_ANNOTATION: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_INTERNAL_ANNOTATION: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_LITERAL_ANNOTATION: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_NON_VIRTUAL_ANNOTATION: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_REQUIRED_NAMED_PARAM: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_REQUIRED_POSITIONAL_PARAM: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_SEALED_ANNOTATION: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_VISIBILITY_ANNOTATION: [
      RemoveAnnotation.new,
    ],
    WarningCode.INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION: [
      RemoveAnnotation.new,
    ],
    WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE: [
      CreateMissingOverrides.new,
    ],
    WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_TWO: [
      CreateMissingOverrides.new,
    ],
    WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_THREE_PLUS: [
      CreateMissingOverrides.new,
    ],
    WarningCode.MISSING_REQUIRED_PARAM: [
      AddMissingRequiredArgument.new,
    ],
    WarningCode.MISSING_REQUIRED_PARAM_WITH_DETAILS: [
      AddMissingRequiredArgument.new,
    ],
    WarningCode.MISSING_RETURN: [
      AddAsync.missingReturn,
    ],
    WarningCode.MUST_CALL_SUPER: [
      AddCallSuper.new,
    ],
    WarningCode.NULLABLE_TYPE_IN_CATCH_CLAUSE: [
      RemoveQuestionMark.new,
    ],
    WarningCode.OVERRIDE_ON_NON_OVERRIDING_FIELD: [
      RemoveAnnotation.new,
    ],
    WarningCode.OVERRIDE_ON_NON_OVERRIDING_GETTER: [
      RemoveAnnotation.new,
    ],
    WarningCode.OVERRIDE_ON_NON_OVERRIDING_METHOD: [
      RemoveAnnotation.new,
    ],
    WarningCode.OVERRIDE_ON_NON_OVERRIDING_SETTER: [
      RemoveAnnotation.new,
    ],
    WarningCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA: [
      AddTrailingComma.new,
    ],
    WarningCode.SDK_VERSION_AS_EXPRESSION_IN_CONST_CONTEXT: [
      UpdateSdkConstraints.version_2_2_2,
    ],
    WarningCode.SDK_VERSION_ASYNC_EXPORTED_FROM_CORE: [
      UpdateSdkConstraints.version_2_1_0,
    ],
    WarningCode.SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT: [
      UpdateSdkConstraints.version_2_2_2,
    ],
    WarningCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT: [
      UpdateSdkConstraints.version_2_2_2,
    ],
    WarningCode.SDK_VERSION_EXTENSION_METHODS: [
      UpdateSdkConstraints.version_2_6_0,
    ],
    WarningCode.SDK_VERSION_GT_GT_GT_OPERATOR: [
      UpdateSdkConstraints.version_2_14_0,
    ],
    WarningCode.SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT: [
      UpdateSdkConstraints.version_2_2_2,
    ],
    WarningCode.SDK_VERSION_SET_LITERAL: [
      UpdateSdkConstraints.version_2_2_0,
    ],
    WarningCode.SDK_VERSION_UI_AS_CODE: [
      UpdateSdkConstraints.version_2_2_2,
    ],
    WarningCode.TEXT_DIRECTION_CODE_POINT_IN_COMMENT: [
      RemoveCharacter.new,
      ReplaceWithUnicodeEscape.new,
    ],
    WarningCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL: [
      RemoveCharacter.new,
      ReplaceWithUnicodeEscape.new,
    ],
    WarningCode.TYPE_CHECK_IS_NOT_NULL: [
      UseNotEqNull.new,
    ],
    WarningCode.TYPE_CHECK_IS_NULL: [
      UseEqEqNull.new,
    ],
    WarningCode.UNDEFINED_HIDDEN_NAME: [
      RemoveNameFromCombinator.new,
    ],
    WarningCode.UNDEFINED_SHOWN_NAME: [
      RemoveNameFromCombinator.new,
    ],
    WarningCode.UNNECESSARY_CAST: [
      RemoveUnnecessaryCast.new,
    ],
    WarningCode.UNNECESSARY_FINAL: [
      RemoveUnnecessaryFinal.new,
    ],
    WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE: [
      RemoveComparison.new,
      ReplaceWithIsNan.new,
    ],
    WarningCode.UNNECESSARY_NAN_COMPARISON_TRUE: [
      RemoveComparison.new,
      ReplaceWithIsNan.new,
    ],
    WarningCode.UNNECESSARY_NULL_COMPARISON_FALSE: [
      RemoveComparison.new,
    ],
    WarningCode.UNNECESSARY_NULL_COMPARISON_TRUE: [
      RemoveComparison.new,
    ],
    WarningCode.UNNECESSARY_QUESTION_MARK: [
      RemoveQuestionMark.new,
    ],
    WarningCode.UNNECESSARY_SET_LITERAL: [
      RemoveSetLiteral.new,
    ],
    WarningCode.UNNECESSARY_TYPE_CHECK_FALSE: [
      RemoveComparison.typeCheck,
    ],
    WarningCode.UNNECESSARY_TYPE_CHECK_TRUE: [
      RemoveComparison.typeCheck,
    ],
    WarningCode.UNNECESSARY_WILDCARD_PATTERN: [
      RemoveUnnecessaryWildcardPattern.new,
    ],
    WarningCode.UNREACHABLE_SWITCH_CASE: [
      RemoveDeadCode.new,
    ],
    WarningCode.UNUSED_CATCH_CLAUSE: [
      RemoveUnusedCatchClause.new,
    ],
    WarningCode.UNUSED_CATCH_STACK: [
      RemoveUnusedCatchStack.new,
    ],
    WarningCode.UNUSED_ELEMENT: [
      RemoveUnusedElement.new,
    ],
    WarningCode.UNUSED_ELEMENT_PARAMETER: [
      RemoveUnusedParameter.new,
    ],
    WarningCode.UNUSED_FIELD: [
      RemoveUnusedField.new,
    ],
    WarningCode.UNUSED_IMPORT: [
      RemoveUnusedImport.new,
    ],
    WarningCode.UNUSED_LABEL: [
      RemoveUnusedLabel.new,
    ],
    WarningCode.UNUSED_LOCAL_VARIABLE: [
      RemoveUnusedLocalVariable.new,
    ],
    WarningCode.UNUSED_SHOWN_NAME: [
      RemoveNameFromCombinator.new,
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
    fixes.sort(Fix.compareFixes);
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
      var generators = lintProducerMap[errorCode.uniqueLintName] ?? [];
      for (var generator in generators) {
        await compute(generator());
      }
    } else {
      var generators = nonLintProducerMap[errorCode] ?? [];
      for (var generator in generators) {
        await compute(generator());
      }
      var multiGenerators = nonLintMultiProducerMap[errorCode];
      if (multiGenerators != null) {
        for (var multiGenerator in multiGenerators) {
          var multiProducer = multiGenerator();
          multiProducer.configure(context);
          for (var producer in await multiProducer.producers) {
            await compute(producer);
          }
        }
      }
    }

    if (errorCode is LintCode ||
        errorCode is HintCode ||
        errorCode is WarningCode) {
      var generators = [
        IgnoreDiagnosticOnLine.new,
        IgnoreDiagnosticInFile.new,
      ];
      for (var generator in generators) {
        await compute(generator());
      }
    }
  }

  /// Associate the given correction producer [generator] with the lint with the
  /// given [lintName].
  static void registerFixForLint(String lintName, ProducerGenerator generator) {
    lintProducerMap.putIfAbsent(lintName, () => []).add(generator);
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

extension on LintCode {
  String get uniqueLintName {
    if (uniqueName.startsWith('LintCode.')) {
      return uniqueName.substring(9);
    }
    return uniqueName;
  }
}
