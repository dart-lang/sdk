// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "coverage_suite.dart";

// This is the currently recorded state
// using out/ReleaseX64/dart-sdk/bin/dart (which for instance makes a
// difference for compute_platform_binaries_location.dart).
const Map<String, ({int hitCount, int missCount})> _expect = {
  // 100.0%.
  "package:front_end/src/api_prototype/compiler_options.dart": (
    hitCount: 43,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/experimental_flags.dart": (
    hitCount: 66,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/file_system.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/incremental_kernel_generator.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/kernel_generator.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/language_version.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/lowering_predicates.dart": (
    hitCount: 13,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/memory_file_system.dart": (
    hitCount: 23,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/standard_file_system.dart": (
    hitCount: 43,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/summary_generator.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/terminal_color_support.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_unstable/compiler_state.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_unstable/dart2js.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/api_unstable/util.dart": (
    hitCount: 10,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/builder_graph.dart": (
    hitCount: 17,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/combinator.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/command_line_reporting.dart": (
    hitCount: 79,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/compiler_context.dart": (
    hitCount: 31,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/configuration.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/crash.dart": (
    hitCount: 52,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/export.dart": (
    hitCount: 20,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/file_system_dependency_tracker.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/hybrid_file_system.dart": (
    hitCount: 21,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/identifiers.dart": (
    hitCount: 78,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/ignored_parser_errors.dart": (
    hitCount: 3,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/import.dart": (
    hitCount: 48,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/import_chains.dart": (
    hitCount: 96,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/incremental_compiler.dart": (
    hitCount: 860,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/incremental_serializer.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/instrumentation.dart": (
    hitCount: 29,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/label_scope.dart": (
    hitCount: 30,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/library_graph.dart": (
    hitCount: 25,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/local_scope.dart": (
    hitCount: 59,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/messages.dart": (
    hitCount: 10,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/modifier.dart": (
    hitCount: 29,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/name_space.dart": (
    hitCount: 168,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/operator.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/problems.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/processed_options.dart": (
    hitCount: 246,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/scope.dart": (
    hitCount: 646,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/ticker.dart": (
    hitCount: 19,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/uri_offset.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/uri_translator.dart": (
    hitCount: 42,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/uris.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/augmentation_iterator.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/builder.dart": (
    hitCount: 29,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/builder_mixins.dart": (
    hitCount: 44,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/builtin_type_declaration_builder.dart": (
    hitCount: 7,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/class_builder.dart": (
    hitCount: 146,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/constructor_reference_builder.dart": (
    hitCount: 52,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/declaration_builder.dart": (
    hitCount: 25,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/dynamic_type_declaration_builder.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/extension_builder.dart": (
    hitCount: 3,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/extension_type_declaration_builder.dart": (
    hitCount: 17,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/fixed_type_builder.dart": (
    hitCount: 5,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/formal_parameter_builder.dart": (
    hitCount: 186,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/function_type_builder.dart": (
    hitCount: 99,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/future_or_type_declaration_builder.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/inferable_type_builder.dart": (
    hitCount: 27,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/invalid_type_builder.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/invalid_type_declaration_builder.dart": (
    hitCount: 17,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/library_builder.dart": (
    hitCount: 61,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/member_builder.dart": (
    hitCount: 149,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/metadata_builder.dart": (
    hitCount: 37,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/mixin_application_builder.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/modifier_builder.dart": (
    hitCount: 17,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/named_type_builder.dart": (
    hitCount: 399,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/never_type_declaration_builder.dart": (
    hitCount: 10,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/null_type_declaration_builder.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/nullability_builder.dart": (
    hitCount: 24,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/omitted_type_builder.dart": (
    hitCount: 42,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/omitted_type_declaration_builder.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/prefix_builder.dart": (
    hitCount: 49,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/record_type_builder.dart": (
    hitCount: 154,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_alias_builder.dart": (
    hitCount: 186,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_builder.dart": (
    hitCount: 56,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_declaration_builder.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_variable_builder.dart": (
    hitCount: 336,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/void_type_declaration_builder.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/codes/type_labeler.dart": (
    hitCount: 518,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/compute_platform_binaries_location.dart": (
    hitCount: 49,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_builder_mixins.dart": (
    hitCount: 16,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_class_builder.dart": (
    hitCount: 177,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_builder.dart": (
    hitCount: 81,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_member_builder.dart": (
    hitCount: 71,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_type_declaration_builder.dart": (
    hitCount: 154,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_type_member_builder.dart": (
    hitCount: 129,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_library_builder.dart": (
    hitCount: 337,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_loader.dart": (
    hitCount: 161,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_member_builder.dart": (
    hitCount: 199,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_target.dart": (
    hitCount: 33,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_type_alias_builder.dart": (
    hitCount: 46,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/augmentation_lowering.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/benchmarker.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/body_builder.dart": (
    hitCount: 7073,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/body_builder_context.dart": (
    hitCount: 342,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/collections.dart": (
    hitCount: 329,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/combined_member_signature.dart": (
    hitCount: 385,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/const_conditional_simplifier.dart": (
    hitCount: 95,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/constant_collection_builders.dart": (
    hitCount: 205,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/constant_evaluator.dart": (
    hitCount: 3700,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/constant_int_folder.dart": (
    hitCount: 243,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/constructor_tearoff_lowering.dart": (
    hitCount: 253,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/exhaustiveness.dart": (
    hitCount: 478,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/expression_generator.dart": (
    hitCount: 2523,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/expression_generator_helper.dart": (
    hitCount: 36,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/forest.dart": (
    hitCount: 401,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/forwarding_node.dart": (
    hitCount: 326,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/class_member.dart": (
    hitCount: 386,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/delayed.dart": (
    hitCount: 218,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/extension_type_members.dart": (
    hitCount: 386,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/hierarchy_builder.dart": (
    hitCount: 98,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/hierarchy_node.dart": (
    hitCount: 392,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/members_builder.dart": (
    hitCount: 133,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/members_node.dart": (
    hitCount: 1166,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/mixin_inferrer.dart": (
    hitCount: 248,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/implicit_field_type.dart": (
    hitCount: 93,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/implicit_type_argument.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/internal_ast.dart": (
    hitCount: 565,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/invalid_type.dart": (
    hitCount: 43,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/kernel_constants.dart": (
    hitCount: 13,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/kernel_helper.dart": (
    hitCount: 285,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/kernel_target.dart": (
    hitCount: 1059,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/kernel_variable_builder.dart": (
    hitCount: 11,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/late_lowering.dart": (
    hitCount: 368,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/load_library_builder.dart": (
    hitCount: 43,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/macro/annotation_parser.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/macro/identifiers.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/macro/introspectors.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/macro/macro.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/macro/offsets.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/macro/types.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/member_covariance.dart": (
    hitCount: 257,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/resource_identifier.dart": (
    hitCount: 15,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/static_weak_references.dart": (
    hitCount: 16,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/try_constant_evaluator.dart": (
    hitCount: 16,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/type_algorithms.dart": (
    hitCount: 924,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/type_builder_computer.dart": (
    hitCount: 175,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/utils.dart": (
    hitCount: 66,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/verifier.dart": (
    hitCount: 21,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/wildcard_lowering.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel_generator_impl.dart": (
    hitCount: 51,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/macros/isolate_macro_serializer.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/macros/macro_injected_impl.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/macros/macro_serializer.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/macros/macro_target.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/macros/macro_target_io.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/macros/temp_dir_macro_serializer.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/builder_factory.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/class_declaration.dart": (
    hitCount: 163,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/diet_listener.dart": (
    hitCount: 650,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/diet_parser.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/name_scheme.dart": (
    hitCount: 219,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/offset_map.dart": (
    hitCount: 118,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/outline_builder.dart": (
    hitCount: 2297,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/redirecting_factory_body.dart": (
    hitCount: 34,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_builder_factory.dart": (
    hitCount: 1159,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_builder_mixins.dart": (
    hitCount: 158,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_class_builder.dart": (
    hitCount: 1245,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_compilation_unit.dart": (
    hitCount: 741,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_constructor_builder.dart": (
    hitCount: 876,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_enum_builder.dart": (
    hitCount: 502,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_extension_builder.dart": (
    hitCount: 86,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_extension_type_declaration_builder.dart":
      (
    hitCount: 446,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_factory_builder.dart": (
    hitCount: 583,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_field_builder.dart": (
    hitCount: 1181,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_function_builder.dart": (
    hitCount: 304,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_library_builder.dart": (
    hitCount: 1419,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_loader.dart": (
    hitCount: 1859,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_member_builder.dart": (
    hitCount: 25,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_procedure_builder.dart": (
    hitCount: 518,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_type_alias_builder.dart": (
    hitCount: 333,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/stack_listener_impl.dart": (
    hitCount: 20,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/type_parameter_scope_builder.dart": (
    hitCount: 206,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/closure_context.dart": (
    hitCount: 411,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/delayed_expressions.dart": (
    hitCount: 425,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/external_ast_helper.dart": (
    hitCount: 139,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/factor_type.dart": (
    hitCount: 16,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/for_in.dart": (
    hitCount: 120,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/inference_results.dart": (
    hitCount: 166,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/inference_visitor.dart": (
    hitCount: 8098,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/inference_visitor_base.dart": (
    hitCount: 2397,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/matching_cache.dart": (
    hitCount: 545,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/matching_expressions.dart": (
    hitCount: 519,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/object_access_target.dart": (
    hitCount: 549,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/shared_type_analyzer.dart": (
    hitCount: 102,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/standard_bounds.dart": (
    hitCount: 20,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_constraint_gatherer.dart": (
    hitCount: 459,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_demotion.dart": (
    hitCount: 19,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_inference_engine.dart": (
    hitCount: 493,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_inferrer.dart": (
    hitCount: 96,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_schema.dart": (
    hitCount: 11,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_schema_elimination.dart": (
    hitCount: 32,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_schema_environment.dart": (
    hitCount: 233,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/util/error_reporter_file_copier.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/util/experiment_environment_getter.dart": (
    hitCount: 6,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/util/helpers.dart": (
    hitCount: 20,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/util/local_stack.dart": (
    hitCount: 15,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/util/parser_ast.dart": (
    hitCount: 78,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/util/textual_outline.dart": (
    hitCount: 463,
    missCount: 0,
  ),
};
