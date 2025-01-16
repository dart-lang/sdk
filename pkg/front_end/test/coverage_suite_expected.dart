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
  "package:front_end/src/api_prototype/expression_compilation_tools.dart": (
    hitCount: 0,
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
    hitCount: 50,
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
    hitCount: 91,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/ignored_parser_errors.dart": (
    hitCount: 3,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/import.dart": (
    hitCount: 42,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/import_chains.dart": (
    hitCount: 97,
    missCount: 0,
  ),
  // 99.88331388564761%.
  "package:front_end/src/base/incremental_compiler.dart": (
    hitCount: 856,
    missCount: 1,
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
    hitCount: 31,
    missCount: 0,
  ),
  // 99.26470588235294%.
  "package:front_end/src/base/modifiers.dart": (
    hitCount: 135,
    missCount: 1,
  ),
  // 100.0%.
  "package:front_end/src/base/name_space.dart": (
    hitCount: 153,
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
    hitCount: 260,
    missCount: 0,
  ),
  // 99.38837920489296%.
  "package:front_end/src/base/scope.dart": (
    hitCount: 650,
    missCount: 4,
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
    hitCount: 49,
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
    hitCount: 30,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/builder_mixins.dart": (
    hitCount: 45,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/builtin_type_declaration_builder.dart": (
    hitCount: 6,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/class_builder.dart": (
    hitCount: 141,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/constructor_reference_builder.dart": (
    hitCount: 52,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/declaration_builder.dart": (
    hitCount: 23,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/dynamic_type_declaration_builder.dart": (
    hitCount: 3,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/extension_builder.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/extension_type_declaration_builder.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/fixed_type_builder.dart": (
    hitCount: 3,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/formal_parameter_builder.dart": (
    hitCount: 170,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/function_type_builder.dart": (
    hitCount: 195,
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
    hitCount: 7,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/invalid_type_declaration_builder.dart": (
    hitCount: 17,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/library_builder.dart": (
    hitCount: 97,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/member_builder.dart": (
    hitCount: 89,
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
  "package:front_end/src/builder/named_type_builder.dart": (
    hitCount: 611,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/never_type_declaration_builder.dart": (
    hitCount: 11,
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
    hitCount: 46,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/omitted_type_declaration_builder.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/prefix_builder.dart": (
    hitCount: 70,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/record_type_builder.dart": (
    hitCount: 216,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/synthesized_type_builder.dart": (
    hitCount: 124,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_alias_builder.dart": (
    hitCount: 178,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_builder.dart": (
    hitCount: 53,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_declaration_builder.dart": (
    hitCount: 6,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_parameter_builder.dart": (
    hitCount: 298,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/void_type_builder.dart": (
    hitCount: 28,
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
    hitCount: 191,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_builder.dart": (
    hitCount: 99,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_member_builder.dart": (
    hitCount: 70,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_type_declaration_builder.dart": (
    hitCount: 172,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_type_member_builder.dart": (
    hitCount: 122,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_library_builder.dart": (
    hitCount: 339,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_loader.dart": (
    hitCount: 161,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_member_builder.dart": (
    hitCount: 218,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_target.dart": (
    hitCount: 33,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_type_alias_builder.dart": (
    hitCount: 55,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/class.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/constructor.dart": (
    hitCount: 50,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/enum.dart": (
    hitCount: 13,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/enum_element.dart": (
    hitCount: 224,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/extension.dart": (
    hitCount: 16,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/extension_type.dart": (
    hitCount: 13,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/factory.dart": (
    hitCount: 40,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/field.dart": (
    hitCount: 259,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/field/body_builder_context.dart": (
    hitCount: 30,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/field/class_member.dart": (
    hitCount: 157,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/field/encoding.dart": (
    hitCount: 995,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/getter.dart": (
    hitCount: 541,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/method.dart": (
    hitCount: 759,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/mixin.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/named_mixin_application.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/primary_constructor.dart": (
    hitCount: 47,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/setter.dart": (
    hitCount: 561,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/typedef.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/util.dart": (
    hitCount: 64,
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
    hitCount: 7181,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/body_builder_context.dart": (
    hitCount: 324,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/cfe_verifier.dart": (
    hitCount: 21,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/collections.dart": (
    hitCount: 329,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/combined_member_signature.dart": (
    hitCount: 380,
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
    hitCount: 3735,
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
  "package:front_end/src/kernel/dynamic_module_validator.dart": (
    hitCount: 322,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/exhaustiveness.dart": (
    hitCount: 478,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/expression_generator.dart": (
    hitCount: 2522,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/expression_generator_helper.dart": (
    hitCount: 35,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/forest.dart": (
    hitCount: 396,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/forwarding_node.dart": (
    hitCount: 323,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/class_member.dart": (
    hitCount: 389,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/delayed.dart": (
    hitCount: 218,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/extension_type_members.dart": (
    hitCount: 388,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/hierarchy_builder.dart": (
    hitCount: 98,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/hierarchy_node.dart": (
    hitCount: 403,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/members_builder.dart": (
    hitCount: 129,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/members_node.dart": (
    hitCount: 1106,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/mixin_inferrer.dart": (
    hitCount: 244,
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
    hitCount: 1075,
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
  "package:front_end/src/kernel/macro/metadata.dart": (
    hitCount: 1,
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
    hitCount: 258,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/record_use.dart": (
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
    hitCount: 533,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/type_builder_computer.dart": (
    hitCount: 169,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/utils.dart": (
    hitCount: 68,
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
    hitCount: 2,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/class_declaration.dart": (
    hitCount: 163,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/diet_listener.dart": (
    hitCount: 660,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/diet_parser.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/name_scheme.dart": (
    hitCount: 212,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/offset_map.dart": (
    hitCount: 150,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/outline_builder.dart": (
    hitCount: 2131,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/redirecting_factory_body.dart": (
    hitCount: 34,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_builder_factory.dart": (
    hitCount: 1206,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_builder_mixins.dart": (
    hitCount: 131,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_class_builder.dart": (
    hitCount: 1274,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_compilation_unit.dart": (
    hitCount: 642,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_constructor_builder.dart": (
    hitCount: 891,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_enum_builder.dart": (
    hitCount: 335,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_extension_builder.dart": (
    hitCount: 146,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_extension_type_declaration_builder.dart":
      (
    hitCount: 504,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_factory_builder.dart": (
    hitCount: 593,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_field_builder.dart": (
    hitCount: 232,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_function_builder.dart": (
    hitCount: 243,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_library_builder.dart": (
    hitCount: 1254,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_loader.dart": (
    hitCount: 1868,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_member_builder.dart": (
    hitCount: 14,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_method_builder.dart": (
    hitCount: 283,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_property_builder.dart": (
    hitCount: 768,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_type_alias_builder.dart": (
    hitCount: 358,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/stack_listener_impl.dart": (
    hitCount: 23,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/synthetic_method_builder.dart": (
    hitCount: 59,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/type_parameter_scope_builder.dart": (
    hitCount: 1514,
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
    hitCount: 155,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/inference_results.dart": (
    hitCount: 126,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/inference_visitor.dart": (
    hitCount: 8260,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/inference_visitor_base.dart": (
    hitCount: 2439,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/matching_cache.dart": (
    hitCount: 545,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/matching_expressions.dart": (
    hitCount: 521,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/object_access_target.dart": (
    hitCount: 549,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/shared_type_analyzer.dart": (
    hitCount: 110,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/standard_bounds.dart": (
    hitCount: 15,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_constraint_gatherer.dart": (
    hitCount: 103,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_demotion.dart": (
    hitCount: 19,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_inference_engine.dart": (
    hitCount: 533,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_inferrer.dart": (
    hitCount: 102,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_schema.dart": (
    hitCount: 12,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_schema_elimination.dart": (
    hitCount: 30,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_schema_environment.dart": (
    hitCount: 255,
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
  // 92.0%.
  "package:front_end/src/util/local_stack.dart": (
    hitCount: 23,
    missCount: 2,
  ),
  // 100.0%.
  "package:front_end/src/util/parser_ast.dart": (
    hitCount: 73,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/util/textual_outline.dart": (
    hitCount: 458,
    missCount: 0,
  ),
};
