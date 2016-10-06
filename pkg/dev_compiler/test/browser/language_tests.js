// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

define(['dart_sdk', 'async_helper', 'unittest', 'require'],
      function(dart_sdk, async_helper, unittest, require) {
  'use strict';

  async_helper = async_helper.async_helper;

  dart_sdk._isolate_helper.startRootIsolate(function() {}, []);
  let html_config = unittest.html_config;
  // Test attributes are a list of strings, or a string for a single
  // attribute. Valid attributes are:
  //
  //   'skip' - don't run the test
  //   'fail' - test fails
  //   'timeout' - test times out
  //   'slow' - use 5s timeout instead of default 2s.
  //   'helper'  - not a test, used by other tests.
  //   'unittest' - run separately as a unittest test.
  //
  // Common combinations:
  const fail = 'fail';
  const skip_fail = ['skip', 'fail'];
  const skip_timeout = ['skip', 'timeout'];

  // The number of expected unittest errors should be zero but unfortunately
  // there are a lot of broken html unittests.
  let num_expected_unittest_fails = 5;
  let num_expected_unittest_errors = 8;

  // TODO(jmesserly): separate StrongModeError from other errors.
  let all_status = {
    'language': {
      'assert_with_type_test_or_cast_test': skip_fail,
      'assertion_test': skip_fail,
      'async_await_test_none_multi': 'unittest',
      'async_await_test_02_multi': 'unittest',
      'async_await_test_03_multi': skip_fail,  // Flaky on travis (#634)
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
      'bit_operations_test_none_multi': skip_fail,  // DDC/dart2js canonicalize bitop results to unsigned
      'bool_test': skip_fail,
      'branch_canonicalization_test': skip_fail,  // JS bit operations truncate to 32 bits.
      'call_closurization_test': fail, // Functions do not expose a "call" method.
      'call_function_apply_test': fail, // Function.apply not really implemented.
      'call_through_null_getter_test': fail, // null errors are not converted to NoSuchMethodErrors.
      'call_with_no_such_method_test': fail, // Function.apply not really implemented.
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

      // interpolation does not call Dart's toString:
      // https://github.com/dart-lang/dev_compiler/issues/470
      'class_syntax2_test': skip_fail,
      'classes_static_method_clash_test': skip_fail,
      'closure_call_wrong_argument_count_negative_test': skip_fail,
      'closure_in_constructor_test': skip_fail,
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
      'const_switch_test_02_multi': skip_fail,
      'const_switch_test_04_multi': skip_fail,
      'constructor11_test': skip_fail,
      'constructor12_test': skip_fail,
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
      'deferred_no_such_method_test': skip_fail, // deferred libs not implemented
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
      'exception_test': fail,
      'execute_finally6_test': skip_fail,
      'expect_test': skip_fail,
      'extends_test_lib': skip_fail,
      'external_test_10_multi': skip_fail,
      'external_test_13_multi': skip_fail,
      'external_test_20_multi': skip_fail,
      'f_bounded_quantification3_test': skip_fail,
      'factory_type_parameter_test': skip_fail,
      'fast_method_extraction_test': skip_fail,
      'field_increment_bailout_test': fail,
      'field_optimization3_test': skip_fail,
      'final_syntax_test_08_multi': skip_fail,
      'first_class_types_test': skip_fail,
      'for_in2_test': skip_fail,
      'for_variable_capture_test': skip_fail,
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
      'function_subtype_call0_test': fail, // Strong mode "is" rejects some type tests.
      'function_subtype_call1_test': fail,
      'function_subtype_call2_test': fail,
      'function_subtype_cast0_test': fail,
      'function_subtype_cast1_test': fail,
      'function_subtype_cast2_test': fail,
      'function_subtype_cast3_test': fail,
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
      'gc_test': skip_fail,
      'generic_field_mixin2_test': skip_fail,
      'generic_field_mixin3_test': skip_fail,
      'generic_field_mixin4_test': skip_fail,
      'generic_field_mixin5_test': skip_fail,
      'generic_field_mixin_test': skip_fail,
      'generic_instanceof_test': fail, // runtime strong mode reject
      'generic_instanceof2_test': skip_fail,
      'generic_is_check_test': skip_fail,
      'getter_closure_execution_order_test': skip_fail,
      'hash_code_mangling_test': skip_fail,
      'identical_closure2_test': skip_fail,
      'infinite_switch_label_test': skip_fail,
      'infinity_test': skip_fail,
      'instance_creation_in_function_annotation_test': skip_fail,
      'instanceof2_test': fail,
      'instanceof4_test_01_multi': fail,
      'instanceof4_test_none_multi': fail,
      'instanceof_optimized_test': skip_fail,
      'integer_division_by_zero_test': fail,
      'is_nan_test': fail,
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
      'modulo_test': fail,
      'named_parameter_clash_test': skip_fail,
      'nan_identical_test': skip_fail,
      'nested_switch_label_test': skip_fail,
      'number_identifier_test_05_multi': skip_fail,
      'number_identity2_test': skip_fail,
      'numbers_test': skip_fail,
      'optimized_hoisting_checked_mode_assert_test': skip_fail,
      'redirecting_factory_reflection_test': skip_fail,
      'regress_13462_0_test': skip_fail,
      'regress_13462_1_test': skip_fail,
      'regress_14105_test': skip_fail,
      'regress_16640_test': skip_fail,
      'regress_21795_test': skip_fail,
      'regress_22443_test': skip_fail,
      'regress_22666_test': skip_fail,
      'setter_no_getter_test_01_multi': skip_fail,
      'stack_overflow_stacktrace_test': skip_fail,
      'stack_overflow_test': skip_fail,
      'stack_trace_test': skip_fail,
      'stacktrace_rethrow_nonerror_test': skip_fail, // mismatch from Karma's file hash
      'stacktrace_rethrow_error_test_none_multi': skip_fail,
      'stacktrace_rethrow_error_test_withtraceparameter_multi': skip_fail,
      'stacktrace_test': skip_fail,
      'string_interpolate_null_test': skip_fail,
      'super_operator_index3_test': skip_fail,
      'super_operator_index4_test': skip_fail,
      'switch_label2_test': skip_fail,
      'switch_label_test': skip_fail,
      'switch_try_catch_test': skip_fail,
      'sync_generator1_test_none_multi': skip_fail,
      'throwing_lazy_variable_test': skip_fail,
      'top_level_non_prefixed_library_test': skip_fail,
      'truncdiv_test': fail,  // did not throw
      'type_variable_nested_test': skip_fail,  // unsound is-check
      'type_variable_typedef_test': skip_fail,  // unsound is-check

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

      'library_prefixes_test1': 'helper',
      'library_prefixes_test2': 'helper',
      'top_level_prefixed_library_test': 'helper',

    },

    'corelib': {
      'apply2_test': fail,
      'apply3_test': fail,
      'apply_test': fail,
      'big_integer_parsed_arith_vm_test': fail,
      'big_integer_parsed_div_rem_vm_test': fail,
      'big_integer_parsed_mul_div_vm_test': fail,
      'bit_twiddling_bigint_test': fail,
      'collection_length_test': skip_timeout,
      'compare_to2_test': fail,
      'const_list_literal_test': fail,
      'const_list_remove_range_test': fail,
      'const_list_set_range_test': fail,
      'double_parse_test_01_multi': fail,
      'error_stack_trace1_test': fail,
      'error_stack_trace2_test': fail,
      'hash_map2_test': skip_timeout,
      'hash_set_test_01_multi': fail,
      'hidden_library2_test_01_multi': fail,
      'indexed_list_access_test': fail,
      'int_modulo_arith_test_bignum_multi': fail,
      'int_modulo_arith_test_modPow_multi': fail,
      'int_modulo_arith_test_none_multi': fail,
      'int_parse_radix_test_01_multi': fail, // JS implementations disagree on U+0085 being whitespace.
      'int_parse_radix_test_02_multi': ['fail', 'timeout', 'skip'], // No bigints.
      'int_parse_radix_test_none_multi': ['slow'],
      'integer_to_radix_string_test': fail,
      'integer_to_string_test_01_multi': fail,
      'iterable_generate_test': fail,
      'iterable_return_type_test_02_multi': fail,
      'json_map_test': fail,
      'list_fill_range_test': fail,
      'list_replace_range_test': fail,
      'list_set_all_test': fail,
      'list_to_string2_test': fail,
      'main_test': fail,
      'map_keys2_test': fail,
      'map_to_string_test': fail,
      'nan_infinity_test_01_multi': fail,
      'null_nosuchmethod_test': fail,
      'null_test': fail,
      'num_sign_test': fail,
      'regress_r21715_test': fail,
      'throw_half_surrogate_pair_test_02_multi': fail,
      'stacktrace_current_test': fail,
      'string_fromcharcodes_test': skip_timeout,
      'string_operations_with_null_test': fail,
      'symbol_reserved_word_test_06_multi': fail,
      'symbol_reserved_word_test_09_multi': fail,
      'symbol_reserved_word_test_12_multi': fail,
      'throw_half_surrogate_pair_test_01_multi': fail,
      // TODO(rnystrom): Times out because it tests a huge number of
      // combinations of URLs (4 * 5 * 5 * 8 * 6 * 6 * 4 = 115200).
      'uri_parse_test': skip_timeout,

      'list_insert_test': fail,
      'list_removeat_test': fail,
      'set_test': fail, // runtime strong mode reject
    },

    'corelib/regexp': {
      'default_arguments_test': fail
    },

    'lib/convert': {
      'encoding_test': skip_timeout,

      // TODO(jmesserly): this is in an inconsistent state between our old and
      // newer SDKs.
      'html_escape_test': ['skip'],

      'json_lib_test': 'unittest',

      'json_utf8_chunk_test': skip_timeout,
      'latin1_test': skip_timeout,

      'streamed_conversion_json_encode1_test': skip_timeout,
      'streamed_conversion_json_utf8_decode_test': skip_timeout,
      'streamed_conversion_json_utf8_encode_test': skip_timeout,
      'streamed_conversion_utf8_decode_test': skip_timeout,
      'streamed_conversion_utf8_encode_test': skip_timeout,
      'utf85_test': skip_timeout,
    },

    // TODO(jacobr): enable more of the html tests in unittest once they have
    // more hope of passing. Triage tests that can never run in this test
    // runner and track them separately.
    'lib/html': {
      'async_spawnuri_test': ['unittest', 'skip', 'fail'],
      'async_test': ['unittest', 'skip', 'fail'],
      'audiobuffersourcenode_test': ['unittest', 'skip', 'fail'],
      'audiocontext_test': ['unittest', 'skip', 'fail'],
      'audioelement_test': ['unittest', 'skip', 'fail'],
      'b_element_test': ['unittest', 'skip', 'fail'],
      'blob_constructor_test': ['unittest', 'skip', 'fail'],
      'cache_test': ['unittest', 'skip', 'fail'],
      'callbacks_test': ['unittest', 'skip', 'fail'],
      'canvas_pixel_array_type_alias_test': ['unittest'],
      'canvasrenderingcontext2d_test': ['unittest'],
      'canvas_test': ['unittest'],
      'cdata_test': ['unittest', 'skip', 'fail'],
      'client_rect_test': ['unittest', 'skip', 'fail'],
      'cross_domain_iframe_test': ['unittest', 'skip', 'fail'],
      'cross_frame_test': ['unittest', 'skip', 'fail'],
      'crypto_test': ['unittest', 'skip', 'fail'],
      'css_rule_list_test': ['unittest', 'skip', 'fail'],
      'cssstyledeclaration_test': ['unittest', 'skip', 'fail'],
      'css_test': ['unittest', 'skip', 'fail'],
      'custom_element_method_clash_test': ['unittest', 'skip', 'fail'],
      'custom_element_name_clash_test': ['unittest', 'skip', 'fail'],
      'custom_elements_23127_test': ['unittest', 'skip', 'fail'],
      'custom_elements_test': ['unittest', 'skip', 'fail'],
      'custom_tags_test': ['unittest', 'skip', 'fail'],
      'dart_object_local_storage_test': ['unittest', 'skip', 'fail'],
      'datalistelement_test': ['unittest', 'skip', 'fail'],
      'documentfragment_test': ['unittest', 'skip', 'fail'],
      'document_test': ['unittest'],
      'dom_constructors_test': ['unittest', 'skip', 'fail'],
      'domparser_test': ['unittest', 'skip', 'fail'],
      'element_add_test': ['unittest', 'skip', 'fail'],
      'element_animate_test': ['unittest', 'skip', 'fail'],
      'element_classes_svg_test': ['unittest', 'skip', 'fail'],
      'element_classes_test': ['unittest', 'skip', 'fail'],
      'element_constructor_1_test': ['unittest', 'skip', 'fail'],
      'element_dimensions_test': ['unittest', 'skip', 'fail'],
      'element_offset_test': ['unittest', 'skip', 'fail'],
      'element_test': ['unittest', 'skip', 'fail'],
      'element_types_constructors1_test': ['unittest', 'skip', 'fail'],
      'element_types_constructors2_test': ['unittest', 'skip', 'fail'],
      'element_types_constructors3_test': ['unittest', 'skip', 'fail'],
      'element_types_constructors4_test': ['unittest', 'skip', 'fail'],
      'element_types_constructors5_test': ['unittest', 'skip', 'fail'],
      'element_types_constructors6_test': ['unittest', 'skip', 'fail'],
      'element_types_test': ['unittest', 'skip', 'fail'],
      'event_customevent_test': ['unittest', 'skip', 'fail'],
      'events_test': ['unittest', 'skip', 'fail'],
      'event_test': ['unittest', 'skip', 'fail'],
      'exceptions_test': ['unittest', 'skip', 'fail'],
      'fileapi_test': ['unittest', 'skip', 'fail'],
      'filereader_test': ['unittest', 'skip', 'fail'],
      'filteredelementlist_test': ['unittest', 'skip', 'fail'],
      'fontface_loaded_test': ['unittest', 'skip', 'fail'],
      'fontface_test': ['unittest', 'skip', 'fail'],
      'form_data_test': ['unittest', 'skip', 'fail'],
      'form_element_test': ['unittest', 'skip', 'fail'],
      'geolocation_test': ['unittest', 'skip', 'fail'],
      'hidden_dom_1_test': ['unittest', 'skip', 'fail'],
      'hidden_dom_2_test': ['unittest', 'skip', 'fail'],
      'history_test': ['unittest', 'skip', 'fail'],
      'htmlcollection_test': ['unittest', 'skip', 'fail'],
      'htmlelement_test': ['unittest', 'skip', 'fail'],
      'htmloptionscollection_test': ['unittest', 'skip', 'fail'],
      'indexeddb_1_test': ['unittest', 'skip', 'fail'],
      'indexeddb_2_test': ['unittest', 'skip', 'fail'],
      'indexeddb_3_test': ['unittest', 'skip', 'fail'],
      'indexeddb_4_test': ['unittest', 'skip', 'fail'],
      'indexeddb_5_test': ['unittest', 'skip', 'fail'],
      'input_element_test': ['unittest', 'skip', 'fail'],
      'instance_of_test': ['unittest', 'skip', 'fail'],
      'interactive_test': ['unittest', 'skip', 'fail'],
      'isolates_test': ['unittest', 'skip', 'fail'],
      'js_function_getter_test': 'unittest',
      'js_function_getter_trust_types_test': 'unittest',
      'js_interop_1_test': 'unittest',
      'js_test': 'unittest',
      'js_util_test': 'unittest',
      'js_typed_interop_anonymous2_exp_test': 'unittest',
      'js_typed_interop_anonymous2_test': 'unittest',
      'js_typed_interop_anonymous_exp_test': 'unittest',
      'js_typed_interop_anonymous_test': 'unittest',
      'js_typed_interop_anonymous_unreachable_exp_test': 'unittest',
      'js_typed_interop_anonymous_unreachable_test': 'unittest',
      'js_typed_interop_default_arg_test': 'unittest',
      'js_typed_interop_side_cast_exp_test': 'unittest',
      'js_typed_interop_side_cast_test': 'unittest',
      'js_typed_interop_test': 'unittest',
      'keyboard_event_test': ['unittest', 'skip', 'fail'],
      'localstorage_test': ['unittest', 'skip', 'fail'],
      'location_test': ['unittest', 'skip', 'fail'],
      'mediasource_test': ['unittest', 'skip', 'fail'],
      'media_stream_test': ['unittest', 'skip', 'fail'],
      'messageevent_test': ['unittest', 'skip', 'fail'],
      'mirrors_js_typed_interop_test': ['unittest', 'skip', 'fail'],
      'mouse_event_test': ['unittest', 'skip', 'fail'],
      'mutationobserver_test': ['unittest', 'skip', 'fail'],
      'native_gc_test': ['unittest', 'skip', 'fail'],
      'navigator_test': ['unittest', 'skip', 'fail'],
      'node_test': ['unittest', 'skip', 'fail'],
      'node_validator_important_if_you_suppress_make_the_bug_critical_test': ['unittest', 'skip', 'fail'],
      'non_instantiated_is_test': ['unittest', 'skip', 'fail'],
      'notification_test': ['unittest', 'skip', 'fail'],
      'performance_api_test': ['unittest', 'skip', 'fail'],
      'postmessage_structured_test': ['unittest', 'skip', 'fail'],
      'private_extension_member_test': ['unittest', 'skip', 'fail'],
      'queryall_test': ['unittest', 'skip', 'fail'],
      'query_test': ['unittest', 'skip', 'fail'],
      'range_test': ['unittest', 'skip', 'fail'],
      'request_animation_frame_test': ['unittest', 'skip', 'fail'],
      'resource_http_test': ['unittest', 'skip', 'fail'],
      'rtc_test': ['unittest', 'skip', 'fail'],
      'selectelement_test': ['unittest', 'skip', 'fail'],
      'serialized_script_value_test': ['unittest', 'skip', 'fail'],
      'shadow_dom_test': ['unittest', 'skip', 'fail'],
      'shadowroot_test': ['unittest', 'skip', 'fail'],
      'speechrecognition_test': ['unittest', 'skip', 'fail'],
      'storage_test': ['unittest', 'skip', 'fail'],
      'streams_test': ['unittest', 'skip', 'fail'],
      'svgelement_test': ['unittest', 'skip', 'fail'],
      'svg_test': ['unittest', 'skip', 'fail'],
      'table_test': ['unittest', 'skip', 'fail'],
      'text_event_test': ['unittest', 'skip', 'fail'],
      'touchevent_test': ['unittest', 'skip', 'fail'],
      'track_element_constructor_test': ['unittest', 'skip', 'fail'],
      'transferables_test': ['unittest', 'skip', 'fail'],
      'transition_event_test': ['unittest', 'skip', 'fail'],
      'trusted_html_tree_sanitizer_test': ['unittest', 'skip', 'fail'],
      'typed_arrays_1_test': ['unittest', 'skip', 'fail'],
      'typed_arrays_2_test': ['unittest', 'skip', 'fail'],
      'typed_arrays_3_test': ['unittest', 'skip', 'fail'],
      'typed_arrays_4_test': ['unittest', 'skip', 'fail'],
      'typed_arrays_5_test': ['unittest', 'skip', 'fail'],
      'typed_arrays_arraybuffer_test': ['unittest', 'skip', 'fail'],
      'typed_arrays_dataview_test': ['unittest', 'skip', 'fail'],
      'typed_arrays_range_checks_test': ['unittest', 'skip', 'fail'],
      'typed_arrays_simd_test': ['unittest', 'skip', 'fail'],
      'typing_test': ['unittest', 'skip', 'fail'],
      'unknownelement_test': ['unittest', 'skip', 'fail'],
      'uri_test': ['unittest', 'skip', 'fail'],
      'url_test': ['unittest', 'skip', 'fail'],
      'webgl_1_test': ['unittest', 'skip', 'fail'],
      'websocket_test': ['unittest', 'skip', 'fail'],
      'websql_test': ['unittest', 'skip', 'fail'],
      'wheelevent_test': ['unittest', 'skip', 'fail'],
      'window_eq_test': ['unittest', 'skip', 'fail'],
      'window_mangling_test': ['unittest', 'skip', 'fail'],
      'window_nosuchmethod_test': ['unittest', 'skip', 'fail'],
      'window_test': ['unittest', 'skip', 'fail'],
      'worker_api_test': ['unittest', 'skip', 'fail'],
      'worker_test': ['unittest', 'skip', 'fail'],
      'wrapping_collections_test': ['unittest', 'skip', 'fail'],
      'xhr_cross_origin_test': ['unittest', 'skip', 'fail'],
      'xhr_test': ['unittest', 'skip', 'fail'],
      'xsltprocessor_test': ['unittest', 'skip', 'fail'],

      'js_typed_interop_default_arg_test_none_multi': ['unittest', 'skip', 'fail'],
      'js_typed_interop_default_arg_test_explicit_argument_multi': ['unittest', 'skip', 'fail'],
      'js_typed_interop_default_arg_test_default_value_multi': ['unittest', 'skip', 'fail']
    },

    'lib/html/custom': {
      'attribute_changed_callback_test': ['unittest', 'skip', 'fail'],
      'constructor_calls_created_synchronously_test':
        ['unittest', 'skip', 'fail'],
      'created_callback_test': ['unittest', 'skip', 'fail'],
      'document_register_basic_test': ['unittest', 'skip', 'fail'],
      'document_register_type_extensions_test': ['unittest', 'skip', 'fail'],
      'element_upgrade_test': ['unittest', 'skip', 'fail'],
      'entered_left_view_test': ['unittest', 'skip', 'fail'],
      'js_custom_test': ['unittest', 'skip', 'fail'],
      'mirrors_test': ['unittest', 'skip', 'fail'],
      'regress_194523002_test': ['unittest', 'skip', 'fail'],
    },

    'lib/math': {
      // TODO(het): triage
      'double_pow_test': skip_fail,
      'low_test': skip_fail,
      'math_test': skip_fail,
      'math2_test': skip_fail,
      'pi_test': skip_timeout,
      'point_test': ['unittest', 'skip', 'fail'],
      'random_big_test': skip_fail,
      'rectangle_test': 'unittest',
    },

    'lib/typed_data': {
      // No bigint or int64 support
      'int32x4_bigint_test': skip_fail,
      'int64_list_load_store_test': skip_fail,
      'typed_data_hierarchy_int64_test': skip_fail,
      'typed_data_list_test': fail,
    },

    'lib/mirrors': {
      'abstract_class_test_none_multi': fail,
      'accessor_cache_overflow_test': fail,
      'array_tracing3_test': fail,
      'array_tracing_test': fail,
      'basic_types_in_dart_core_test': fail,
      'circular_factory_redirection_test_none_multi': fail,
      'class_mirror_location_test': fail,
      'class_mirror_type_variables_test': fail,
      'closurization_equivalence_test': fail,
      'constructor_kinds_test_01_multi': fail,
      'constructor_kinds_test_none_multi': fail,
      'constructor_optional_args_test': fail,
      'constructor_private_name_test': fail,
      'declarations_type_test': fail,
      'deferred_mirrors_metadata_test': skip_timeout,
      'deferred_mirrors_metatarget_test': skip_timeout,
      'deferred_mirrors_update_test': fail,
      'empty_test': fail,
      'equality_test': fail,
      'fake_function_with_call_test': fail,
      'field_type_test': fail,
      'function_apply_mirrors_test': fail,
      'function_type_mirror_test': fail,
      'generic_f_bounded_test_01_multi': fail,
      'generic_f_bounded_test_none_multi': fail,
      'generic_function_typedef_test': fail,
      'generic_interface_test_none_multi': fail,
      'generic_list_test': fail,
      'generic_local_function_test': fail,
      'generic_mixin_applications_test': fail,
      'generic_mixin_test': fail,
      'generic_superclass_test_01_multi': fail,
      'generic_superclass_test_none_multi': fail,
      'generic_type_mirror_test': fail,
      'generics_double_substitution_test_01_multi': fail,
      'generics_double_substitution_test_none_multi': fail,
      'generics_dynamic_test': fail,
      'generics_special_types_test': fail,
      'generics_substitution_test': fail,
      'generics_test_none_multi': fail,
      'get_field_static_test_00_multi': fail,
      'get_field_static_test_none_multi': fail,
      'globalized_closures2_test_00_multi': fail,
      'globalized_closures2_test_none_multi': fail,
      'globalized_closures_test_00_multi': fail,
      'globalized_closures_test_none_multi': fail,
      'hierarchy_invariants_test': fail,
      'hot_get_field_test': fail,
      'hot_set_field_test': fail,
      'inherited_metadata_test': fail,
      'instance_members_unimplemented_interface_test': fail,
      'instantiate_abstract_class_test': fail,
      'intercepted_superclass_test': fail,
      'invocation_fuzz_test_emptyarray_multi': fail,
      'invocation_fuzz_test_false_multi': fail,
      'invocation_fuzz_test_none_multi': fail,
      'invocation_fuzz_test_smi_multi': fail,
      'invocation_fuzz_test_string_multi': fail,
      'invoke_call_on_closure_test': fail,
      'invoke_closurization2_test': fail,
      'invoke_closurization_test': fail,
      'invoke_import_test': fail,
      'invoke_named_test_01_multi': fail,
      'invoke_named_test_none_multi': fail,
      'invoke_natives_malicious_test': fail,
      'invoke_private_test': fail,
      'invoke_private_wrong_library_test': fail,
      'invoke_test': fail,
      'invoke_throws_test': fail,
      'io_html_mutual_exclusion_test': fail,
      'libraries_test': fail,
      'library_enumeration_deferred_loading_test': fail,
      'library_imports_bad_metadata_test_none_multi': fail,
      'library_metadata2_test_none_multi': fail,
      'library_metadata_test': fail,
      'library_uri_package_test': fail,
      'list_constructor_test_01_multi': fail,
      'list_constructor_test_none_multi': fail,
      'local_function_is_static_test': fail,
      'local_isolate_test': fail,
      'metadata_allowed_values_test_none_multi': fail,
      'metadata_scope_test_none_multi': fail,
      'metadata_test': fail,
      'method_mirror_location_test': fail,
      'method_mirror_returntype_test': fail,
      'method_mirror_source_line_ending_test': fail,
      'method_mirror_source_test': fail,
      'mirrors_reader_test': fail,
      'mirrors_resolve_fields_test': fail,
      'mirrors_used_typedef_declaration_test_01_multi': fail,
      'mirrors_used_typedef_declaration_test_none_multi': fail,
      'mixin_test': fail,
      'new_instance_with_type_arguments_test': fail,
      'null2_test': fail,
      'null_test': fail,
      'other_declarations_location_test': fail,
      'parameter_annotation_mirror_test': fail,
      'parameter_is_const_test_none_multi': fail,
      'parameter_metadata_test': fail,
      'private_class_field_test': fail,
      'private_symbol_mangling_test': fail,
      'private_types_test': fail,
      'proxy_type_test': fail,
      'raw_type_test_01_multi': fail,
      'raw_type_test_none_multi': fail,
      'reflect_class_test_none_multi': fail,
      'reflect_runtime_type_test': fail,
      'reflect_uninstantiated_class_test': fail,
      'reflected_type_classes_test_none_multi': fail,
      'reflected_type_function_type_test': fail,
      'reflected_type_special_types_test': fail,
      'reflected_type_test_none_multi': fail,
      'reflected_type_typedefs_test': fail,
      'reflected_type_typevars_test': fail,
      'reflectively_instantiate_uninstantiated_class_test': fail,
      'regress_14304_test': fail,
      'regress_26187_test': fail,
      'relation_assignable_test': fail,
      'relation_subtype_test': fail,
      'runtime_type_test': fail,
      'set_field_with_final_test': fail,
      'static_const_field_test': fail,
      'superclass2_test': fail,
      'symbol_validation_test_01_multi': fail,
      'symbol_validation_test_none_multi': fail,
      'to_string_test': fail,
      'type_argument_is_type_variable_test': fail,
      'type_variable_is_static_test': fail,
      'type_variable_owner_test_01_multi': fail,
      'type_variable_owner_test_none_multi': fail,
      'typedef_deferred_library_test': skip_fail,  // Isolate spawn not support
      'typedef_library_test': fail,
      'typedef_metadata_test': fail,
      'typedef_test': fail,
      'typevariable_mirror_metadata_test': fail,
      'unnamed_library_test': fail,
      'variable_is_const_test_none_multi': fail,
    },
  };

  function countMatches(text, regex) {
    let matches = text.match(regex);
    return matches ? matches.length : 0;
  }
  function libraryName(name) {
    return name.replace(/-/g, '$45');
  }

  let unittest_tests = [];

  let languageTestPattern =
      new RegExp('gen/codegen_output/(.*)/([^/]*_test[^/]*)');
  // We need to let Dart unittest control when tests are run not mocha.
  // mocha.allowUncaught(true);
  for (let testFile of allTestFiles) {
    let match = languageTestPattern.exec(testFile);
    if (match != null) {
      let status_group = match[1];
      let name = match[2];
      let module = match[0];

      let status = all_status[status_group];
      if (status == null) throw "No status for '" + status_group + "'";

      let expectation = status[name];
      if (expectation == null) expectation = [];
      if (typeof expectation == 'string') expectation = [expectation];
      let has = (tag) => expectation.indexOf(tag) >= 0;

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
          require(module)[libraryName(name)].main();
        });
        continue;
      }

      let protect = (f) => {  // Returns the exception, or `null`.
        try {
          f();
          return null;
        } catch (e) {
          return e;
        }
      };

      test(name, function(done) { // 'function' to allow `this.timeout`.
        async_helper.asyncTestInitialize(done);
        console.debug('Running test:  ' + name);

        let mainLibrary = require(module)[libraryName(name)];
        let negative = /negative_test/.test(name);
        if (has('slow')) this.timeout(10000);
        if (has('fail')) {
          let e = protect(mainLibrary.main);
          if (negative) {
            if (e != null) {
              throw new Error(
                  "negative test marked as 'fail' " +
                  "but passed by throwing:\n" + e);
            }
          } else {
            if (e == null) {
              throw new Error("test marked as 'fail' but passed");
            }
          }
        } else {
          if (negative) {
            assert.throws(mainLibrary.main);
          } else {
            mainLibrary.main();
          }
        }

        if (!async_helper.asyncTestStarted) done();
      });
    }
  }

  let mochaOnError;
  // We run these tests in a mocha test wrapper to avoid the confusing failure
  // case of dart unittests being interleaved with mocha tests.
  // In practice we are really just suppressing all mocha test behavior while
  // Dart unittests run and then re-enabling it when the dart tests complete.
  html_config.useHtmlConfiguration();
  test('run all dart unittests', function(done) { // 'function' to allow `this.timeout`
    if (unittest_tests.length == 0) return done();

    // TODO(vsm): We're using an old deprecated version of unittest.
    // We need to migrate all tests (in the SDK itself) off of
    // unittest.

    // All unittests need to be explicitly marked as such above.  If
    // not, the unittest framework will be run in a 'normal' test and
    // left in an inconsistent state at this point triggering spurious
    // failures.  This check ensures we're not in such a state.  If it fails,
    // we've likely added a new unittest and need to categorize it as such.
    if (unittest.src__test_environment.environment.testCases[dart_sdk.dartx.length] != 0) {
      return done(new Error('Unittest framework in an invalid state'));
    }

    this.timeout(100000000);
    this.enableTimeouts(false);
    // Suppress mocha on-error handling because it will mess up unittests.
    mochaOnError = window.onerror;
    window.onerror = function(err, url, line) {
      console.error(err, url, line);
    };
    window.addEventListener('message', (event) => {
      if (event.data == 'unittest-suite-done') {
        window.console.log("Done running unittests");
        let output = document.body.textContent;
        // Restore the Mocha onerror handler in case future tests need to run.
        window.onerror = mochaOnError;
        this.enableTimeouts(true);

        let numErrors = countMatches(output, /\d\s+ERROR/g);
        let numFails = countMatches(output, /\d\s+FAIL/g);
        if (numErrors != num_expected_unittest_errors ||
            numFails != num_expected_unittest_fails) {
          output = "Expected " + num_expected_unittest_fails +
              " fail and " + num_expected_unittest_errors +
              " error unittests, got " + numFails + " fail and " +
              numErrors + "error tests.\n" + output;
          console.error(output);
          done(new Error(output));
        } else {
          console.log(output);
          done();
        }
      }
    });

    for (let action of unittest_tests) {
      try {
        action();
      } catch (e) {
        console.error("Caught error tying to setup test:", e);
      }
    }
  });
});
