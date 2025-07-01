// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "coverage_suite.dart";

// This is the currently recorded state
// using out/ReleaseX64/dart-sdk/bin/dart (which for instance makes a
// difference for compute_platform_binaries_location.dart).
const Map<String, ({int hitCount, int missCount})> _expect = {
  // 100.0%.
  "package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart": (
    hitCount: 1227,
    missCount: 0,
  ),
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
    hitCount: 31,
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
  // 100.0%.
  "package:front_end/src/base/incremental_compiler.dart": (
    hitCount: 813,
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
    hitCount: 48,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/lookup_result.dart": (
    hitCount: 42,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/messages.dart": (
    hitCount: 31,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/modifiers.dart": (
    hitCount: 128,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/name_space.dart": (
    hitCount: 137,
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
    hitCount: 245,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/scope.dart": (
    hitCount: 188,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/ticker.dart": (
    hitCount: 19,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/uri_offset.dart": (
    hitCount: 13,
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
    hitCount: 11,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/builder_mixins.dart": (
    hitCount: 34,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/builtin_type_declaration_builder.dart": (
    hitCount: 6,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/class_builder.dart": (
    hitCount: 129,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/constructor_reference_builder.dart": (
    hitCount: 55,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/declaration_builder.dart": (
    hitCount: 18,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/dynamic_type_declaration_builder.dart": (
    hitCount: 3,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/extension_builder.dart": (
    hitCount: 0,
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
    hitCount: 173,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/function_type_builder.dart": (
    hitCount: 194,
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
    hitCount: 38,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/member_builder.dart": (
    hitCount: 63,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/metadata_builder.dart": (
    hitCount: 41,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/method_builder.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/named_type_builder.dart": (
    hitCount: 613,
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
  "package:front_end/src/builder/prefix_builder.dart": (
    hitCount: 77,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/property_builder.dart": (
    hitCount: 51,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/record_type_builder.dart": (
    hitCount: 216,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/synthesized_type_builder.dart": (
    hitCount: 122,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_alias_builder.dart": (
    hitCount: 176,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_builder.dart": (
    hitCount: 51,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_declaration_builder.dart": (
    hitCount: 6,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/type_parameter_builder.dart": (
    hitCount: 233,
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
    hitCount: 46,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_builder_mixins.dart": (
    hitCount: 88,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_class_builder.dart": (
    hitCount: 203,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_builder.dart": (
    hitCount: 113,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_member_builder.dart": (
    hitCount: 62,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_type_declaration_builder.dart": (
    hitCount: 207,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_extension_type_member_builder.dart": (
    hitCount: 154,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_library_builder.dart": (
    hitCount: 351,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_loader.dart": (
    hitCount: 161,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_member_builder.dart": (
    hitCount: 248,
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
  "package:front_end/src/dill/dill_type_parameter_builder.dart": (
    hitCount: 26,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/class.dart": (
    hitCount: 15,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/class/declaration.dart": (
    hitCount: 170,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/constructor.dart": (
    hitCount: 65,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/constructor/body_builder_context.dart": (
    hitCount: 84,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/constructor/declaration.dart": (
    hitCount: 623,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/constructor/encoding.dart": (
    hitCount: 489,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/declaration.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/enum.dart": (
    hitCount: 17,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/enum_element.dart": (
    hitCount: 287,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/extension.dart": (
    hitCount: 28,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/extension_type.dart": (
    hitCount: 17,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/factory.dart": (
    hitCount: 58,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/factory/body_builder_context.dart": (
    hitCount: 52,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/factory/declaration.dart": (
    hitCount: 152,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/factory/encoding.dart": (
    hitCount: 551,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/field.dart": (
    hitCount: 34,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/field/body_builder_context.dart": (
    hitCount: 18,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/field/class_member.dart": (
    hitCount: 129,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/field/declaration.dart": (
    hitCount: 436,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/field/encoding.dart": (
    hitCount: 965,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/getter.dart": (
    hitCount: 54,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/getter/body_builder_context.dart": (
    hitCount: 50,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/getter/declaration.dart": (
    hitCount: 130,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/getter/encoding.dart": (
    hitCount: 365,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/method.dart": (
    hitCount: 54,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/method/body_builder_context.dart": (
    hitCount: 54,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/method/declaration.dart": (
    hitCount: 106,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/method/encoding.dart": (
    hitCount: 638,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/mixin.dart": (
    hitCount: 13,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/named_mixin_application.dart": (
    hitCount: 10,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/primary_constructor.dart": (
    hitCount: 62,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/primary_constructor_field.dart": (
    hitCount: 127,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/setter.dart": (
    hitCount: 54,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/setter/body_builder_context.dart": (
    hitCount: 48,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/setter/declaration.dart": (
    hitCount: 126,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/setter/encoding.dart": (
    hitCount: 389,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/type_parameter.dart": (
    hitCount: 12,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/typedef.dart": (
    hitCount: 10,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fragment/util.dart": (
    hitCount: 80,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/benchmarker.dart": (
    hitCount: 0,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/body_builder.dart": (
    hitCount: 7214,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/body_builder_context.dart": (
    hitCount: 182,
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
    hitCount: 3696,
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
    hitCount: 408,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/exhaustiveness.dart": (
    hitCount: 481,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/expression_generator.dart": (
    hitCount: 2454,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/expression_generator_helper.dart": (
    hitCount: 35,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/forest.dart": (
    hitCount: 405,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/forwarding_node.dart": (
    hitCount: 323,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/class_member.dart": (
    hitCount: 290,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/delayed.dart": (
    hitCount: 137,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/extension_type_members.dart": (
    hitCount: 390,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/hierarchy_builder.dart": (
    hitCount: 94,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/hierarchy_node.dart": (
    hitCount: 381,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/members_builder.dart": (
    hitCount: 132,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/members_node.dart": (
    hitCount: 1088,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/mixin_inferrer.dart": (
    hitCount: 244,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/implicit_field_type.dart": (
    hitCount: 25,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/implicit_type_argument.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/internal_ast.dart": (
    hitCount: 554,
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
    hitCount: 265,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/kernel_target.dart": (
    hitCount: 1041,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/kernel_variable_builder.dart": (
    hitCount: 13,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/late_lowering.dart": (
    hitCount: 362,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/load_library_builder.dart": (
    hitCount: 44,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/macro/metadata.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/member_covariance.dart": (
    hitCount: 258,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/record_use.dart": (
    hitCount: 14,
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
    hitCount: 86,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel/wildcard_lowering.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/kernel_generator_impl.dart": (
    hitCount: 46,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/builder_factory.dart": (
    hitCount: 1169,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/diet_listener.dart": (
    hitCount: 646,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/diet_parser.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/fragment_factory.dart": (
    hitCount: 68,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/fragment_factory_impl.dart": (
    hitCount: 1159,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/name_scheme.dart": (
    hitCount: 212,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/name_space_builder.dart": (
    hitCount: 193,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/nominal_parameter_name_space.dart": (
    hitCount: 61,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/offset_map.dart": (
    hitCount: 144,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/outline_builder.dart": (
    hitCount: 2107,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/redirecting_factory_body.dart": (
    hitCount: 34,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_builder_mixins.dart": (
    hitCount: 114,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_class_builder.dart": (
    hitCount: 1466,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_compilation_unit.dart": (
    hitCount: 667,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_constructor_builder.dart": (
    hitCount: 354,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_enum_builder.dart": (
    hitCount: 395,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_extension_builder.dart": (
    hitCount: 150,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_extension_type_declaration_builder.dart":
      (
    hitCount: 546,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_factory_builder.dart": (
    hitCount: 155,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_function_builder.dart": (
    hitCount: 44,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_library_builder.dart": (
    hitCount: 1125,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_loader.dart": (
    hitCount: 1795,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_member_builder.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_method_builder.dart": (
    hitCount: 182,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_property_builder.dart": (
    hitCount: 474,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_type_alias_builder.dart": (
    hitCount: 347,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/source_type_parameter_builder.dart": (
    hitCount: 106,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/stack_listener_impl.dart": (
    hitCount: 23,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/source/type_scope.dart": (
    hitCount: 23,
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
    hitCount: 127,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/inference_visitor.dart": (
    hitCount: 8329,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/inference_visitor_base.dart": (
    hitCount: 2449,
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
    hitCount: 552,
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
    hitCount: 108,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_demotion.dart": (
    hitCount: 19,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_inference_engine.dart": (
    hitCount: 535,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/type_inference/type_inferrer.dart": (
    hitCount: 111,
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
    hitCount: 263,
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
    hitCount: 23,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/util/parser_ast.dart": (
    hitCount: 119,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/util/textual_outline.dart": (
    hitCount: 460,
    missCount: 0,
  ),
};
