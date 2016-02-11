// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(function() {
  'use strict';

  let _isolate_helper = dart_library.import('dart/_isolate_helper');
  _isolate_helper.startRootIsolate(function() {}, []);
  let async_helper = dart_library.import('async_helper/async_helper');

  // TODO(jmesserly): separate StrongModeError from other errors.
  let status = {
    'language': {
      expectedFailures: new Set([
        'arithmetic2_test',
        'assert_with_type_test_or_cast_test',
        'assertion_test',
        'async_star_await_pauses_test',
        'async_star_cancel_while_paused_test',
        'async_star_regression_fisk_test',
        'async_switch_test',
        'asyncstar_throw_in_catch_test',
        'await_future_test',
        'bit_operations_test_none_multi',
        'bit_shift_test',
        'bool_test',
        'bound_closure_equality_test',
        'call_closurization_test',
        'call_function_apply_test',
        'call_operator_test',
        'call_property_test',
        'call_test',
        'call_this_test',
        'call_through_null_getter_test',
        'call_with_no_such_method_test',
        'canonical_const2_test',
        'canonical_const_test',
        'cascade_precedence_test',
        'cast_test_01_multi',
        'cast_test_02_multi',
        'cast_test_03_multi',
        'cast_test_07_multi',
        'cast_test_10_multi',
        'cast_test_12_multi',
        'cast_test_13_multi',
        'cast_test_14_multi',
        'cast_test_15_multi',
        'cha_deopt1_test',
        'cha_deopt2_test',
        'cha_deopt3_test',
        'classes_static_method_clash_test',
        'closure_call_wrong_argument_count_negative_test',
        'closure_in_constructor_test',
        'closure_with_super_field_test',
        'closures_initializer_test',
        'code_after_try_is_executed_test_01_multi',
        'compile_time_constant10_test_none_multi',
        'compile_time_constant_a_test',
        'compile_time_constant_b_test',
        'compile_time_constant_d_test',
        'compile_time_constant_i_test',
        'compile_time_constant_k_test_none_multi',
        'compile_time_constant_o_test_none_multi',
        'const_constructor3_test_03_multi',
        'const_escape_frog_test',
        'const_evaluation_test_01_multi',
        'const_map4_test',
        'const_switch_test_02_multi',
        'const_switch_test_04_multi',
        'constructor11_test',
        'constructor12_test',
        'ct_const_test',
        'cyclic_type2_test',
        'cyclic_type_test_00_multi',
        'cyclic_type_test_01_multi',
        'cyclic_type_test_02_multi',
        'cyclic_type_test_03_multi',
        'cyclic_type_test_04_multi',
        'cyclic_type_variable_test_none_multi',
        'deferred_call_empty_before_load_test',
        'deferred_closurize_load_library_test',
        'deferred_constant_list_test',
        'deferred_function_type_test',
        'deferred_inlined_test',
        'deferred_load_inval_code_test',
        'deferred_mixin_test',
        'deferred_no_such_method_test',
        'deferred_not_loaded_check_test',
        'deferred_only_constant_test',
        'deferred_optimized_test',
        'deferred_redirecting_factory_test',
        'deferred_regression_22995_test',
        'deferred_shadow_load_library_test',
        'deferred_shared_and_unshared_classes_test',
        'deferred_static_seperate_test',
        'double_int_to_string_test',
        'double_to_string_test',
        'dynamic_test',
        'enum_mirror_test',
        'exception_test',
        'execute_finally6_test',
        'expect_test',
        'extends_test_lib',
        'external_test_10_multi',
        'external_test_13_multi',
        'external_test_20_multi',
        'f_bounded_quantification3_test',
        'factory_type_parameter_test',
        'fast_method_extraction_test',
        'field_increment_bailout_test',
        'field_optimization3_test',
        'field_test',
        'final_syntax_test_08_multi',
        'first_class_types_literals_test_01_multi',
        'first_class_types_literals_test_02_multi',
        'first_class_types_literals_test_none_multi',
        'first_class_types_test',
        'for_in2_test',
        'for_variable_capture_test',
        'function_propagation_test',
        'function_subtype0_test',
        'function_subtype1_test',
        'function_subtype2_test',
        'function_subtype3_test',
        'function_subtype_bound_closure0_test',
        'function_subtype_bound_closure1_test',
        'function_subtype_bound_closure2_test',
        'function_subtype_bound_closure3_test',
        'function_subtype_bound_closure4_test',
        'function_subtype_bound_closure5_test',
        'function_subtype_bound_closure5a_test',
        'function_subtype_bound_closure6_test',
        'function_subtype_call0_test',
        'function_subtype_call1_test',
        'function_subtype_call2_test',
        'function_subtype_cast0_test',
        'function_subtype_cast1_test',
        'function_subtype_cast2_test',
        'function_subtype_cast3_test',
        'function_subtype_factory0_test',
        'function_subtype_inline0_test',
        'function_subtype_local0_test',
        'function_subtype_local1_test',
        'function_subtype_local2_test',
        'function_subtype_local3_test',
        'function_subtype_local4_test',
        'function_subtype_local5_test',
        'function_subtype_named1_test',
        'function_subtype_named2_test',
        'function_subtype_not0_test',
        'function_subtype_not1_test',
        'function_subtype_not2_test',
        'function_subtype_not3_test',
        'function_subtype_optional1_test',
        'function_subtype_optional2_test',
        'function_subtype_top_level0_test',
        'function_subtype_top_level1_test',
        'function_subtype_typearg0_test',
        'function_subtype_typearg2_test',
        'function_subtype_typearg4_test',
        'function_type_alias2_test',
        'function_type_alias3_test',
        'function_type_alias4_test',
        'function_type_alias6_test_none_multi',
        'function_type_alias_test',
        'function_type_call_getter_test',
        'gc_test',
        'generic2_test',
        'generic_deep_test',
        'generic_field_mixin2_test',
        'generic_field_mixin3_test',
        'generic_field_mixin4_test',
        'generic_field_mixin5_test',
        'generic_field_mixin_test',
        'generic_inheritance_test',
        'generic_instanceof2_test',
        'generic_instanceof3_test',
        'generic_instanceof_test',
        'generic_is_check_test',
        'generic_native_test',
        'generic_parameterized_extends_test',
        'getter_closure_execution_order_test',
        'getter_override2_test_00_multi',
        'getters_setters_test',
        'hash_code_mangling_test',
        'identical_closure2_test',
        'if_null_behavior_test_14_multi',
        'infinite_switch_label_test',
        'infinity_test',
        'instance_creation_in_function_annotation_test',
        'instanceof2_test',
        'instanceof4_test_01_multi',
        'instanceof4_test_none_multi',
        'instanceof_optimized_test',
        'int_test',
        'integer_division_by_zero_test',
        'interceptor_test',
        'is_nan_test',
        'issue10747_test',
        'issue13179_test',
        'issue21079_test',
        'issue21957_test',
        'issue_1751477_test',
        'issue_22780_test_01_multi',
        'issue_23914_test',
        'js_properties_test',
        'lazy_static3_test',
        'least_upper_bound_expansive_test_none_multi',
        'left_shift_test',
        'list_is_test',
        'list_literal3_test',
        'many_generic_instanceof_test',
        'map_literal10_test',
        'map_literal7_test',
        'memory_swap_test',
        'method_invocation_test',
        'mint_arithmetic_test',
        'mixin_forwarding_constructor3_test',
        'mixin_generic_test',
        'mixin_implements_test',
        'mixin_issue10216_2_test',
        'mixin_mixin2_test',
        'mixin_mixin3_test',
        'mixin_mixin4_test',
        'mixin_mixin5_test',
        'mixin_mixin6_test',
        'mixin_mixin7_test',
        'mixin_mixin_bound2_test',
        'mixin_mixin_bound_test',
        'mixin_mixin_test',
        'mixin_regress_13688_test',
        'mixin_type_parameter1_test',
        'mixin_type_parameter2_test',
        'mixin_type_parameter3_test',
        'modulo_test',
        'named_argument_test',
        'named_parameter_clash_test',
        'namer2_test',
        'nan_identical_test',
        'nested_switch_label_test',
        'no_such_method3_test',
        'no_such_method_empty_selector_test',
        'no_such_method_subtype_test',
        'null_no_such_method_test',
        'number_identifier_test_05_multi',
        'number_identity2_test',
        'numbers_test',
        'operator4_test',
        'operator_test',
        'optimized_hoisting_checked_mode_assert_test',
        'positive_bit_operations_test',
        'prefix_test1',
        'prefix_test2',
        'redirecting_factory_reflection_test',
        'regress_13462_0_test',
        'regress_13462_1_test',
        'regress_14105_test',
        'regress_16640_test',
        'regress_21795_test',
        'regress_22443_test',
        'regress_22666_test',
        'regress_22719_test',
        'regress_23650_test',
        'regress_r24720_test',
        'setter_no_getter_test_01_multi',
        'smi_type_test',
        'stack_overflow_stacktrace_test',
        'stack_overflow_test',
        'stack_trace_test',
        'stacktrace_rethrow_error_test_none_multi',
        'stacktrace_rethrow_error_test_withtraceparameter_multi',
        'stacktrace_test',
        'string_interpolate_null_test',
        'string_interpolation_newline_test',
        'super_field_2_test',
        'super_field_test',
        'super_operator_index3_test',
        'super_operator_index4_test',
        'switch_label2_test',
        'switch_label_test',
        'switch_try_catch_test',
        'symbol_literal_test_none_multi',
        'sync_generator1_test_none_multi',
        'throwing_lazy_variable_test',
        'top_level_non_prefixed_library_test',
        'truncdiv_test',
        'type_argument_substitution_test',
        'type_promotion_functions_test_none_multi',
        'type_variable_closure2_test',
        'type_variable_field_initializer_closure_test',
        'type_variable_field_initializer_test',
        'type_variable_nested_test',
        'type_variable_typedef_test',
        'typedef_is_test',

        'bit_operations_test_01_multi',
        'bit_operations_test_02_multi',
        'bit_operations_test_03_multi',
        'bit_operations_test_04_multi',
        'bool_condition_check_test_01_multi',
        'deferred_constraints_constants_test_none_multi',
        'deferred_constraints_constants_test_reference_after_load_multi',
        'deferred_constraints_type_annotation_test_new_generic1_multi',
        'deferred_constraints_type_annotation_test_new_multi',
        'deferred_constraints_type_annotation_test_none_multi',
        'deferred_constraints_type_annotation_test_static_method_multi',
        'deferred_constraints_type_annotation_test_type_annotation_non_deferred_multi',
        'deferred_load_constants_test_none_multi',
        'deferred_load_library_wrong_args_test_01_multi',
        'deferred_load_library_wrong_args_test_none_multi',
        'external_test_21_multi',
        'external_test_24_multi',
        'main_not_a_function_test_01_multi',
        'multiline_newline_test_04_multi',
        'multiline_newline_test_05_multi',
        'multiline_newline_test_06_multi',
        'multiline_newline_test_none_multi',
        'no_main_test_01_multi',
      ]),
      helpers: new Set([
        'library_prefixes_test1',
        'library_prefixes_test2',
        'top_level_prefixed_library_test',
      ])
    },
    'lib/typed_data': {
      expectedFailures: new Set([
        // TODO(vsm): Right shift should not propagate sign
        // https://github.com/dart-lang/dev_compiler/issues/446
        'float32x4_sign_mask_test',
        'int32x4_sign_mask_test',

        // No bigint or int64 support
        'int32x4_bigint_test',
        'int64_list_load_store_test',
        'typed_data_hierarchy_int64_test',

        // TODO(vsm): List.toString is different in DDC
        // https://github.com/dart-lang/dev_compiler/issues/445
        'setRange_1_test',
        'setRange_2_test',
        'setRange_3_test',
        'setRange_4_test',
        'setRange_5_test',

        // TODO(vsm): Triage further
        // exports._GeneratorIterable$ is not a function
        'typed_data_list_test',
      ]),
      helpers: new Set([
      ])
    }
  };

  let testSuites = ['language', 'lib/typed_data'];

  for (let s of testSuites) {
    suite(s, () => {
      let languageTestPattern = new RegExp(s + '/(.*_test.*)');
      for (let testFile of dart_library.libraries()) {
        let match = languageTestPattern.exec(testFile);
        if (match != null) {
          let name = match[1];

          if (status[s].helpers.has(name)) {
            // These are not top-level tests.  They are used by other tests.
            continue;
          }

          // These two tests are special because they use package:unittest.
          // We run them below.
          if (name == 'async_await_test' ||
              name.startsWith('async_star_test')) {
            continue;
          }

          // TODO(jmesserly): figure out why this test is hanging.
          if (name == 'async_star_cancel_and_throw_in_finally_test') {
            console.debug('Skipping known timeout: ' + name);
            continue;
          }

          // TODO(jmesserly): better tracking of async test failures.
          // For now we skip tests that expect failure.
          if (status[s].expectedFailures.has(name)) {
            console.debug('Skipping known failure: ' + name);
            continue;
          }

          test(name, (done) => {
            async_helper.asyncTestInitialize(done);
            console.debug('Running ' + s + ' test:  ' + name);

            dart_library.import(s + '/' + name).main();

            if (!async_helper.asyncTestStarted) done();
          });
        }
      }
    });
  }

  dart_library.import('language/async_await_test_none_multi').main();
  dart_library.import('language/async_star_test_none_multi').main();

})();
