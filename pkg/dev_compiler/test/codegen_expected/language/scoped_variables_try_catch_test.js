dart_library.library('language/scoped_variables_try_catch_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__scoped_variables_try_catch_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const scoped_variables_try_catch_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  scoped_variables_try_catch_test.main = function() {
    let a = scoped_variables_try_catch_test.bar();
    try {
      a = scoped_variables_try_catch_test.bar();
    } catch (e) {
    }

    expect$.Expect.equals(42, a);
    {
      let a = scoped_variables_try_catch_test.foo();
      try {
        a = scoped_variables_try_catch_test.foo();
      } catch (e) {
      }

      expect$.Expect.equals(54, a);
    }
    expect$.Expect.equals(42, a);
  };
  dart.fn(scoped_variables_try_catch_test.main, VoidTodynamic());
  scoped_variables_try_catch_test.bar = function() {
    return 42;
  };
  dart.fn(scoped_variables_try_catch_test.bar, VoidTodynamic());
  scoped_variables_try_catch_test.foo = function() {
    return 54;
  };
  dart.fn(scoped_variables_try_catch_test.foo, VoidTodynamic());
  // Exports:
  exports.scoped_variables_try_catch_test = scoped_variables_try_catch_test;
});
