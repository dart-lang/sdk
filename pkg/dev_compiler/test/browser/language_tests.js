// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(function() {
  'use strict';

  let _isolate_helper = dart_library.import('dart/_isolate_helper');
  _isolate_helper.startRootIsolate(function() {}, []);
  let async_helper = dart_library.import('async_helper/async_helper');

  function dartLanguageTest(name) {
    test(name, (done) => {
      async_helper.asyncTestInitialize(done);
      console.debug('Running language test:  ' + name);
      dart_library.import('language/' + name).main();
      if (!async_helper.asyncTestStarted) done();
    });
  }

  function dartLanguageTests(tests) {
    for (let name of tests) {
      if (name instanceof Array) {
        let multitestName = name[0];
        let testCases = name.slice(1);
        for (let testCase of testCases) {
          if (typeof testCase == 'number') {
            testCase = (testCase < 10 ? '0' : '') + testCase;
          }
          dartLanguageTest(`${multitestName}_${testCase}_multi`);
        }
      } else {
        dartLanguageTest(name);
      }
    }
  }

  suite('cascade', () => {
    dartLanguageTests(['cascade_in_expression_function_test']);
  });

  suite('null aware ops', () => {
    dartLanguageTests([
      ['conditional_method_invocation_test', 'none', 1, 2, 3, 4],
      ['conditional_property_access_test', 'none', 1, 2, 3],
      ['conditional_property_assignment_test', 'none', 1, 2, 3, 7, 8, 9],
      ['conditional_property_increment_decrement_test',
          'none', 1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15],
      ['if_null_assignment_behavior_test', 'none',
          1, 2, 5, 6, 7, 8, 9, 10, 11, 12, 16, 17, 18, 19, 20, 21, 22, 23, 24,
          25, 26, 27, 28, 31, 32],
      ['if_null_assignment_static_test', 'none',
          1, 3, 5, 8, 10, 12, 15, 17, 19, 22, 24, 26, 29, 31, 33, 36, 38, 40],
      'nullaware_opt_test',
      ['super_conditional_operator_test', 'none'],
      ['this_conditional_operator_test', 'none']
    ]);
  });

  suite('sync*', () => {
    test('syncstar_syntax', () => {
      dart_library.import('syncstar_syntax').main();
    });

    dartLanguageTests([
      'syncstar_yield_test',
      'syncstar_yieldstar_test'
    ]);
  });

  dart_library.import('language/async_await_test').main();

  suite('async', () => {
    dartLanguageTests([
      'async_and_or_test',
      'async_await_catch_regression_test',
      'async_backwards_compatibility_1_test',
      'async_backwards_compatibility_2_test',
      'async_break_in_finally_test',
      // TODO(jmesserly): https://github.com/dart-lang/dev_compiler/issues/263
      // 'async_continue_label_test',
      'async_control_structures_test',
      'async_finally_rethrow_test',
      'async_regression_23058_test',
      'async_rethrow_test',
      // TODO(jmesserly): https://github.com/dart-lang/dev_compiler/issues/294
      // 'async_switch_test',
      'async_test',
      'async_this_bound_test',
      'async_throw_in_catch_test'
      // By design, rejected statically by strong mode:
      // 'async_return_types_test',
      // 'async_or_generator_return_type_stacktrace_test',
    ]);
  });

  dart_library.import('language/async_star_test_none_multi').main();

  suite('async*', () => {
    dartLanguageTests([
      // TODO(jmesserly): figure out why this test is hanging.
      //'async_star_cancel_and_throw_in_finally_test',
      'async_star_regression_23116_test',
      'asyncstar_concat_test',
      // TODO(jmesserly): https://github.com/dart-lang/dev_compiler/issues/294
      // 'asyncstar_throw_in_catch_test',
      'asyncstar_yield_test',
      'asyncstar_yieldstar_test'
    ]);
  });

  suite('export', () => {
    dartLanguageTests([
      'duplicate_export_test',
      'export_cyclic_test',
      'export_double_same_main_test',
      'export_main_override_test',
      'export_main_test',
      'export_test',
      'local_export_test',
      'reexport_core_test',
      'top_level_entry_test'
    ]);
  });

})();
