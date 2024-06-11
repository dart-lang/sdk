// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "coverage_suite.dart";

// This is the currently recorded state
// using out/ReleaseX64/dart-sdk/bin/dart (which for instance makes a
// difference for compute_platform_binaries_location.dart).
const Map<String, ({int hitCount, int missCount})> _expect = {
  // 18.53448275862069%.
  "package:front_end/src/api_prototype/compiler_options.dart": (
    hitCount: 43,
    missCount: 189,
  ),
  // 86.48648648648648%.
  "package:front_end/src/api_prototype/experimental_flags.dart": (
    hitCount: 64,
    missCount: 10,
  ),
  // 55.28846153846154%.
  "package:front_end/src/api_prototype/experimental_flags_generated.dart": (
    hitCount: 230,
    missCount: 186,
  ),
  // 33.33333333333333%.
  "package:front_end/src/api_prototype/file_system.dart": (
    hitCount: 2,
    missCount: 4,
  ),
  // 6.666666666666667%.
  "package:front_end/src/api_prototype/incremental_kernel_generator.dart": (
    hitCount: 1,
    missCount: 14,
  ),
  // 0.0%.
  "package:front_end/src/api_prototype/kernel_generator.dart": (
    hitCount: 0,
    missCount: 18,
  ),
  // 0.0%.
  "package:front_end/src/api_prototype/language_version.dart": (
    hitCount: 0,
    missCount: 67,
  ),
  // 3.6036036036036037%.
  "package:front_end/src/api_prototype/lowering_predicates.dart": (
    hitCount: 12,
    missCount: 321,
  ),
  // 25.0%.
  "package:front_end/src/api_prototype/memory_file_system.dart": (
    hitCount: 23,
    missCount: 69,
  ),
  // 38.46153846153847%.
  "package:front_end/src/api_prototype/standard_file_system.dart": (
    hitCount: 40,
    missCount: 64,
  ),
  // 0.0%.
  "package:front_end/src/api_prototype/summary_generator.dart": (
    hitCount: 0,
    missCount: 4,
  ),
  // 0.0%.
  "package:front_end/src/api_prototype/terminal_color_support.dart": (
    hitCount: 0,
    missCount: 6,
  ),
  // 0.0%.
  "package:front_end/src/api_unstable/compiler_state.dart": (
    hitCount: 0,
    missCount: 12,
  ),
  // 0.0%.
  "package:front_end/src/api_unstable/dart2js.dart": (
    hitCount: 0,
    missCount: 74,
  ),
  // 37.03703703703704%.
  "package:front_end/src/api_unstable/util.dart": (
    hitCount: 10,
    missCount: 17,
  ),
  // 100.0%.
  "package:front_end/src/base/instrumentation.dart": (
    hitCount: 29,
    missCount: 0,
  ),
  // 39.86486486486486%.
  "package:front_end/src/base/processed_options.dart": (
    hitCount: 236,
    missCount: 356,
  ),
  // 71.23287671232876%.
  "package:front_end/src/compute_platform_binaries_location.dart": (
    hitCount: 52,
    missCount: 21,
  ),
  // 0.0%.
  "package:front_end/src/fasta/builder/augmentation_iterator.dart": (
    hitCount: 0,
    missCount: 17,
  ),
  // 64.44444444444444%.
  "package:front_end/src/fasta/builder/builder.dart": (
    hitCount: 29,
    missCount: 16,
  ),
  // 100.0%.
  "package:front_end/src/fasta/builder/builder_mixins.dart": (
    hitCount: 42,
    missCount: 0,
  ),
  // 70.0%.
  "package:front_end/src/fasta/builder/builtin_type_declaration_builder.dart": (
    hitCount: 7,
    missCount: 3,
  ),
  // 71.14427860696517%.
  "package:front_end/src/fasta/builder/class_builder.dart": (
    hitCount: 143,
    missCount: 58,
  ),
  // 100.0%.
  "package:front_end/src/fasta/builder/constructor_reference_builder.dart": (
    hitCount: 52,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fasta/builder/declaration_builder.dart": (
    hitCount: 25,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fasta/builder/dynamic_type_declaration_builder.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 50.0%.
  "package:front_end/src/fasta/builder/extension_builder.dart": (
    hitCount: 4,
    missCount: 4,
  ),
  // 100.0%.
  "package:front_end/src/fasta/builder/extension_type_declaration_builder.dart":
      (
    hitCount: 17,
    missCount: 0,
  ),
  // 22.727272727272727%.
  "package:front_end/src/fasta/builder/fixed_type_builder.dart": (
    hitCount: 5,
    missCount: 17,
  ),
  // 95.85492227979275%.
  "package:front_end/src/fasta/builder/formal_parameter_builder.dart": (
    hitCount: 185,
    missCount: 8,
  ),
  // 77.95275590551181%.
  "package:front_end/src/fasta/builder/function_type_builder.dart": (
    hitCount: 99,
    missCount: 28,
  ),
  // 0.0%.
  "package:front_end/src/fasta/builder/future_or_type_declaration_builder.dart":
      (
    hitCount: 0,
    missCount: 10,
  ),
  // 100.0%.
  "package:front_end/src/fasta/builder/inferable_type_builder.dart": (
    hitCount: 27,
    missCount: 0,
  ),
  // 33.33333333333333%.
  "package:front_end/src/fasta/builder/invalid_type_builder.dart": (
    hitCount: 4,
    missCount: 8,
  ),
  // 85.0%.
  "package:front_end/src/fasta/builder/invalid_type_declaration_builder.dart": (
    hitCount: 17,
    missCount: 3,
  ),
  // 81.63265306122449%.
  "package:front_end/src/fasta/builder/library_builder.dart": (
    hitCount: 80,
    missCount: 18,
  ),
  // 97.38562091503267%.
  "package:front_end/src/fasta/builder/member_builder.dart": (
    hitCount: 149,
    missCount: 4,
  ),
  // 86.04651162790698%.
  "package:front_end/src/fasta/builder/metadata_builder.dart": (
    hitCount: 37,
    missCount: 6,
  ),
  // 100.0%.
  "package:front_end/src/fasta/builder/mixin_application_builder.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 85.0%.
  "package:front_end/src/fasta/builder/modifier_builder.dart": (
    hitCount: 17,
    missCount: 3,
  ),
  // 74.74747474747475%.
  "package:front_end/src/fasta/builder/named_type_builder.dart": (
    hitCount: 370,
    missCount: 125,
  ),
  // 76.92307692307693%.
  "package:front_end/src/fasta/builder/never_type_declaration_builder.dart": (
    hitCount: 10,
    missCount: 3,
  ),
  // 33.33333333333333%.
  "package:front_end/src/fasta/builder/null_type_declaration_builder.dart": (
    hitCount: 2,
    missCount: 4,
  ),
  // 100.0%.
  "package:front_end/src/fasta/builder/nullability_builder.dart": (
    hitCount: 24,
    missCount: 0,
  ),
  // 34.146341463414636%.
  "package:front_end/src/fasta/builder/omitted_type_builder.dart": (
    hitCount: 28,
    missCount: 54,
  ),
  // 0.0%.
  "package:front_end/src/fasta/builder/omitted_type_declaration_builder.dart": (
    hitCount: 0,
    missCount: 13,
  ),
  // 89.47368421052632%.
  "package:front_end/src/fasta/builder/prefix_builder.dart": (
    hitCount: 34,
    missCount: 4,
  ),
  // 77.43589743589745%.
  "package:front_end/src/fasta/builder/record_type_builder.dart": (
    hitCount: 151,
    missCount: 44,
  ),
  // 78.99159663865547%.
  "package:front_end/src/fasta/builder/type_alias_builder.dart": (
    hitCount: 188,
    missCount: 50,
  ),
  // 77.77777777777779%.
  "package:front_end/src/fasta/builder/type_builder.dart": (
    hitCount: 56,
    missCount: 16,
  ),
  // 90.0%.
  "package:front_end/src/fasta/builder/type_declaration_builder.dart": (
    hitCount: 9,
    missCount: 1,
  ),
  // 78.42227378190255%.
  "package:front_end/src/fasta/builder/type_variable_builder.dart": (
    hitCount: 338,
    missCount: 93,
  ),
  // 100.0%.
  "package:front_end/src/fasta/builder/void_type_declaration_builder.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 54.71698113207547%.
  "package:front_end/src/fasta/builder_graph.dart": (
    hitCount: 29,
    missCount: 24,
  ),
  // 73.0892742453436%.
  "package:front_end/src/fasta/codes/fasta_codes_cfe_generated.dart": (
    hitCount: 1138,
    missCount: 419,
  ),
  // 82.92682926829268%.
  "package:front_end/src/fasta/codes/type_labeler.dart": (
    hitCount: 510,
    missCount: 105,
  ),
  // 100.0%.
  "package:front_end/src/fasta/combinator.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 68.68686868686868%.
  "package:front_end/src/fasta/command_line_reporting.dart": (
    hitCount: 68,
    missCount: 31,
  ),
  // 90.1639344262295%.
  "package:front_end/src/fasta/compiler_context.dart": (
    hitCount: 55,
    missCount: 6,
  ),
  // 100.0%.
  "package:front_end/src/fasta/configuration.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 59.09090909090909%.
  "package:front_end/src/fasta/crash.dart": (
    hitCount: 52,
    missCount: 36,
  ),
  // 100.0%.
  "package:front_end/src/fasta/dill/dill_builder_mixins.dart": (
    hitCount: 16,
    missCount: 0,
  ),
  // 92.34972677595628%.
  "package:front_end/src/fasta/dill/dill_class_builder.dart": (
    hitCount: 169,
    missCount: 14,
  ),
  // 80.72289156626506%.
  "package:front_end/src/fasta/dill/dill_extension_builder.dart": (
    hitCount: 67,
    missCount: 16,
  ),
  // 70.29702970297029%.
  "package:front_end/src/fasta/dill/dill_extension_member_builder.dart": (
    hitCount: 71,
    missCount: 30,
  ),
  // 95.42483660130719%.
  "package:front_end/src/fasta/dill/dill_extension_type_declaration_builder.dart":
      (
    hitCount: 146,
    missCount: 7,
  ),
  // 83.76623376623377%.
  "package:front_end/src/fasta/dill/dill_extension_type_member_builder.dart": (
    hitCount: 129,
    missCount: 25,
  ),
  // 78.4256559766764%.
  "package:front_end/src/fasta/dill/dill_library_builder.dart": (
    hitCount: 269,
    missCount: 74,
  ),
  // 76.58536585365854%.
  "package:front_end/src/fasta/dill/dill_loader.dart": (
    hitCount: 157,
    missCount: 48,
  ),
  // 86.52173913043478%.
  "package:front_end/src/fasta/dill/dill_member_builder.dart": (
    hitCount: 199,
    missCount: 31,
  ),
  // 74.35897435897436%.
  "package:front_end/src/fasta/dill/dill_target.dart": (
    hitCount: 29,
    missCount: 10,
  ),
  // 95.83333333333334%.
  "package:front_end/src/fasta/dill/dill_type_alias_builder.dart": (
    hitCount: 46,
    missCount: 2,
  ),
  // 86.66666666666667%.
  "package:front_end/src/fasta/export.dart": (
    hitCount: 13,
    missCount: 2,
  ),
  // 50.0%.
  "package:front_end/src/fasta/hybrid_file_system.dart": (
    hitCount: 21,
    missCount: 21,
  ),
  // 84.78260869565217%.
  "package:front_end/src/fasta/identifiers.dart": (
    hitCount: 78,
    missCount: 14,
  ),
  // 100.0%.
  "package:front_end/src/fasta/ignored_parser_errors.dart": (
    hitCount: 3,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fasta/import.dart": (
    hitCount: 46,
    missCount: 0,
  ),
  // 96.96969696969697%.
  "package:front_end/src/fasta/import_chains.dart": (
    hitCount: 96,
    missCount: 3,
  ),
  // 48.225352112676056%.
  "package:front_end/src/fasta/incremental_compiler.dart": (
    hitCount: 856,
    missCount: 919,
  ),
  // 0.0%.
  "package:front_end/src/fasta/incremental_serializer.dart": (
    hitCount: 0,
    missCount: 202,
  ),
  // 100.0%.
  "package:front_end/src/fasta/kernel/augmentation_lowering.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 0.0%.
  "package:front_end/src/fasta/kernel/benchmarker.dart": (
    hitCount: 0,
    missCount: 128,
  ),
  // 91.35454423412538%.
  "package:front_end/src/fasta/kernel/body_builder.dart": (
    hitCount: 6805,
    missCount: 644,
  ),
  // 70.40816326530613%.
  "package:front_end/src/fasta/kernel/body_builder_context.dart": (
    hitCount: 345,
    missCount: 145,
  ),
  // 36.44736842105264%.
  "package:front_end/src/fasta/kernel/collections.dart": (
    hitCount: 277,
    missCount: 483,
  ),
  // 91.8854415274463%.
  "package:front_end/src/fasta/kernel/combined_member_signature.dart": (
    hitCount: 385,
    missCount: 34,
  ),
  // 61.68831168831169%.
  "package:front_end/src/fasta/kernel/const_conditional_simplifier.dart": (
    hitCount: 95,
    missCount: 59,
  ),
  // 67.65676567656766%.
  "package:front_end/src/fasta/kernel/constant_collection_builders.dart": (
    hitCount: 205,
    missCount: 98,
  ),
  // 82.14686728048507%.
  "package:front_end/src/fasta/kernel/constant_evaluator.dart": (
    hitCount: 3658,
    missCount: 795,
  ),
  // 92.04545454545455%.
  "package:front_end/src/fasta/kernel/constant_int_folder.dart": (
    hitCount: 243,
    missCount: 21,
  ),
  // 95.11278195488721%.
  "package:front_end/src/fasta/kernel/constructor_tearoff_lowering.dart": (
    hitCount: 253,
    missCount: 13,
  ),
  // 74.57098283931357%.
  "package:front_end/src/fasta/kernel/exhaustiveness.dart": (
    hitCount: 478,
    missCount: 163,
  ),
  // 79.56411876184461%.
  "package:front_end/src/fasta/kernel/expression_generator.dart": (
    hitCount: 2519,
    missCount: 647,
  ),
  // 100.0%.
  "package:front_end/src/fasta/kernel/expression_generator_helper.dart": (
    hitCount: 36,
    missCount: 0,
  ),
  // 90.27777777777779%.
  "package:front_end/src/fasta/kernel/forest.dart": (
    hitCount: 390,
    missCount: 42,
  ),
  // 94.4927536231884%.
  "package:front_end/src/fasta/kernel/forwarding_node.dart": (
    hitCount: 326,
    missCount: 19,
  ),
  // 83.1896551724138%.
  "package:front_end/src/fasta/kernel/hierarchy/class_member.dart": (
    hitCount: 386,
    missCount: 78,
  ),
  // 100.0%.
  "package:front_end/src/fasta/kernel/hierarchy/delayed.dart": (
    hitCount: 218,
    missCount: 0,
  ),
  // 87.52834467120182%.
  "package:front_end/src/fasta/kernel/hierarchy/extension_type_members.dart": (
    hitCount: 386,
    missCount: 55,
  ),
  // 50.77720207253886%.
  "package:front_end/src/fasta/kernel/hierarchy/hierarchy_builder.dart": (
    hitCount: 98,
    missCount: 95,
  ),
  // 93.33333333333333%.
  "package:front_end/src/fasta/kernel/hierarchy/hierarchy_node.dart": (
    hitCount: 392,
    missCount: 28,
  ),
  // 98.51851851851852%.
  "package:front_end/src/fasta/kernel/hierarchy/members_builder.dart": (
    hitCount: 133,
    missCount: 2,
  ),
  // 91.44427001569859%.
  "package:front_end/src/fasta/kernel/hierarchy/members_node.dart": (
    hitCount: 1165,
    missCount: 109,
  ),
  // 61.53846153846154%.
  "package:front_end/src/fasta/kernel/hierarchy/mixin_inferrer.dart": (
    hitCount: 248,
    missCount: 155,
  ),
  // 52.24719101123596%.
  "package:front_end/src/fasta/kernel/implicit_field_type.dart": (
    hitCount: 93,
    missCount: 85,
  ),
  // 2.941176470588235%.
  "package:front_end/src/fasta/kernel/implicit_type_argument.dart": (
    hitCount: 1,
    missCount: 33,
  ),
  // 46.40625%.
  "package:front_end/src/fasta/kernel/internal_ast.dart": (
    hitCount: 594,
    missCount: 686,
  ),
  // 74.13793103448276%.
  "package:front_end/src/fasta/kernel/invalid_type.dart": (
    hitCount: 43,
    missCount: 15,
  ),
  // 55.55555555555556%.
  "package:front_end/src/fasta/kernel/kernel_constants.dart": (
    hitCount: 10,
    missCount: 8,
  ),
  // 98.95833333333334%.
  "package:front_end/src/fasta/kernel/kernel_helper.dart": (
    hitCount: 285,
    missCount: 3,
  ),
  // 79.9079754601227%.
  "package:front_end/src/fasta/kernel/kernel_target.dart": (
    hitCount: 1042,
    missCount: 262,
  ),
  // 61.111111111111114%.
  "package:front_end/src/fasta/kernel/kernel_variable_builder.dart": (
    hitCount: 11,
    missCount: 7,
  ),
  // 100.0%.
  "package:front_end/src/fasta/kernel/late_lowering.dart": (
    hitCount: 368,
    missCount: 0,
  ),
  // 89.58333333333334%.
  "package:front_end/src/fasta/kernel/load_library_builder.dart": (
    hitCount: 43,
    missCount: 5,
  ),
  // 0.1984126984126984%.
  "package:front_end/src/fasta/kernel/macro/annotation_parser.dart": (
    hitCount: 2,
    missCount: 1006,
  ),
  // 0.0%.
  "package:front_end/src/fasta/kernel/macro/identifiers.dart": (
    hitCount: 0,
    missCount: 134,
  ),
  // 0.0%.
  "package:front_end/src/fasta/kernel/macro/introspectors.dart": (
    hitCount: 0,
    missCount: 573,
  ),
  // 0.19047619047619047%.
  "package:front_end/src/fasta/kernel/macro/macro.dart": (
    hitCount: 2,
    missCount: 1048,
  ),
  // 0.0%.
  "package:front_end/src/fasta/kernel/macro/offsets.dart": (
    hitCount: 0,
    missCount: 201,
  ),
  // 0.0%.
  "package:front_end/src/fasta/kernel/macro/types.dart": (
    hitCount: 0,
    missCount: 230,
  ),
  // 89.23611111111111%.
  "package:front_end/src/fasta/kernel/member_covariance.dart": (
    hitCount: 257,
    missCount: 31,
  ),
  // 39.473684210526315%.
  "package:front_end/src/fasta/kernel/resource_identifier.dart": (
    hitCount: 15,
    missCount: 23,
  ),
  // 15.238095238095239%.
  "package:front_end/src/fasta/kernel/static_weak_references.dart": (
    hitCount: 16,
    missCount: 89,
  ),
  // 19.753086419753085%.
  "package:front_end/src/fasta/kernel/try_constant_evaluator.dart": (
    hitCount: 16,
    missCount: 65,
  ),
  // 93.14928425357874%.
  "package:front_end/src/fasta/kernel/type_algorithms.dart": (
    hitCount: 911,
    missCount: 67,
  ),
  // 90.20618556701031%.
  "package:front_end/src/fasta/kernel/type_builder_computer.dart": (
    hitCount: 175,
    missCount: 19,
  ),
  // 37.93103448275862%.
  "package:front_end/src/fasta/kernel/utils.dart": (
    hitCount: 66,
    missCount: 108,
  ),
  // 56.25%.
  "package:front_end/src/fasta/kernel/verifier.dart": (
    hitCount: 18,
    missCount: 14,
  ),
  // 79.3103448275862%.
  "package:front_end/src/fasta/library_graph.dart": (
    hitCount: 23,
    missCount: 6,
  ),
  // 100.0%.
  "package:front_end/src/fasta/messages.dart": (
    hitCount: 12,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fasta/modifier.dart": (
    hitCount: 29,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/fasta/operator.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 0.0%.
  "package:front_end/src/fasta/problems.dart": (
    hitCount: 0,
    missCount: 29,
  ),
  // 80.5050505050505%.
  "package:front_end/src/fasta/scope.dart": (
    hitCount: 797,
    missCount: 193,
  ),
  // 80.29556650246306%.
  "package:front_end/src/fasta/source/class_declaration.dart": (
    hitCount: 163,
    missCount: 40,
  ),
  // 92.02898550724638%.
  "package:front_end/src/fasta/source/diet_listener.dart": (
    hitCount: 635,
    missCount: 55,
  ),
  // 100.0%.
  "package:front_end/src/fasta/source/diet_parser.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 93.19148936170212%.
  "package:front_end/src/fasta/source/name_scheme.dart": (
    hitCount: 219,
    missCount: 16,
  ),
  // 95.16129032258065%.
  "package:front_end/src/fasta/source/offset_map.dart": (
    hitCount: 118,
    missCount: 6,
  ),
  // 91.45299145299145%.
  "package:front_end/src/fasta/source/outline_builder.dart": (
    hitCount: 2247,
    missCount: 210,
  ),
  // 94.44444444444444%.
  "package:front_end/src/fasta/source/redirecting_factory_body.dart": (
    hitCount: 34,
    missCount: 2,
  ),
  // 88.8268156424581%.
  "package:front_end/src/fasta/source/source_builder_mixins.dart": (
    hitCount: 159,
    missCount: 20,
  ),
  // 85.39007092198581%.
  "package:front_end/src/fasta/source/source_class_builder.dart": (
    hitCount: 1204,
    missCount: 206,
  ),
  // 92.65658747300216%.
  "package:front_end/src/fasta/source/source_constructor_builder.dart": (
    hitCount: 858,
    missCount: 68,
  ),
  // 95.73560767590618%.
  "package:front_end/src/fasta/source/source_enum_builder.dart": (
    hitCount: 449,
    missCount: 20,
  ),
  // 61.261261261261254%.
  "package:front_end/src/fasta/source/source_extension_builder.dart": (
    hitCount: 68,
    missCount: 43,
  ),
  // 84.32539682539682%.
  "package:front_end/src/fasta/source/source_extension_type_declaration_builder.dart":
      (
    hitCount: 425,
    missCount: 79,
  ),
  // 92.22222222222223%.
  "package:front_end/src/fasta/source/source_factory_builder.dart": (
    hitCount: 581,
    missCount: 49,
  ),
  // 89.10891089108911%.
  "package:front_end/src/fasta/source/source_field_builder.dart": (
    hitCount: 1170,
    missCount: 143,
  ),
  // 89.29663608562691%.
  "package:front_end/src/fasta/source/source_function_builder.dart": (
    hitCount: 292,
    missCount: 35,
  ),
  // 83.62422997946611%.
  "package:front_end/src/fasta/source/source_library_builder.dart": (
    hitCount: 3258,
    missCount: 638,
  ),
  // 80.1697186243859%.
  "package:front_end/src/fasta/source/source_loader.dart": (
    hitCount: 1795,
    missCount: 444,
  ),
  // 40.32258064516129%.
  "package:front_end/src/fasta/source/source_member_builder.dart": (
    hitCount: 25,
    missCount: 37,
  ),
  // 96.11829944547135%.
  "package:front_end/src/fasta/source/source_procedure_builder.dart": (
    hitCount: 520,
    missCount: 21,
  ),
  // 97.63313609467455%.
  "package:front_end/src/fasta/source/source_type_alias_builder.dart": (
    hitCount: 330,
    missCount: 8,
  ),
  // 78.37837837837837%.
  "package:front_end/src/fasta/source/stack_listener_impl.dart": (
    hitCount: 29,
    missCount: 8,
  ),
  // 73.07692307692307%.
  "package:front_end/src/fasta/ticker.dart": (
    hitCount: 19,
    missCount: 7,
  ),
  // 85.65400843881856%.
  "package:front_end/src/fasta/type_inference/closure_context.dart": (
    hitCount: 406,
    missCount: 68,
  ),
  // 77.55474452554745%.
  "package:front_end/src/fasta/type_inference/delayed_expressions.dart": (
    hitCount: 425,
    missCount: 123,
  ),
  // 97.88732394366197%.
  "package:front_end/src/fasta/type_inference/external_ast_helper.dart": (
    hitCount: 139,
    missCount: 3,
  ),
  // 76.19047619047619%.
  "package:front_end/src/fasta/type_inference/factor_type.dart": (
    hitCount: 16,
    missCount: 5,
  ),
  // 75.47169811320755%.
  "package:front_end/src/fasta/type_inference/for_in.dart": (
    hitCount: 120,
    missCount: 39,
  ),
  // 85.12820512820512%.
  "package:front_end/src/fasta/type_inference/inference_results.dart": (
    hitCount: 166,
    missCount: 29,
  ),
  // 90.25658807212206%.
  "package:front_end/src/fasta/type_inference/inference_visitor.dart": (
    hitCount: 7809,
    missCount: 843,
  ),
  // 84.56303724928367%.
  "package:front_end/src/fasta/type_inference/inference_visitor_base.dart": (
    hitCount: 2361,
    missCount: 431,
  ),
  // 80.26509572901325%.
  "package:front_end/src/fasta/type_inference/matching_cache.dart": (
    hitCount: 545,
    missCount: 134,
  ),
  // 98.10964083175804%.
  "package:front_end/src/fasta/type_inference/matching_expressions.dart": (
    hitCount: 519,
    missCount: 10,
  ),
  // 77.31629392971246%.
  "package:front_end/src/fasta/type_inference/object_access_target.dart": (
    hitCount: 484,
    missCount: 142,
  ),
  // 98.0%.
  "package:front_end/src/fasta/type_inference/shared_type_analyzer.dart": (
    hitCount: 98,
    missCount: 2,
  ),
  // 71.42857142857143%.
  "package:front_end/src/fasta/type_inference/standard_bounds.dart": (
    hitCount: 20,
    missCount: 8,
  ),
  // 61.28608923884514%.
  "package:front_end/src/fasta/type_inference/type_constraint_gatherer.dart": (
    hitCount: 467,
    missCount: 295,
  ),
  // 95.0%.
  "package:front_end/src/fasta/type_inference/type_demotion.dart": (
    hitCount: 19,
    missCount: 1,
  ),
  // 89.62962962962962%.
  "package:front_end/src/fasta/type_inference/type_inference_engine.dart": (
    hitCount: 484,
    missCount: 56,
  ),
  // 54.037267080745345%.
  "package:front_end/src/fasta/type_inference/type_inferrer.dart": (
    hitCount: 87,
    missCount: 74,
  ),
  // 36.666666666666664%.
  "package:front_end/src/fasta/type_inference/type_schema.dart": (
    hitCount: 11,
    missCount: 19,
  ),
  // 88.88888888888889%.
  "package:front_end/src/fasta/type_inference/type_schema_elimination.dart": (
    hitCount: 32,
    missCount: 4,
  ),
  // 89.06882591093117%.
  "package:front_end/src/fasta/type_inference/type_schema_environment.dart": (
    hitCount: 220,
    missCount: 27,
  ),
  // 100.0%.
  "package:front_end/src/fasta/uri_offset.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 75.92592592592592%.
  "package:front_end/src/fasta/uri_translator.dart": (
    hitCount: 41,
    missCount: 13,
  ),
  // 100.0%.
  "package:front_end/src/fasta/uris.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 0.0%.
  "package:front_end/src/fasta/util/error_reporter_file_copier.dart": (
    hitCount: 0,
    missCount: 11,
  ),
  // 85.71428571428571%.
  "package:front_end/src/fasta/util/experiment_environment_getter.dart": (
    hitCount: 6,
    missCount: 1,
  ),
  // 52.63157894736842%.
  "package:front_end/src/fasta/util/helpers.dart": (
    hitCount: 20,
    missCount: 18,
  ),
  // 5.5954088952654235%.
  "package:front_end/src/fasta/util/parser_ast.dart": (
    hitCount: 78,
    missCount: 1316,
  ),
  // 20.424013434089%.
  "package:front_end/src/fasta/util/parser_ast_helper.dart": (
    hitCount: 973,
    missCount: 3791,
  ),
  // 86.54205607476636%.
  "package:front_end/src/fasta/util/textual_outline.dart": (
    hitCount: 463,
    missCount: 72,
  ),
  // 28.79581151832461%.
  "package:front_end/src/kernel_generator_impl.dart": (
    hitCount: 55,
    missCount: 136,
  ),
  // 0.0%.
  "package:front_end/src/macros/isolate_macro_serializer.dart": (
    hitCount: 0,
    missCount: 15,
  ),
  // 0.0%.
  "package:front_end/src/macros/macro_serializer.dart": (
    hitCount: 0,
    missCount: 4,
  ),
  // 0.0%.
  "package:front_end/src/macros/macro_target.dart": (
    hitCount: 0,
    missCount: 3,
  ),
  // 0.0%.
  "package:front_end/src/macros/macro_target_io.dart": (
    hitCount: 0,
    missCount: 42,
  ),
  // 0.0%.
  "package:front_end/src/macros/temp_dir_macro_serializer.dart": (
    hitCount: 0,
    missCount: 18,
  ),
};
