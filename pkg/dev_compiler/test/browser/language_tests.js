// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(function() {
  'use strict';

  let dart_sdk = dart_library.import('dart_sdk');
  dart_sdk._isolate_helper.startRootIsolate(function() {}, []);
  let async_helper = dart_library.import('async_helper').async_helper;

  // Test attributes are a list of strings, or a string for a single
  // attribute. Valid attribues are:
  //
  //   'skip' - don't run the test
  //   'fail' - test fails
  //   'timeout' - test times out
  //   'helper'  - not a test, used by other tests.
  //   'unittest' - run separately as a unittest test.
  //
  // Common combinations:
  const fail = 'fail';
  const skip_fail = ['skip', 'fail'];
  const skip_timeout = ['skip', 'timeout'];

  // TODO(jmesserly): separate StrongModeError from other errors.
  let all_status = {
    'language': {
      'arithmetic2_test': fail,
      'assert_with_type_test_or_cast_test': skip_fail,
      'assertion_test': skip_fail,
      'async_await_test_none_multi': 'unittest',
      'async_star_await_pauses_test': skip_fail,

      // TODO(jmesserly): figure out why this test is hanging.
      'async_star_cancel_and_throw_in_finally_test': skip_timeout,

      'async_star_cancel_while_paused_test': skip_fail,
      'async_star_regression_fisk_test': skip_fail,

      // TODO(vsm): Re-enable.
      // See https://github.com/dart-lang/dev_compiler/issues/456
      'async_star_test_none_multi': ['unittest', 'skip', 'fail'],
      'async_star_test_01_multi': ['unittest', 'skip', 'fail'],
      'async_star_test_02_multi': ['unittest', 'skip', 'fail'],
      'async_star_test_03_multi': ['unittest', 'skip', 'fail'],
      'async_star_test_04_multi': ['unittest', 'skip', 'fail'],
      'async_star_test_05_multi': ['unittest', 'skip', 'fail'],

      'async_switch_test': skip_fail,
      'asyncstar_throw_in_catch_test': skip_fail,
      'await_future_test': skip_fail,
      'bit_operations_test_none_multi': skip_fail,
      'bit_shift_test': skip_fail,
      'bool_test': skip_fail,
      'bound_closure_equality_test': skip_fail,
      'branch_canonicalization_test': skip_fail,  // JS bit operations truncate to 32 bits.
      'call_closurization_test': skip_fail,
      'call_function_apply_test': skip_fail,
      'call_operator_test': skip_fail,
      'call_property_test': skip_fail,
      'call_test': skip_fail,
      'call_this_test': skip_fail,
      'call_through_null_getter_test': skip_fail,
      'call_with_no_such_method_test': skip_fail,
      'canonical_const2_test': skip_fail,
      'canonical_const_test': skip_fail,
      'cascade_precedence_test': skip_fail,
      'cast_test_01_multi': skip_fail,
      'cast_test_02_multi': skip_fail,
      'cast_test_03_multi': skip_fail,
      'cast_test_07_multi': skip_fail,
      'cast_test_10_multi': skip_fail,
      'cast_test_12_multi': skip_fail,
      'cast_test_13_multi': skip_fail,
      'cast_test_14_multi': skip_fail,
      'cast_test_15_multi': skip_fail,
      'cha_deopt1_test': skip_fail,
      'cha_deopt2_test': skip_fail,
      'cha_deopt3_test': skip_fail,
      'classes_static_method_clash_test': skip_fail,
      'closure_call_wrong_argument_count_negative_test': skip_fail,
      'closure_in_constructor_test': skip_fail,
      'closure_with_super_field_test': skip_fail,
      'closures_initializer_test': skip_fail,
      'code_after_try_is_executed_test_01_multi': skip_fail,
      'compile_time_constant10_test_none_multi': skip_fail,
      'compile_time_constant_a_test': skip_fail,
      'compile_time_constant_b_test': skip_fail,
      'compile_time_constant_d_test': skip_fail,
      'compile_time_constant_i_test': skip_fail,
      'compile_time_constant_k_test_none_multi': skip_fail,
      'compile_time_constant_o_test_none_multi': skip_fail,
      'const_constructor3_test_03_multi': skip_fail,
      'const_escape_frog_test': skip_fail,
      'const_evaluation_test_01_multi': skip_fail,
      'const_map4_test': skip_fail,
      'const_switch_test_02_multi': skip_fail,
      'const_switch_test_04_multi': skip_fail,
      'constructor11_test': skip_fail,
      'constructor12_test': skip_fail,
      'ct_const_test': skip_fail,
      'cyclic_type2_test': skip_fail,
      'cyclic_type_test_00_multi': skip_fail,
      'cyclic_type_test_01_multi': skip_fail,
      'cyclic_type_test_02_multi': skip_fail,
      'cyclic_type_test_03_multi': skip_fail,
      'cyclic_type_test_04_multi': skip_fail,
      'cyclic_type_variable_test_none_multi': skip_fail,
      'deferred_call_empty_before_load_test': skip_fail,
      'deferred_closurize_load_library_test': skip_fail,
      'deferred_constant_list_test': skip_fail,
      'deferred_function_type_test': skip_fail,
      'deferred_inlined_test': skip_fail,
      'deferred_load_inval_code_test': skip_fail,
      'deferred_mixin_test': skip_fail,
      'deferred_no_such_method_test': skip_fail,
      'deferred_not_loaded_check_test': skip_fail,
      'deferred_only_constant_test': skip_fail,
      'deferred_optimized_test': skip_fail,
      'deferred_redirecting_factory_test': skip_fail,
      'deferred_regression_22995_test': skip_fail,
      'deferred_shadow_load_library_test': skip_fail,
      'deferred_shared_and_unshared_classes_test': skip_fail,
      'deferred_static_seperate_test': skip_fail,
      'double_int_to_string_test': skip_fail,
      'double_to_string_test': skip_fail,
      'dynamic_test': skip_fail,
      'enum_mirror_test': skip_fail,
      'exception_test': skip_fail,
      'execute_finally6_test': skip_fail,
      'expect_test': skip_fail,
      'extends_test_lib': skip_fail,
      'external_test_10_multi': skip_fail,
      'external_test_13_multi': skip_fail,
      'external_test_20_multi': skip_fail,
      'f_bounded_quantification3_test': skip_fail,
      'factory_type_parameter_test': skip_fail,
      'fast_method_extraction_test': skip_fail,
      'field_increment_bailout_test': skip_fail,
      'field_optimization3_test': skip_fail,
      'field_test': skip_fail,
      'final_syntax_test_08_multi': skip_fail,
      'first_class_types_literals_test_01_multi': skip_fail,
      'first_class_types_literals_test_02_multi': skip_fail,
      'first_class_types_literals_test_none_multi': skip_fail,
      'first_class_types_test': skip_fail,
      'for_in2_test': skip_fail,
      'for_variable_capture_test': skip_fail,
      'function_propagation_test': skip_fail,
      'function_subtype0_test': skip_fail,
      'function_subtype1_test': skip_fail,
      'function_subtype2_test': skip_fail,
      'function_subtype3_test': skip_fail,
      'function_subtype_bound_closure0_test': skip_fail,
      'function_subtype_bound_closure1_test': skip_fail,
      'function_subtype_bound_closure2_test': skip_fail,
      'function_subtype_bound_closure3_test': skip_fail,
      'function_subtype_bound_closure4_test': skip_fail,
      'function_subtype_bound_closure5_test': skip_fail,
      'function_subtype_bound_closure5a_test': skip_fail,
      'function_subtype_bound_closure6_test': skip_fail,
      'function_subtype_call0_test': skip_fail,
      'function_subtype_call1_test': skip_fail,
      'function_subtype_call2_test': skip_fail,
      'function_subtype_cast0_test': skip_fail,
      'function_subtype_cast1_test': skip_fail,
      'function_subtype_cast2_test': skip_fail,
      'function_subtype_cast3_test': skip_fail,
      'function_subtype_factory0_test': skip_fail,
      'function_subtype_inline0_test': skip_fail,
      'function_subtype_local0_test': skip_fail,
      'function_subtype_local1_test': skip_fail,
      'function_subtype_local2_test': skip_fail,
      'function_subtype_local3_test': skip_fail,
      'function_subtype_local4_test': skip_fail,
      'function_subtype_local5_test': skip_fail,
      'function_subtype_named1_test': skip_fail,
      'function_subtype_named2_test': skip_fail,
      'function_subtype_not0_test': skip_fail,
      'function_subtype_not1_test': skip_fail,
      'function_subtype_not2_test': skip_fail,
      'function_subtype_not3_test': skip_fail,
      'function_subtype_optional1_test': skip_fail,
      'function_subtype_optional2_test': skip_fail,
      'function_subtype_top_level0_test': skip_fail,
      'function_subtype_top_level1_test': skip_fail,
      'function_subtype_typearg0_test': skip_fail,
      'function_subtype_typearg2_test': skip_fail,
      'function_subtype_typearg4_test': skip_fail,
      'function_type_alias2_test': skip_fail,
      'function_type_alias3_test': skip_fail,
      'function_type_alias4_test': skip_fail,
      'function_type_alias6_test_none_multi': skip_fail,
      'function_type_alias_test': skip_fail,
      'function_type_call_getter_test': skip_fail,
      'gc_test': skip_fail,
      'generic2_test': skip_fail,
      'generic_deep_test': skip_fail,
      'generic_field_mixin2_test': skip_fail,
      'generic_field_mixin3_test': skip_fail,
      'generic_field_mixin4_test': skip_fail,
      'generic_field_mixin5_test': skip_fail,
      'generic_field_mixin_test': skip_fail,
      'generic_inheritance_test': skip_fail,
      'generic_instanceof2_test': skip_fail,
      'generic_instanceof3_test': skip_fail,
      'generic_instanceof_test': skip_fail,
      'generic_is_check_test': skip_fail,
      'generic_native_test': skip_fail,
      'generic_parameterized_extends_test': skip_fail,
      'getter_closure_execution_order_test': skip_fail,
      'getter_override2_test_00_multi': skip_fail,
      'getters_setters_test': skip_fail,
      'hash_code_mangling_test': skip_fail,
      'identical_closure2_test': skip_fail,
      'if_null_behavior_test_14_multi': skip_fail,
      'infinite_switch_label_test': skip_fail,
      'infinity_test': skip_fail,
      'instance_creation_in_function_annotation_test': skip_fail,
      'instanceof2_test': skip_fail,
      'instanceof4_test_01_multi': skip_fail,
      'instanceof4_test_none_multi': skip_fail,
      'instanceof_optimized_test': skip_fail,
      'int_test': skip_fail,
      'integer_division_by_zero_test': skip_fail,
      'interceptor_test': skip_fail,
      'interceptor9_test': skip_fail,
      'is_nan_test': skip_fail,
      'issue10747_test': skip_fail,
      'issue13179_test': skip_fail,
      'issue21079_test': skip_fail,
      'issue21957_test': skip_fail,
      'issue_1751477_test': skip_fail,
      'issue_22780_test_01_multi': skip_fail,
      'issue_23914_test': skip_fail,
      'js_properties_test': skip_fail,
      'lazy_static3_test': skip_fail,
      'least_upper_bound_expansive_test_none_multi': skip_fail,
      'left_shift_test': skip_fail,
      'list_is_test': skip_fail,
      'list_literal3_test': skip_fail,
      'many_generic_instanceof_test': skip_fail,
      'map_literal10_test': skip_fail,
      'map_literal7_test': skip_fail,
      'memory_swap_test': skip_fail,
      'method_invocation_test': skip_fail,
      'mint_arithmetic_test': skip_fail,
      'mixin_forwarding_constructor3_test': skip_fail,
      'mixin_generic_test': skip_fail,
      'mixin_implements_test': skip_fail,
      'mixin_issue10216_2_test': skip_fail,
      'mixin_mixin2_test': skip_fail,
      'mixin_mixin3_test': skip_fail,
      'mixin_mixin4_test': skip_fail,
      'mixin_mixin5_test': skip_fail,
      'mixin_mixin6_test': skip_fail,
      'mixin_mixin7_test': skip_fail,
      'mixin_mixin_bound2_test': skip_fail,
      'mixin_mixin_bound_test': skip_fail,
      'mixin_mixin_test': skip_fail,
      'mixin_regress_13688_test': skip_fail,
      'mixin_type_parameter1_test': skip_fail,
      'mixin_type_parameter2_test': skip_fail,
      'mixin_type_parameter3_test': skip_fail,
      'modulo_test': skip_fail,
      'named_argument_test': skip_fail,
      'named_parameter_clash_test': skip_fail,
      'namer2_test': skip_fail,
      'nan_identical_test': skip_fail,
      'nested_switch_label_test': skip_fail,
      'no_such_method3_test': skip_fail,
      'no_such_method_empty_selector_test': skip_fail,
      'no_such_method_subtype_test': skip_fail,
      'null_no_such_method_test': skip_fail,
      'number_identifier_test_05_multi': skip_fail,
      'number_identity2_test': skip_fail,
      'numbers_test': skip_fail,
      'operator4_test': skip_fail,
      'operator_test': skip_fail,
      'optimized_hoisting_checked_mode_assert_test': skip_fail,
      'positive_bit_operations_test': skip_fail,
      'prefix_test1': skip_fail,
      'prefix_test2': skip_fail,
      'redirecting_factory_reflection_test': skip_fail,
      'regress_13462_0_test': skip_fail,
      'regress_13462_1_test': skip_fail,
      'regress_14105_test': skip_fail,
      'regress_16640_test': skip_fail,
      'regress_18535_test': skip_fail,
      'regress_21795_test': skip_fail,
      'regress_22443_test': skip_fail,
      'regress_22666_test': skip_fail,
      'regress_22719_test': skip_fail,
      'regress_23650_test': skip_fail,
      'regress_r24720_test': skip_fail,
      'setter_no_getter_test_01_multi': skip_fail,
      'smi_type_test': skip_fail,
      'stack_overflow_stacktrace_test': skip_fail,
      'stack_overflow_test': skip_fail,
      'stack_trace_test': skip_fail,
      'stacktrace_rethrow_nonerror_test': skip_fail, // mismatch from Karma's file hash
      'stacktrace_rethrow_error_test_none_multi': skip_fail,
      'stacktrace_rethrow_error_test_withtraceparameter_multi': skip_fail,
      'stacktrace_test': skip_fail,
      'string_interpolate_null_test': skip_fail,
      'string_interpolation_newline_test': skip_fail,
      'super_field_2_test': skip_fail,
      'super_field_test': skip_fail,
      'super_operator_index3_test': skip_fail,
      'super_operator_index4_test': skip_fail,
      'switch_label2_test': skip_fail,
      'switch_label_test': skip_fail,
      'switch_try_catch_test': skip_fail,
      'sync_generator1_test_none_multi': skip_fail,
      'throwing_lazy_variable_test': skip_fail,
      'top_level_non_prefixed_library_test': skip_fail,
      'truncdiv_test': skip_fail,
      'type_argument_substitution_test': skip_fail,
      'type_promotion_functions_test_none_multi': skip_fail,
      'type_variable_closure2_test': skip_fail,
      'type_variable_field_initializer_closure_test': skip_fail,
      'type_variable_field_initializer_test': skip_fail,
      'type_variable_nested_test': skip_fail,
      'type_variable_typedef_test': skip_fail,
      'typedef_is_test': skip_fail,

      'bit_operations_test_01_multi': skip_fail,
      'bit_operations_test_02_multi': skip_fail,
      'bit_operations_test_03_multi': skip_fail,
      'bit_operations_test_04_multi': skip_fail,
      'bool_condition_check_test_01_multi': skip_fail,
      'deferred_constraints_constants_test_none_multi': skip_fail,
      'deferred_constraints_constants_test_reference_after_load_multi': skip_fail,
      'deferred_constraints_type_annotation_test_new_generic1_multi': skip_fail,
      'deferred_constraints_type_annotation_test_new_multi': skip_fail,
      'deferred_constraints_type_annotation_test_none_multi': skip_fail,
      'deferred_constraints_type_annotation_test_static_method_multi': skip_fail,
      'deferred_constraints_type_annotation_test_type_annotation_non_deferred_multi': skip_fail,
      'deferred_load_constants_test_none_multi': skip_fail,
      'deferred_load_library_wrong_args_test_01_multi': skip_fail,
      'deferred_load_library_wrong_args_test_none_multi': skip_fail,
      'external_test_21_multi': skip_fail,
      'external_test_24_multi': skip_fail,
      'main_not_a_function_test_01_multi': skip_fail,
      'multiline_newline_test_04_multi': skip_fail,
      'multiline_newline_test_05_multi': skip_fail,
      'multiline_newline_test_06_multi': skip_fail,
      'multiline_newline_test_none_multi': skip_fail,
      'no_main_test_01_multi': skip_fail,

      // https://github.com/dart-lang/sdk/issues/26123
      'bad_raw_string_negative_test': skip_fail,

      // https://github.com/dart-lang/sdk/issues/26124
      'prefix10_negative_test': skip_fail,


      // TODO(vsm): Right shift should not propagate sign
      // https://github.com/dart-lang/dev_compiler/issues/446
      'float32x4_sign_mask_test': skip_fail,
      'int32x4_sign_mask_test': skip_fail,

      // TODO(vsm): Triage further
      // exports._GeneratorIterable$ is not a function
      'typed_data_list_test': skip_fail,
      'byte_data_test': skip_fail,
      'endianness_test': skip_fail,

      'library_prefixes_test1': 'helper',
      'library_prefixes_test2': 'helper',
      'top_level_prefixed_library_test': 'helper',
    },

    'lib/typed_data': {
      // No bigint or int64 support
      'int32x4_bigint_test': skip_fail,
      'int64_list_load_store_test': skip_fail,
      'typed_data_hierarchy_int64_test': skip_fail,

      // TODO(vsm): List.toString is different in DDC
      // https://github.com/dart-lang/dev_compiler/issues/445
      'setRange_1_test': skip_fail,
      'setRange_2_test': skip_fail,
      'setRange_3_test': skip_fail,
      'setRange_4_test': skip_fail,
      'setRange_5_test': skip_fail,
    },

    'lib/html': {
    },
  };

  let unittest_tests = [];

  let languageTestPattern = new RegExp('(.*)/([^/]*_test[^/]*)');
  for (let testFile of dart_library.libraries()) {
    let match = languageTestPattern.exec(testFile);
    if (match != null) {
      let status_group = match[1]
      let name = match[2];
      let module = match[0];

      let status = all_status[status_group];
      if (status == null) throw "No status for '" + status_group + "'";

      let expectation = status[name];
      if (expectation == null) expectation = [];
      if (typeof expectation == 'string') expectation = [expectation];
      function has(tag) {
        return expectation.indexOf(tag) >= 0;
      }

      if (has('helper')) {
        // These are not top-level tests.  They are used by other tests.
        continue;
      }

      if (has('skip')) {
        let why = 'for unknown reason';
        if (has('timeout')) why = 'known timeout';
        if (has('fail')) why = 'known failure';
        console.debug('Skipping ' + why + ': ' + name);
        continue;
      }

      // A few tests are special because they use package:unittest.
      // We run them below.
      if (has('unittest')) {
        unittest_tests.push(() => {
          console.log('Running unittest test ' + testFile);
          dart_library.import(module)[name].main();
        });
        continue;
      }

      test(name, (done) => {
        async_helper.asyncTestInitialize(done);
        console.debug('Running test:  ' + name);

        let mainLibrary = dart_library.import(module)[name];
        let negative = /negative_test/.test(name);
        if (has('fail')) negative = !negative;
        if (negative) {
          assert.throws(mainLibrary.main);
        } else {
          mainLibrary.main();
        }

        if (!async_helper.asyncTestStarted) done();
      });
    }
  }

  for (let action of unittest_tests) {
    action();
  }
})();
