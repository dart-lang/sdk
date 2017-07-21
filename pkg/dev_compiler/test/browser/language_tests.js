// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

define(['dart_sdk', 'async_helper', 'expect', 'unittest', 'is', 'require'],
      function(dart_sdk, async_helper, expect, unittest, is, require) {
  'use strict';

  async_helper = async_helper.async_helper;
  let minitest = expect.minitest;
  let mochaOnError = window.onerror;
  dart_sdk.dart.trapRuntimeErrors(false);
  dart_sdk.dart.ignoreWhitelistedErrors(false);
  dart_sdk.dart.failForWeakModeIsChecks(false);
  dart_sdk._isolate_helper.startRootIsolate(function() {}, []);
  // Make it easier to debug test failures and required for formatter test that
  // assumes custom formatters are enabled.
  dart_sdk._debugger.registerDevtoolsFormatter();

  let html_config = unittest.html_config;
  // Test attributes are a list of strings, or a string for a single
  // attribute. Valid attributes are:
  //
  //   'pass' - test passes (default)
  //   'skip' - don't run the test
  //   'fail' - test fails
  //   'timeout' - test times out
  //   'slow' - use 5s timeout instead of default 2s.
  //   'helper'  - not a test, used by other tests.
  //   'unittest' - run separately as a unittest test.
  //   'whitelist' - run with whitelisted type errors allowed
  //
  // Common combinations:
  const pass = 'pass';
  const fail = 'fail';
  const skip_timeout = ['skip', 'timeout'];

  // Browsers
  const firefox_fail = is.firefox() ? fail : pass;
  const chrome_fail = is.chrome() ? fail : pass;

  // These are typically tests with asynchronous exceptions that our
  // test framework doesn't always catch.
  const flaky = 'skip';
  const whitelist = 'whitelist';

  // Tests marked with this are still using the deprecated unittest package
  // because they rely on its support for futures and asynchronous tests, which
  // expect and minitest do not handle.
  // TODO(rnystrom): Move all of these away from using the async test API so
  // they can stop using unittest.
  const async_unittest = ['unittest', 'skip', 'fail'];

  // The number of expected unittest errors should be zero but unfortunately
  // there are a lot of broken html unittests.
  let num_expected_unittest_fails = 4;
  let num_expected_unittest_errors = 0;

  // TODO(jmesserly): separate StrongModeError from other errors.
  let all_status = {
    'language': {
      'async_await_test_none_multi': 'unittest',
      'async_await_test_02_multi': 'unittest',

      // Flaky on travis (https://github.com/dart-lang/sdk/issues/27224)
      'async_await_test_03_multi': async_unittest,

      'async_star_await_pauses_test': skip_timeout,

      // TODO(jmesserly): figure out why this test is hanging.
      'async_star_cancel_and_throw_in_finally_test': skip_timeout,

      'async_star_cancel_while_paused_test': fail,

      // TODO(vsm): Re-enable (https://github.com/dart-lang/sdk/issues/28319)
      'async_star_test_none_multi': async_unittest,
      'async_star_test_01_multi': async_unittest,
      'async_star_test_02_multi': async_unittest,
      'async_star_test_03_multi': async_unittest,
      'async_star_test_04_multi': async_unittest,
      'async_star_test_05_multi': async_unittest,

      'async_switch_test': fail,
      'async_test': whitelist,
      'async_this_bound_test': whitelist,
      'asyncstar_throw_in_catch_test': ['skip', 'fail'],
      'await_future_test': skip_timeout,
      'bit_operations_test_none_multi': fail,  // DDC/dart2js canonicalize bitop results to unsigned
      'branch_canonicalization_test': fail,  // JS bit operations truncate to 32 bits.
      'call_closurization_test': fail, // Functions do not expose a "call" method.
      'call_with_no_such_method_test': fail, // Function.apply not really implemented.
      'canonical_const2_test': fail,
      'canonical_const_test': fail,
      'compile_time_constant10_test_none_multi': fail,
      'compile_time_constant_a_test': fail,
      'compile_time_constant_b_test': fail,
      'compile_time_constant_d_test': fail,
      'compile_time_constant_k_test_none_multi': fail,
      'compile_time_constant_o_test_none_multi': fail,
      'const_evaluation_test_01_multi': fail,
      'const_switch_test_02_multi': fail,
      'const_switch_test_04_multi': fail,
      'constructor12_test': fail,
      'custom_await_stack_trace_test': fail,
      'cyclic_type2_test': fail,
      'cyclic_type_test_00_multi': fail,
      'cyclic_type_test_01_multi': fail,
      'cyclic_type_test_02_multi': fail,
      'cyclic_type_test_03_multi': fail,
      'cyclic_type_test_04_multi': fail,

      // Deferred libraries are not actually deferred. These tests all test
      // that synchronous access to the library fails.
      'deferred_call_empty_before_load_test': fail,
      'deferred_load_library_wrong_args_test_01_multi': fail,
      'deferred_not_loaded_check_test': fail,
      'deferred_redirecting_factory_test': fail,
      'deferred_static_seperate_test': fail,

      'double_int_to_string_test': fail,
      'dynamic_test': fail,
      'exception_test': fail,
      'execute_finally6_test': fail,
      'expect_test': fail,
      'extends_test_lib': fail,
      'f_bounded_quantification3_test': fail,
      'field_increment_bailout_test': fail,
      'field_optimization3_test': fail,
      'first_class_types_test': fail,
      'flatten_test_01_multi': fail,
      'flatten_test_04_multi': fail,
      'flatten_test_05_multi': fail,
      'flatten_test_08_multi': fail,
      'flatten_test_09_multi': fail,
      'flatten_test_12_multi': fail,
      'for_variable_capture_test': is.firefox('<=50') ? pass : fail,
      'function_subtype_named1_test': fail,
      'function_subtype_named2_test': fail,
      'function_subtype_optional1_test': fail,
      'function_subtype_optional2_test': fail,
      'function_subtype_typearg2_test': fail,
      'function_subtype_typearg4_test': fail,
      'function_type_alias3_test': fail,
      'function_type_alias6_test_none_multi': fail,
      'generic_instanceof_test': fail, // runtime strong mode reject
      'generic_instanceof2_test': fail,
      'generic_is_check_test': fail,
      'generic_methods_generic_class_tearoff_test': fail,
      'getter_closure_execution_order_test': fail,
      'gc_test': 'slow',
      'identical_closure2_test': fail,
      'infinite_switch_label_test': fail,
      'infinity_test': fail,
      'initializing_formal_final_test': fail,
      'instance_creation_in_function_annotation_test': fail,
      'instanceof2_test': fail,
      'instanceof4_test_01_multi': fail,
      'instanceof4_test_none_multi': fail,
      'integer_division_by_zero_test': fail,
      'issue23244_test': fail,
      'lazy_static3_test': fail,
      'least_upper_bound_expansive_test_none_multi': fail,
      'left_shift_test': fail,
      'list_is_test': fail,
      'list_literal3_test': fail,
      'main_test_03_multi': fail,
      'many_generic_instanceof_test': fail,
      'many_named_arguments_test': whitelist,
      'map_literal10_test': fail,
      'map_literal7_test': fail,
      'memory_swap_test': skip_timeout,
      'mint_arithmetic_test': fail,
      'modulo_test': fail,
      'named_parameter_clash_test': fail,
      'named_parameters_passing_falsy_test': is.firefox('<=50') ? fail : pass,
      'nan_identical_test': fail,
      'nested_switch_label_test': fail,
      'number_identifier_test_05_multi': fail,
      'number_identity2_test': fail,
      'numbers_test': fail,
      'reg_exp_test': whitelist,
      'regress_16640_test': fail,
      'regress_22445_test': fail,
      'regress_22666_test': fail,
      'regress_22777_test': flaky,
      'stack_overflow_stacktrace_test': fail,
      'stack_overflow_test': fail,
      'stacktrace_test': chrome_fail,
      'switch_label2_test': fail,
      'switch_label_test': fail,
      'switch_try_catch_test': fail,
      'throwing_lazy_variable_test': fail,
      'truncdiv_test': fail,  // did not throw
      'try_catch_on_syntax_test_10_multi': fail,
      'try_catch_on_syntax_test_11_multi': fail,
      'type_variable_nested_test': fail,

      'bit_operations_test_01_multi': fail,
      'bit_operations_test_02_multi': fail,
      'bit_operations_test_03_multi': fail,
      'bit_operations_test_04_multi': fail,
      'deferred_load_constants_test_none_multi': fail,
      'external_test_21_multi': fail,
      'external_test_24_multi': fail,
      'multiline_newline_test_04_multi': fail,
      'multiline_newline_test_05_multi': fail,
      'multiline_newline_test_06_multi': fail,
      'multiline_newline_test_none_multi': fail,

      // https://github.com/dart-lang/sdk/issues/26124
      'prefix10_negative_test': fail,

      'library_prefixes_test1': 'helper',
      'library_prefixes_test2': 'helper',
      'top_level_prefixed_library_test': 'helper',

    },

    'language/covariant_override': {},

    'codegen': {},

    'corelib': {
      'apply2_test': fail,
      'apply3_test': fail,
      'big_integer_arith_vm_test_add_multi': fail,
      'big_integer_arith_vm_test_div_multi': fail,
      'big_integer_arith_vm_test_gcd_multi': fail,
      'big_integer_arith_vm_test_modInv_multi': fail,
      'big_integer_arith_vm_test_modPow_multi': fail,
      'big_integer_arith_vm_test_mod_multi': fail,
      'big_integer_arith_vm_test_mul_multi': fail,
      'big_integer_arith_vm_test_negate_multi': fail,
      'big_integer_arith_vm_test_none_multi': fail,
      'big_integer_arith_vm_test_overflow_multi': fail,
      'big_integer_arith_vm_test_shift_multi': fail,
      'big_integer_arith_vm_test_sub_multi': fail,
      'big_integer_arith_vm_test_trunDiv_multi': fail,
      'big_integer_parsed_arith_vm_test': fail,
      'big_integer_parsed_div_rem_vm_test': fail,
      'big_integer_parsed_mul_div_vm_test': fail,

      'bit_twiddling_bigint_test': fail,
      'collection_length_test': skip_timeout,
      'compare_to2_test': fail,
      'const_list_literal_test': fail,
      'const_list_remove_range_test': fail,
      'const_list_set_range_test': fail,
      'data_uri_test': fail,
      'double_parse_test_01_multi': fail,
      'double_parse_test_02_multi': firefox_fail,
      'for_in_test': is.firefox('<=50') ? fail : pass,
      'growable_list_test': fail,
      'hash_map2_test': skip_timeout,
      'hash_set_test_01_multi': fail,
      'int_modulo_arith_test_bignum_multi': fail,
      'int_modulo_arith_test_modPow_multi': fail,
      'int_modulo_arith_test_none_multi': fail,
      'int_parse_radix_test_01_multi': fail, // JS implementations disagree on U+0085 being whitespace.
      'int_parse_radix_test_02_multi': ['fail', 'timeout', 'skip'], // No bigints.
      'int_parse_radix_test_none_multi': ['slow'],
      'integer_to_radix_string_test': fail,
      'integer_to_string_test_01_multi': fail,
      'iterable_empty_test': whitelist,
      'iterable_join_test': whitelist,
      'iterable_return_type_test_02_multi': fail,
      'json_map_test': fail,
      'list_fill_range_test': fail,
      'list_insert_all_test': whitelist,
      'list_replace_range_test': fail,
      'list_set_all_test': fail,
      'list_test_01_multi': fail,
      'list_test_none_multi': fail,
      'main_test': fail,
      'map_keys2_test': fail,
      'map_from_iterable_test': is.firefox('<=50') ? fail : pass,
      'nan_infinity_test_01_multi': fail,
      'null_nosuchmethod_test': fail,
      'reg_exp_all_matches_test': whitelist,
      'reg_exp_start_end_test': whitelist,
      'regress_r21715_test': fail,
      'sort_test': whitelist,
      'splay_tree_from_iterable_test': is.firefox('<=50') ? fail : pass,
      'string_case_test_01_multi': firefox_fail,
      'string_fromcharcodes_test': skip_timeout,
      'string_operations_with_null_test': fail,
      'string_split_test': whitelist,
      'string_trimlr_test_01_multi': is.chrome('<=58') ? fail : pass,
      'string_trimlr_test_none_multi': is.chrome('<=58') ? fail : pass,
      'symbol_reserved_word_test_06_multi': fail,
      'symbol_reserved_word_test_09_multi': fail,
      'symbol_reserved_word_test_12_multi': fail,
      'unicode_test': firefox_fail,
      'uri_parameters_all_test': is.firefox('<=50') ? fail : pass,
      // TODO(rnystrom): Times out because it tests a huge number of
      // combinations of URLs (4 * 5 * 5 * 8 * 6 * 6 * 4 = 115200).
      'uri_parse_test': skip_timeout,
      'uri_query_test': fail,
      // this is timing out on Chrome Canary only
      // pinning this skip in case it's a transient canary issue
      'uri_test': is.chrome('59') ? ['skip'] : ['slow'],

      'list_insert_test': fail,
      'list_removeat_test': fail,
    },

    'corelib/regexp': {
      'default_arguments_test': fail,
      'UC16_test': firefox_fail,
    },

    'lib/async': {
      'first_regression_test': async_unittest,
      'future_or_bad_type_test_implements_multi': fail,
      'future_or_bad_type_test_none_multi': fail,
      'future_or_non_strong_test': fail,
      'future_timeout_test': async_unittest,
      'multiple_timer_test': async_unittest,
      'futures_test': fail,
      'schedule_microtask2_test': async_unittest,
      'schedule_microtask3_test': async_unittest,
      'schedule_microtask5_test': async_unittest,
      'stream_controller_async_test': async_unittest,
      'stream_first_where_test': async_unittest,
      'stream_from_iterable_test': async_unittest,
      'stream_iterator_test': async_unittest,
      'stream_join_test': async_unittest,
      'stream_last_where_test': async_unittest,
      'stream_periodic2_test': async_unittest,
      'stream_periodic3_test': async_unittest,
      'stream_periodic4_test': async_unittest,
      'stream_periodic5_test': async_unittest,
      'stream_periodic6_test': async_unittest,
      'stream_periodic_test': async_unittest,
      'stream_single_test': async_unittest,
      'stream_single_to_multi_subscriber_test': async_unittest,
      'stream_state_helper': async_unittest,
      'stream_state_nonzero_timer_test': async_unittest,
      'stream_state_test': async_unittest,
      'stream_subscription_as_future_test': async_unittest,
      'stream_subscription_cancel_test': async_unittest,
      'stream_timeout_test': async_unittest,
      'stream_transform_test': async_unittest,
      'stream_transformation_broadcast_test': async_unittest,
      'stream_transformer_from_handlers_test': fail,
      'timer_cancel1_test': async_unittest,
      'timer_cancel2_test': async_unittest,
      'timer_cancel_test': async_unittest,
      'timer_isActive_test': async_unittest,
      'timer_not_available_test': fail,
      'timer_repeat_test': async_unittest,
      'timer_test': async_unittest,
      'zone_bind_callback_test': fail,
      'zone_error_callback_test': fail,
      'zone_register_callback_test': fail,
      'zone_run_unary_test': fail,
    },

    'lib/collection': {
      'linked_list_test': whitelist,
    },

    'lib/convert': {
      'base64_test_01_multi': 'slow',
      'chunked_conversion_utf82_test': whitelist,
      'chunked_conversion_utf83_test': whitelist,
      'chunked_conversion_utf85_test': ['whitelist', 'slow'],
      'chunked_conversion_utf86_test': whitelist,
      'chunked_conversion_utf87_test': whitelist,

      'encoding_test': skip_timeout,

      'json_utf8_chunk_test': skip_timeout,
      'latin1_test': skip_timeout,

      'streamed_conversion_json_decode1_test': whitelist,
      'streamed_conversion_json_encode1_test': skip_timeout,
      'streamed_conversion_json_utf8_decode_test': skip_timeout,
      'streamed_conversion_json_utf8_encode_test': skip_timeout,
      'streamed_conversion_utf8_decode_test': skip_timeout,
      'streamed_conversion_utf8_encode_test': skip_timeout,
      'utf82_test': whitelist,
      'utf85_test': skip_timeout,
      'utf8_encode_test': whitelist,
      'utf8_test': whitelist,
    },

    'lib/html': {
      'async_spawnuri_test': async_unittest,
      'async_test': async_unittest,

       // was https://github.com/dart-lang/sdk/issues/27578, needs triage
      'audiocontext_test': is.chrome('<=54') ? fail : pass,

      'canvas_test': ['unittest'],
      'canvasrenderingcontext2d_test': ['unittest'],
      'cross_domain_iframe_test': async_unittest,
      'cssstyledeclaration_test': async_unittest,
      'css_test': async_unittest,

      // This is failing with a range error, I'm guessing because it's looking
      // for a stylesheet and the page has none.
      'css_rule_list_test': 'fail',

      'custom_element_method_clash_test': async_unittest,
      'custom_element_name_clash_test': async_unittest,
      'custom_elements_23127_test': async_unittest,
      'custom_elements_test': async_unittest,

      // Please do not mark this test as fail. If your change breaks this test,
      // please look at the test for instructions on how to generate a new
      // golden file.
      'debugger_test': firefox_fail,
      'element_animate_test': 'unittest',

      // https://github.com/dart-lang/sdk/issues/27579.
      'element_classes_test': 'fail',
      'element_classes_svg_test': 'fail',

      // Failure: 'Expected 56 to be in the inclusive range [111, 160].'.
      'element_offset_test': 'fail',

      'element_test': async_unittest,
      // This may no longer be a valid test?
      'element_types_test': is.chrome('<=56') ? pass : fail,
      'event_customevent_test': async_unittest,
      'events_test': async_unittest,
      'fileapi_test': async_unittest,
      'filereader_test': async_unittest,
      'fontface_loaded_test': async_unittest,
      'fontface_test': firefox_fail,
      'form_data_test': async_unittest,
      'history_test': async_unittest,
      'indexeddb_1_test': async_unittest,
      'indexeddb_2_test': async_unittest,
      'indexeddb_3_test': async_unittest,
      'indexeddb_4_test': async_unittest,
      'indexeddb_5_test': async_unittest,

      // was https://github.com/dart-lang/sdk/issues/27578, needs triage
      'input_element_test': 'fail',

      'interactive_test': async_unittest,
      'isolates_test': async_unittest,

      'js_interop_1_test': async_unittest,

      // The "typed literal" test fails because the object does not have "_c".
      'js_util_test': 'fail',
      'keyboard_event_test': async_unittest,

      // was https://github.com/dart-lang/sdk/issues/27578, needs triage
      'mediasource_test': 'fail',
      'media_stream_test': 'fail',

      // https://github.com/dart-lang/sdk/issues/29071
      'messageevent_test': firefox_fail,

      'mutationobserver_test': async_unittest,
      'native_gc_test': async_unittest,
      'postmessage_structured_test': async_unittest,

      // this is timing out on Chrome Canary only
      // pinning this skip in case it's a transient canary issue
      'queryall_test': is.chrome('59') ? ['skip'] : ['slow'], // see sdk #27794

      'request_animation_frame_test': async_unittest,
      'resource_http_test': async_unittest,

      // was https://github.com/dart-lang/sdk/issues/27578, needs triage
      'rtc_test': is.chrome('<=55') ? fail : pass,

      // https://github.com/dart-lang/sdk/issues/29071
      'serialized_script_value_test': firefox_fail,

      'shadow_dom_test': firefox_fail,

      // was https://github.com/dart-lang/sdk/issues/27578, needs triage
      'speechrecognition_test': firefox_fail,
      'text_event_test': firefox_fail,

      // was https://github.com/dart-lang/sdk/issues/27578, needs triage
      'touchevent_test': 'fail',

      'transferables_test': async_unittest,
      'transition_event_test': async_unittest,
      'url_test': async_unittest,
      'websocket_test': async_unittest,
      'websql_test': async_unittest,
      'wheelevent_test': async_unittest,
      'worker_api_test': async_unittest,
      'worker_test': async_unittest,

      'xhr_cross_origin_test': async_unittest,
      'xhr_test': async_unittest,

      // Failing when it gets 3 instead of 42.
      'js_typed_interop_default_arg_test_default_value_multi': 'fail',
    },

    'lib/html/custom': {
      'attribute_changed_callback_test': async_unittest,
      'constructor_calls_created_synchronously_test': async_unittest,
      'created_callback_test': async_unittest,
      'entered_left_view_test': async_unittest,
      'js_custom_test': async_unittest,
      'mirrors_test': async_unittest,
      'regress_194523002_test': async_unittest,
    },

    'lib/math': {
      // TODO(het): triage
      'double_pow_test': fail,
      'low_test': fail,
      'pi_test': skip_timeout,
      'random_big_test': fail,
    },

    'lib/typed_data': {
      // No bigint or int64 support
      'int32x4_bigint_test': fail,
      'int64_list_load_store_test': fail,
      'typed_data_hierarchy_int64_test': fail,
      'typed_data_list_test': fail,
      'typed_list_iterable_test': whitelist,
    },

    'lib/mirrors': {
      'abstract_class_test_none_multi': fail,
      'accessor_cache_overflow_test': fail,
      'basic_types_in_dart_core_test': fail,
      'class_mirror_location_test': fail,
      'class_mirror_type_variables_test': fail,
      'closurization_equivalence_test': fail,
      'constructor_kinds_test_01_multi': fail,
      'constructor_kinds_test_none_multi': fail,
      'constructor_private_name_test': fail,
      'declarations_type_test': fail,
      'deferred_mirrors_metadata_test': skip_timeout,
      'deferred_mirrors_metatarget_test': skip_timeout,
      'deferred_mirrors_update_test': fail,
      'empty_test': fail,
      'equality_test': fail,
      'fake_function_with_call_test': fail,
      'field_type_test': fail,
      'function_type_mirror_test': fail,
      'generic_f_bounded_test_01_multi': fail,
      'generic_f_bounded_test_none_multi': fail,
      'generic_function_typedef_test': fail,
      'generic_interface_test_none_multi': fail,
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
      'globalized_closures2_test_00_multi': fail,
      'globalized_closures2_test_none_multi': fail,
      'globalized_closures_test_00_multi': fail,
      'globalized_closures_test_none_multi': fail,
      'hot_get_field_test': fail,
      'hot_set_field_test': fail,
      'inherited_metadata_test': fail,
      'instance_members_unimplemented_interface_test': fail,
      'instance_members_with_override_test': fail, // JsClassMirror.instanceMembers unimplemented
      'instantiate_abstract_class_test': fail,
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
      'libraries_test': fail,
      'library_imports_bad_metadata_test_none_multi': fail,
      'library_metadata_test': fail,
      'library_uri_io_test': async_unittest,
      'library_uri_package_test': async_unittest,
      'list_constructor_test_01_multi': fail,
      'list_constructor_test_none_multi': fail,
      'load_library_test': fail,
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
      'mirrors_used_typedef_declaration_test_01_multi': fail,
      'mirrors_used_typedef_declaration_test_none_multi': fail,
      'mixin_test': fail,
      'null2_test': fail,
      'null_test': fail,
      'other_declarations_location_test': fail,
      'parameter_annotation_mirror_test': fail,
      'parameter_is_const_test_none_multi': fail,
      'parameter_metadata_test': fail,
      'private_class_field_test': fail,
      'private_symbol_mangling_test': fail,
      'private_types_test': fail,
      'reflect_class_test_none_multi': fail,
      'reflect_runtime_type_test': fail,
      'reflect_uninstantiated_class_test': fail,
      'reflected_type_classes_test_none_multi': fail,
      'reflected_type_function_type_test': fail,
      'reflected_type_special_types_test': fail,
      'reflected_type_test_none_multi': fail,
      'reflected_type_typedefs_test': fail,
      'reflected_type_typevars_test': fail,
      'regress_14304_test': fail,
      'regress_26187_test': fail,
      'relation_assignable_test': fail,
      'relation_subtype_test': fail,
      'set_field_with_final_test': fail,
      'set_field_with_final_inheritance_test': fail,
      'symbol_validation_test_01_multi': fail,
      'symbol_validation_test_none_multi': fail,
      'to_string_test': fail,
      'type_argument_is_type_variable_test': fail,
      'type_variable_is_static_test': fail,
      'type_variable_owner_test_01_multi': fail,
      'type_variable_owner_test_none_multi': fail,
      'typedef_deferred_library_test': fail,  // Isolate spawn not support
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
  let unittestAccidentallyInitialized = false;

  // Pattern for selecting out generated test files in sub-directories
  // of the codegen directory.  These are the language, corelib, etc
  // tests
  let languageTestPattern =
      new RegExp('gen/codegen_output/(.*)/([^/]*_test[^/]*)');
  // Pattern for selecting out generated test files in the toplevel
  // codegen directory.  These are codegen tests that should be
  // executed.
  let codegenTestPattern =
      new RegExp('gen/codegen_output/([^/]*_test[^/]*)');
  // We need to let Dart unittest control when tests are run not mocha.
  // mocha.allowUncaught(true);
  for (let testFile of allTestFiles) {
    let status_group;
    let name;
    let module;
    let match = languageTestPattern.exec(testFile);
    if (match != null) {
      status_group = match[1];
      name = match[2];
      module = match[0];
    } else if ((match = codegenTestPattern.exec(testFile)) != null) {
      status_group = 'codegen';
      name = match[1];
      module = match[0];
    }
    if (match != null) {
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
          return f();
        } catch (e) {
          return e;
        }
      };

      var fullName = status_group + '/' + name;
      test(fullName, function(done) { // 'function' to allow `this.timeout`.
        console.debug('Running test:  ' + fullName);

        // Many tests are async.  Currently, tests can indicate this in
        // two different ways.  First, `main` can call (in Dart)
        // `async_helper.asyncStart`.  We can check if this happened by
        // querying `async_helper.asyncTestStarted` afterward and waiting for
        // the callback if so.  Second, `main` can return a `Future`.  If so,
        // we wait for that to complete.  If neither is true, we assume the
        // test is synchronous.
        //
        // A 'failing' test will throw an exception.  This exception may be
        // synchronous (i.e., during `main`) or asynchronous (after `main` in
        // lieu of the callback/future).  The latter exceptions are not
        // directly caught.  Instead, we intercept `window.onerror` to detect
        // them.
        //
        // Note, if the test is marked 'negative' or 'fail', than pass and fail
        // are effectively inverted: only a success is reported.
        //
        // In all cases, we funnel test completion through the `finish` handler
        // below to handle reporting (based on status) and cleanup state.
        //
        // A test can finish in one of several ways:
        // 1. Synchronous without an error.  In this case, `main` returns
        //    null and did not set `async_helper`.  `finish` is invoked
        //    immediately.
        // 2. Synchronous error.  `main` throws an error.  `finish`
        //    is invoked immediately with the error.
        // 3. `Future` without an error.  In this case, the future completes
        //    and asynchronously invokes `finish`.
        // 4. Via `async_helper` without an error.  In this case, the
        //    `async_helper` library triggers `finish` via its callback.
        // 5. Asynchronously with an error.  In this case, `window.onerror`
        //    triggers `finish` with the error.
        // 6. Hangs.  In this case, we rely on the underlying mocha framework
        //    timeout.
        //
        // TODO(vsm): This currently doesn't handle tests that trigger multiple
        // asynchronous exceptions.

        let mainLibrary = require(module)[libraryName(name)];
        let negative = /negative_test/.test(name) ||
            mainLibrary._expectRuntimeError;
        let fail = has('fail');

        let whitelist = has('whitelist');
        dart_sdk.dart.ignoreWhitelistedErrors(whitelist);

        function finish(error) {
          // If the test left any lingering detritus in the DOM, blow it away
          // so it doesn't interfere with later tests.
          if (fail) {
            if (negative) {
              if (error) {
                error = new Error(
                  "negative test marked as 'fail' " +
                  "but passed by throwing:\n" + error);
              }
            } else if (error) {
              error = null
            } else {
              error = new Error("test marked as 'fail' but passed");
            }
          } else if (negative) {
            if (!error) {
              error = new Error("test marked as 'negative' but did not throw");
            } else {
              error = null;
            }
          }
          minitest.finishTests();
          document.body.innerHTML = '';
          console.log("cleared");
          if (error && !(error instanceof Error)) error = new Error(error);
          dart_sdk.dart.ignoreWhitelistedErrors(false);
          done(error);
        }

        // Intercept uncaught exceptions
        window.onerror = function(message, url, line, column, error) {
          console.warn('Asynchronous error in ' + name + ': ' + message);
          if (!error) {
            error = new Error(message);
          }
          finish(error);
        };

        async_helper.asyncTestInitialize(finish);
        if (has('slow')) this.timeout(10000);

        var result;
        try {
          var result = mainLibrary.main();
          if (result && !(dart_sdk.async.Future.is(result))) {
            result = null;
          }
        } catch (e) {
          finish(e);
        }

        // Ensure this isn't a unittest
        if (!unittestAccidentallyInitialized &&
            unittest.src__test_environment.environment.initialized) {
          // This suppresses duplicate messages for later tests
          unittestAccidentallyInitialized = true;
          finish(new Error('Test ' + name + ' must be marked as a unittest'));
        } else if (!async_helper.asyncTestStarted) {
          if (!result) {
            finish();
          } else {
            result.then(dart_sdk.dart.dynamic)(() => finish(),
              { onError: (e) => finish(e) });
          }
        }
      });
    }
  }

  // We run these tests in a mocha test wrapper to avoid the confusing failure
  // case of dart unittests being interleaved with mocha tests.
  // In practice we are really just suppressing all mocha test behavior while
  // Dart unittests run and then re-enabling it when the dart tests complete.
  html_config.useHtmlConfiguration();
  test('run all dart unittests', function(done) { // 'function' to allow `this.timeout`
    // Use the whitelist for all unittests - there may be an error in the framework
    // itself.
    dart_sdk.dart.ignoreWhitelistedErrors(true);
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
        dart_sdk.dart.ignoreWhitelistedErrors(false);

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
