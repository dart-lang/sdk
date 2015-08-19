// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(function() {
  'use strict';

  let _isolate_helper = dart_library.import('dart/_isolate_helper');
  _isolate_helper.startRootIsolate(function() {}, []);

  let async_helper = dart_library.import('async_helper/async_helper');

  function dartLanguageTests(tests) {
    for (const name of tests) {
      test(name, (done) => {
        async_helper.asyncTestInitialize(done);
        console.debug('Running language test:  ' + name);
        dart_library.import('language/' + name).main();
        if (!async_helper.asyncTestStarted) done();
      });
    }
  }

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
      // TODO(jmesserly): fix errors
      // 'async_backwards_compatibility_1_test',
      'async_backwards_compatibility_2_test',
      'async_break_in_finally_test',
      // TODO(jmesserly): https://github.com/dart-lang/dev_compiler/issues/263
      // 'async_continue_label_test',
      'async_control_structures_test',
      'async_finally_rethrow_test',
      // TODO(jmesserly): fix errors
      // 'async_or_generator_return_type_stacktrace_test',
      'async_regression_23058_test',
      'async_rethrow_test',
      // TODO(jmesserly): fix errors
      // 'async_return_types_test',
      // TODO(jmesserly): https://github.com/dart-lang/dev_compiler/issues/294
      // 'async_switch_test',
      'async_test',
      'async_this_bound_test',
      'async_throw_in_catch_test'
    ]);
  });

  dart_library.import('language/async_star_test').main();

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
