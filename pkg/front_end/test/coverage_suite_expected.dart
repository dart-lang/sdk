// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "coverage_suite.dart";

// This is the currently recorded state
// using out/ReleaseX64/dart-sdk/bin/dart (which for instance makes a
// difference for compute_platform_binaries_location.dart).
const Map<String, ({int hitCount, int missCount})> _expect = {
  // 18.614718614718615%.
  "package:front_end/src/api_prototype/compiler_options.dart": (
    hitCount: 43,
    missCount: 188,
  ),
  // 89.1891891891892%.
  "package:front_end/src/api_prototype/experimental_flags.dart": (
    hitCount: 66,
    missCount: 8,
  ),
  // 100.0%.
  "package:front_end/src/api_prototype/file_system.dart": (
    hitCount: 2,
    missCount: 0,
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
    missCount: 65,
  ),
  // 3.927492447129909%.
  "package:front_end/src/api_prototype/lowering_predicates.dart": (
    hitCount: 13,
    missCount: 318,
  ),
  // 27.710843373493976%.
  "package:front_end/src/api_prototype/memory_file_system.dart": (
    hitCount: 23,
    missCount: 60,
  ),
  // 38.83495145631068%.
  "package:front_end/src/api_prototype/standard_file_system.dart": (
    hitCount: 40,
    missCount: 63,
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
  // 94.44444444444444%.
  "package:front_end/src/base/builder_graph.dart": (
    hitCount: 17,
    missCount: 1,
  ),
  // 100.0%.
  "package:front_end/src/base/combinator.dart": (
    hitCount: 9,
    missCount: 0,
  ),
  // 70.70707070707071%.
  "package:front_end/src/base/command_line_reporting.dart": (
    hitCount: 70,
    missCount: 29,
  ),
  // 93.22033898305084%.
  "package:front_end/src/base/compiler_context.dart": (
    hitCount: 55,
    missCount: 4,
  ),
  // 100.0%.
  "package:front_end/src/base/configuration.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 59.09090909090909%.
  "package:front_end/src/base/crash.dart": (
    hitCount: 52,
    missCount: 36,
  ),
  // 88.88888888888889%.
  "package:front_end/src/base/export.dart": (
    hitCount: 16,
    missCount: 2,
  ),
  // 50.0%.
  "package:front_end/src/base/hybrid_file_system.dart": (
    hitCount: 21,
    missCount: 21,
  ),
  // 84.78260869565217%.
  "package:front_end/src/base/identifiers.dart": (
    hitCount: 78,
    missCount: 14,
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
  // 96.96969696969697%.
  "package:front_end/src/base/import_chains.dart": (
    hitCount: 96,
    missCount: 3,
  ),
  // 50.795521508544496%.
  "package:front_end/src/base/incremental_compiler.dart": (
    hitCount: 862,
    missCount: 835,
  ),
  // 0.0%.
  "package:front_end/src/base/incremental_serializer.dart": (
    hitCount: 0,
    missCount: 202,
  ),
  // 100.0%.
  "package:front_end/src/base/instrumentation.dart": (
    hitCount: 29,
    missCount: 0,
  ),
  // 86.20689655172413%.
  "package:front_end/src/base/library_graph.dart": (
    hitCount: 25,
    missCount: 4,
  ),
  // 100.0%.
  "package:front_end/src/base/messages.dart": (
    hitCount: 12,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/modifier.dart": (
    hitCount: 29,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/base/operator.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 0.0%.
  "package:front_end/src/base/problems.dart": (
    hitCount: 0,
    missCount: 29,
  ),
  // 40.75993091537133%.
  "package:front_end/src/base/processed_options.dart": (
    hitCount: 236,
    missCount: 343,
  ),
  // 84.01682439537329%.
  "package:front_end/src/base/scope.dart": (
    hitCount: 799,
    missCount: 152,
  ),
  // 73.07692307692307%.
  "package:front_end/src/base/ticker.dart": (
    hitCount: 19,
    missCount: 7,
  ),
  // 100.0%.
  "package:front_end/src/base/uri_offset.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 75.92592592592592%.
  "package:front_end/src/base/uri_translator.dart": (
    hitCount: 41,
    missCount: 13,
  ),
  // 69.23076923076923%.
  "package:front_end/src/base/uris.dart": (
    hitCount: 9,
    missCount: 4,
  ),
  // 0.0%.
  "package:front_end/src/builder/augmentation_iterator.dart": (
    hitCount: 0,
    missCount: 17,
  ),
  // 72.5%.
  "package:front_end/src/builder/builder.dart": (
    hitCount: 29,
    missCount: 11,
  ),
  // 100.0%.
  "package:front_end/src/builder/builder_mixins.dart": (
    hitCount: 42,
    missCount: 0,
  ),
  // 70.0%.
  "package:front_end/src/builder/builtin_type_declaration_builder.dart": (
    hitCount: 7,
    missCount: 3,
  ),
  // 71.64179104477611%.
  "package:front_end/src/builder/class_builder.dart": (
    hitCount: 144,
    missCount: 57,
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
    hitCount: 4,
    missCount: 0,
  ),
  // 100.0%.
  "package:front_end/src/builder/extension_type_declaration_builder.dart": (
    hitCount: 17,
    missCount: 0,
  ),
  // 22.727272727272727%.
  "package:front_end/src/builder/fixed_type_builder.dart": (
    hitCount: 5,
    missCount: 17,
  ),
  // 95.87628865979381%.
  "package:front_end/src/builder/formal_parameter_builder.dart": (
    hitCount: 186,
    missCount: 8,
  ),
  // 77.95275590551181%.
  "package:front_end/src/builder/function_type_builder.dart": (
    hitCount: 99,
    missCount: 28,
  ),
  // 0.0%.
  "package:front_end/src/builder/future_or_type_declaration_builder.dart": (
    hitCount: 0,
    missCount: 10,
  ),
  // 100.0%.
  "package:front_end/src/builder/inferable_type_builder.dart": (
    hitCount: 27,
    missCount: 0,
  ),
  // 33.33333333333333%.
  "package:front_end/src/builder/invalid_type_builder.dart": (
    hitCount: 4,
    missCount: 8,
  ),
  // 85.0%.
  "package:front_end/src/builder/invalid_type_declaration_builder.dart": (
    hitCount: 17,
    missCount: 3,
  ),
  // 78.48101265822784%.
  "package:front_end/src/builder/library_builder.dart": (
    hitCount: 62,
    missCount: 17,
  ),
  // 97.38562091503267%.
  "package:front_end/src/builder/member_builder.dart": (
    hitCount: 149,
    missCount: 4,
  ),
  // 86.04651162790698%.
  "package:front_end/src/builder/metadata_builder.dart": (
    hitCount: 37,
    missCount: 6,
  ),
  // 100.0%.
  "package:front_end/src/builder/mixin_application_builder.dart": (
    hitCount: 1,
    missCount: 0,
  ),
  // 85.0%.
  "package:front_end/src/builder/modifier_builder.dart": (
    hitCount: 17,
    missCount: 3,
  ),
  // 80.60606060606061%.
  "package:front_end/src/builder/named_type_builder.dart": (
    hitCount: 399,
    missCount: 96,
  ),
  // 76.92307692307693%.
  "package:front_end/src/builder/never_type_declaration_builder.dart": (
    hitCount: 10,
    missCount: 3,
  ),
  // 33.33333333333333%.
  "package:front_end/src/builder/null_type_declaration_builder.dart": (
    hitCount: 2,
    missCount: 4,
  ),
  // 100.0%.
  "package:front_end/src/builder/nullability_builder.dart": (
    hitCount: 24,
    missCount: 0,
  ),
  // 37.83783783783784%.
  "package:front_end/src/builder/omitted_type_builder.dart": (
    hitCount: 28,
    missCount: 46,
  ),
  // 0.0%.
  "package:front_end/src/builder/omitted_type_declaration_builder.dart": (
    hitCount: 0,
    missCount: 5,
  ),
  // 89.74358974358975%.
  "package:front_end/src/builder/prefix_builder.dart": (
    hitCount: 35,
    missCount: 4,
  ),
  // 77.77777777777779%.
  "package:front_end/src/builder/record_type_builder.dart": (
    hitCount: 154,
    missCount: 44,
  ),
  // 78.8135593220339%.
  "package:front_end/src/builder/type_alias_builder.dart": (
    hitCount: 186,
    missCount: 50,
  ),
  // 82.35294117647058%.
  "package:front_end/src/builder/type_builder.dart": (
    hitCount: 56,
    missCount: 12,
  ),
  // 90.0%.
  "package:front_end/src/builder/type_declaration_builder.dart": (
    hitCount: 9,
    missCount: 1,
  ),
  // 78.32167832167832%.
  "package:front_end/src/builder/type_variable_builder.dart": (
    hitCount: 336,
    missCount: 93,
  ),
  // 100.0%.
  "package:front_end/src/builder/void_type_declaration_builder.dart": (
    hitCount: 2,
    missCount: 0,
  ),
  // 85.0574712643678%.
  "package:front_end/src/codes/type_labeler.dart": (
    hitCount: 518,
    missCount: 91,
  ),
  // 71.23287671232876%.
  "package:front_end/src/compute_platform_binaries_location.dart": (
    hitCount: 52,
    missCount: 21,
  ),
  // 100.0%.
  "package:front_end/src/dill/dill_builder_mixins.dart": (
    hitCount: 16,
    missCount: 0,
  ),
  // 93.37016574585635%.
  "package:front_end/src/dill/dill_class_builder.dart": (
    hitCount: 169,
    missCount: 12,
  ),
  // 86.74698795180723%.
  "package:front_end/src/dill/dill_extension_builder.dart": (
    hitCount: 72,
    missCount: 11,
  ),
  // 70.29702970297029%.
  "package:front_end/src/dill/dill_extension_member_builder.dart": (
    hitCount: 71,
    missCount: 30,
  ),
  // 95.42483660130719%.
  "package:front_end/src/dill/dill_extension_type_declaration_builder.dart": (
    hitCount: 146,
    missCount: 7,
  ),
  // 83.76623376623377%.
  "package:front_end/src/dill/dill_extension_type_member_builder.dart": (
    hitCount: 129,
    missCount: 25,
  ),
  // 85.05154639175258%.
  "package:front_end/src/dill/dill_library_builder.dart": (
    hitCount: 330,
    missCount: 58,
  ),
  // 77.03349282296651%.
  "package:front_end/src/dill/dill_loader.dart": (
    hitCount: 161,
    missCount: 48,
  ),
  // 86.52173913043478%.
  "package:front_end/src/dill/dill_member_builder.dart": (
    hitCount: 199,
    missCount: 31,
  ),
  // 74.35897435897436%.
  "package:front_end/src/dill/dill_target.dart": (
    hitCount: 29,
    missCount: 10,
  ),
  // 95.83333333333334%.
  "package:front_end/src/dill/dill_type_alias_builder.dart": (
    hitCount: 46,
    missCount: 2,
  ),
  // 100.0%.
  "package:front_end/src/kernel/augmentation_lowering.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 0.0%.
  "package:front_end/src/kernel/benchmarker.dart": (
    hitCount: 0,
    missCount: 128,
  ),
  // 92.1639300493926%.
  "package:front_end/src/kernel/body_builder.dart": (
    hitCount: 6904,
    missCount: 587,
  ),
  // 91.26984126984127%.
  "package:front_end/src/kernel/body_builder_context.dart": (
    hitCount: 345,
    missCount: 33,
  ),
  // 36.83510638297872%.
  "package:front_end/src/kernel/collections.dart": (
    hitCount: 277,
    missCount: 475,
  ),
  // 92.54807692307693%.
  "package:front_end/src/kernel/combined_member_signature.dart": (
    hitCount: 385,
    missCount: 31,
  ),
  // 60.89743589743589%.
  "package:front_end/src/kernel/const_conditional_simplifier.dart": (
    hitCount: 95,
    missCount: 61,
  ),
  // 69.72789115646259%.
  "package:front_end/src/kernel/constant_collection_builders.dart": (
    hitCount: 205,
    missCount: 89,
  ),
  // 85.85694379934975%.
  "package:front_end/src/kernel/constant_evaluator.dart": (
    hitCount: 3697,
    missCount: 609,
  ),
  // 97.59036144578313%.
  "package:front_end/src/kernel/constant_int_folder.dart": (
    hitCount: 243,
    missCount: 6,
  ),
  // 95.11278195488721%.
  "package:front_end/src/kernel/constructor_tearoff_lowering.dart": (
    hitCount: 253,
    missCount: 13,
  ),
  // 75.0392464678179%.
  "package:front_end/src/kernel/exhaustiveness.dart": (
    hitCount: 478,
    missCount: 159,
  ),
  // 79.81651376146789%.
  "package:front_end/src/kernel/expression_generator.dart": (
    hitCount: 2523,
    missCount: 638,
  ),
  // 100.0%.
  "package:front_end/src/kernel/expression_generator_helper.dart": (
    hitCount: 36,
    missCount: 0,
  ),
  // 93.97590361445783%.
  "package:front_end/src/kernel/forest.dart": (
    hitCount: 390,
    missCount: 25,
  ),
  // 94.4927536231884%.
  "package:front_end/src/kernel/forwarding_node.dart": (
    hitCount: 326,
    missCount: 19,
  ),
  // 83.1896551724138%.
  "package:front_end/src/kernel/hierarchy/class_member.dart": (
    hitCount: 386,
    missCount: 78,
  ),
  // 100.0%.
  "package:front_end/src/kernel/hierarchy/delayed.dart": (
    hitCount: 218,
    missCount: 0,
  ),
  // 87.92710706150342%.
  "package:front_end/src/kernel/hierarchy/extension_type_members.dart": (
    hitCount: 386,
    missCount: 53,
  ),
  // 50.77720207253886%.
  "package:front_end/src/kernel/hierarchy/hierarchy_builder.dart": (
    hitCount: 98,
    missCount: 95,
  ),
  // 93.33333333333333%.
  "package:front_end/src/kernel/hierarchy/hierarchy_node.dart": (
    hitCount: 392,
    missCount: 28,
  ),
  // 98.51851851851852%.
  "package:front_end/src/kernel/hierarchy/members_builder.dart": (
    hitCount: 133,
    missCount: 2,
  ),
  // 91.52276295133439%.
  "package:front_end/src/kernel/hierarchy/members_node.dart": (
    hitCount: 1166,
    missCount: 108,
  ),
  // 61.53846153846154%.
  "package:front_end/src/kernel/hierarchy/mixin_inferrer.dart": (
    hitCount: 248,
    missCount: 155,
  ),
  // 60.3896103896104%.
  "package:front_end/src/kernel/implicit_field_type.dart": (
    hitCount: 93,
    missCount: 61,
  ),
  // 5.555555555555555%.
  "package:front_end/src/kernel/implicit_type_argument.dart": (
    hitCount: 1,
    missCount: 17,
  ),
  // 47.25972994440032%.
  "package:front_end/src/kernel/internal_ast.dart": (
    hitCount: 595,
    missCount: 664,
  ),
  // 78.18181818181819%.
  "package:front_end/src/kernel/invalid_type.dart": (
    hitCount: 43,
    missCount: 12,
  ),
  // 55.55555555555556%.
  "package:front_end/src/kernel/kernel_constants.dart": (
    hitCount: 10,
    missCount: 8,
  ),
  // 98.95833333333334%.
  "package:front_end/src/kernel/kernel_helper.dart": (
    hitCount: 285,
    missCount: 3,
  ),
  // 81.35072908672295%.
  "package:front_end/src/kernel/kernel_target.dart": (
    hitCount: 1060,
    missCount: 243,
  ),
  // 61.111111111111114%.
  "package:front_end/src/kernel/kernel_variable_builder.dart": (
    hitCount: 11,
    missCount: 7,
  ),
  // 100.0%.
  "package:front_end/src/kernel/late_lowering.dart": (
    hitCount: 368,
    missCount: 0,
  ),
  // 89.58333333333334%.
  "package:front_end/src/kernel/load_library_builder.dart": (
    hitCount: 43,
    missCount: 5,
  ),
  // 0.1984126984126984%.
  "package:front_end/src/kernel/macro/annotation_parser.dart": (
    hitCount: 2,
    missCount: 1006,
  ),
  // 0.0%.
  "package:front_end/src/kernel/macro/identifiers.dart": (
    hitCount: 0,
    missCount: 120,
  ),
  // 0.0%.
  "package:front_end/src/kernel/macro/introspectors.dart": (
    hitCount: 0,
    missCount: 549,
  ),
  // 0.1932367149758454%.
  "package:front_end/src/kernel/macro/macro.dart": (
    hitCount: 2,
    missCount: 1033,
  ),
  // 0.0%.
  "package:front_end/src/kernel/macro/offsets.dart": (
    hitCount: 0,
    missCount: 201,
  ),
  // 0.0%.
  "package:front_end/src/kernel/macro/types.dart": (
    hitCount: 0,
    missCount: 230,
  ),
  // 91.13475177304964%.
  "package:front_end/src/kernel/member_covariance.dart": (
    hitCount: 257,
    missCount: 25,
  ),
  // 39.473684210526315%.
  "package:front_end/src/kernel/resource_identifier.dart": (
    hitCount: 15,
    missCount: 23,
  ),
  // 15.238095238095239%.
  "package:front_end/src/kernel/static_weak_references.dart": (
    hitCount: 16,
    missCount: 89,
  ),
  // 20.77922077922078%.
  "package:front_end/src/kernel/try_constant_evaluator.dart": (
    hitCount: 16,
    missCount: 61,
  ),
  // 94.27402862985686%.
  "package:front_end/src/kernel/type_algorithms.dart": (
    hitCount: 922,
    missCount: 56,
  ),
  // 92.10526315789474%.
  "package:front_end/src/kernel/type_builder_computer.dart": (
    hitCount: 175,
    missCount: 15,
  ),
  // 37.93103448275862%.
  "package:front_end/src/kernel/utils.dart": (
    hitCount: 66,
    missCount: 108,
  ),
  // 56.25%.
  "package:front_end/src/kernel/verifier.dart": (
    hitCount: 18,
    missCount: 14,
  ),
  // 28.947368421052634%.
  "package:front_end/src/kernel_generator_impl.dart": (
    hitCount: 55,
    missCount: 135,
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
  // 80.29556650246306%.
  "package:front_end/src/source/class_declaration.dart": (
    hitCount: 163,
    missCount: 40,
  ),
  // 93.38129496402877%.
  "package:front_end/src/source/diet_listener.dart": (
    hitCount: 649,
    missCount: 46,
  ),
  // 100.0%.
  "package:front_end/src/source/diet_parser.dart": (
    hitCount: 4,
    missCount: 0,
  ),
  // 93.99141630901288%.
  "package:front_end/src/source/name_scheme.dart": (
    hitCount: 219,
    missCount: 14,
  ),
  // 95.16129032258065%.
  "package:front_end/src/source/offset_map.dart": (
    hitCount: 118,
    missCount: 6,
  ),
  // 93.60228198859005%.
  "package:front_end/src/source/outline_builder.dart": (
    hitCount: 2297,
    missCount: 157,
  ),
  // 94.44444444444444%.
  "package:front_end/src/source/redirecting_factory_body.dart": (
    hitCount: 34,
    missCount: 2,
  ),
  // 88.8268156424581%.
  "package:front_end/src/source/source_builder_mixins.dart": (
    hitCount: 159,
    missCount: 20,
  ),
  // 86.01845280340667%.
  "package:front_end/src/source/source_class_builder.dart": (
    hitCount: 1212,
    missCount: 197,
  ),
  // 93.058568329718%.
  "package:front_end/src/source/source_constructor_builder.dart": (
    hitCount: 858,
    missCount: 64,
  ),
  // 95.73560767590618%.
  "package:front_end/src/source/source_enum_builder.dart": (
    hitCount: 449,
    missCount: 20,
  ),
  // 64.15094339622641%.
  "package:front_end/src/source/source_extension_builder.dart": (
    hitCount: 68,
    missCount: 38,
  ),
  // 84.29423459244532%.
  "package:front_end/src/source/source_extension_type_declaration_builder.dart":
      (
    hitCount: 424,
    missCount: 79,
  ),
  // 92.22222222222223%.
  "package:front_end/src/source/source_factory_builder.dart": (
    hitCount: 581,
    missCount: 49,
  ),
  // 94.2537909018356%.
  "package:front_end/src/source/source_field_builder.dart": (
    hitCount: 1181,
    missCount: 72,
  ),
  // 89.39393939393939%.
  "package:front_end/src/source/source_function_builder.dart": (
    hitCount: 295,
    missCount: 35,
  ),
  // 85.1680467608378%.
  "package:front_end/src/source/source_library_builder.dart": (
    hitCount: 3497,
    missCount: 609,
  ),
  // 81.87472234562416%.
  "package:front_end/src/source/source_loader.dart": (
    hitCount: 1843,
    missCount: 408,
  ),
  // 50.0%.
  "package:front_end/src/source/source_member_builder.dart": (
    hitCount: 25,
    missCount: 25,
  ),
  // 96.11829944547135%.
  "package:front_end/src/source/source_procedure_builder.dart": (
    hitCount: 520,
    missCount: 21,
  ),
  // 97.63313609467455%.
  "package:front_end/src/source/source_type_alias_builder.dart": (
    hitCount: 330,
    missCount: 8,
  ),
  // 83.33333333333334%.
  "package:front_end/src/source/stack_listener_impl.dart": (
    hitCount: 20,
    missCount: 4,
  ),
  // 86.70886075949366%.
  "package:front_end/src/type_inference/closure_context.dart": (
    hitCount: 411,
    missCount: 63,
  ),
  // 77.55474452554745%.
  "package:front_end/src/type_inference/delayed_expressions.dart": (
    hitCount: 425,
    missCount: 123,
  ),
  // 97.88732394366197%.
  "package:front_end/src/type_inference/external_ast_helper.dart": (
    hitCount: 139,
    missCount: 3,
  ),
  // 76.19047619047619%.
  "package:front_end/src/type_inference/factor_type.dart": (
    hitCount: 16,
    missCount: 5,
  ),
  // 75.47169811320755%.
  "package:front_end/src/type_inference/for_in.dart": (
    hitCount: 120,
    missCount: 39,
  ),
  // 87.36842105263159%.
  "package:front_end/src/type_inference/inference_results.dart": (
    hitCount: 166,
    missCount: 24,
  ),
  // 90.44083526682135%.
  "package:front_end/src/type_inference/inference_visitor.dart": (
    hitCount: 7796,
    missCount: 824,
  ),
  // 85.96491228070175%.
  "package:front_end/src/type_inference/inference_visitor_base.dart": (
    hitCount: 2401,
    missCount: 392,
  ),
  // 80.26509572901325%.
  "package:front_end/src/type_inference/matching_cache.dart": (
    hitCount: 545,
    missCount: 134,
  ),
  // 98.10964083175804%.
  "package:front_end/src/type_inference/matching_expressions.dart": (
    hitCount: 519,
    missCount: 10,
  ),
  // 81.13522537562604%.
  "package:front_end/src/type_inference/object_access_target.dart": (
    hitCount: 486,
    missCount: 113,
  ),
  // 98.0%.
  "package:front_end/src/type_inference/shared_type_analyzer.dart": (
    hitCount: 98,
    missCount: 2,
  ),
  // 71.42857142857143%.
  "package:front_end/src/type_inference/standard_bounds.dart": (
    hitCount: 20,
    missCount: 8,
  ),
  // 61.28608923884514%.
  "package:front_end/src/type_inference/type_constraint_gatherer.dart": (
    hitCount: 467,
    missCount: 295,
  ),
  // 95.0%.
  "package:front_end/src/type_inference/type_demotion.dart": (
    hitCount: 19,
    missCount: 1,
  ),
  // 90.29850746268657%.
  "package:front_end/src/type_inference/type_inference_engine.dart": (
    hitCount: 484,
    missCount: 52,
  ),
  // 54.037267080745345%.
  "package:front_end/src/type_inference/type_inferrer.dart": (
    hitCount: 87,
    missCount: 74,
  ),
  // 42.30769230769231%.
  "package:front_end/src/type_inference/type_schema.dart": (
    hitCount: 11,
    missCount: 15,
  ),
  // 88.88888888888889%.
  "package:front_end/src/type_inference/type_schema_elimination.dart": (
    hitCount: 32,
    missCount: 4,
  ),
  // 94.33198380566802%.
  "package:front_end/src/type_inference/type_schema_environment.dart": (
    hitCount: 233,
    missCount: 14,
  ),
  // 0.0%.
  "package:front_end/src/util/error_reporter_file_copier.dart": (
    hitCount: 0,
    missCount: 11,
  ),
  // 85.71428571428571%.
  "package:front_end/src/util/experiment_environment_getter.dart": (
    hitCount: 6,
    missCount: 1,
  ),
  // 52.63157894736842%.
  "package:front_end/src/util/helpers.dart": (
    hitCount: 20,
    missCount: 18,
  ),
  // 5.611510791366906%.
  "package:front_end/src/util/parser_ast.dart": (
    hitCount: 78,
    missCount: 1312,
  ),
  // 86.54205607476636%.
  "package:front_end/src/util/textual_outline.dart": (
    hitCount: 463,
    missCount: 72,
  ),
};
