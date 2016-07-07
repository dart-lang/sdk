dart_library.library('language/regress_22936_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_22936_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_22936_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_22936_test_none_multi.fooCalled = false;
  regress_22936_test_none_multi.foo = function() {
    regress_22936_test_none_multi.fooCalled = true;
    return null;
  };
  dart.fn(regress_22936_test_none_multi.foo, VoidTodynamic());
  regress_22936_test_none_multi.main = function() {
    let x = null;
    try {
      regress_22936_test_none_multi.foo();
    } catch (e) {
      if (core.NoSuchMethodError.is(e)) {
      } else
        throw e;
    }

    expect$.Expect.isTrue(regress_22936_test_none_multi.fooCalled);
  };
  dart.fn(regress_22936_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.regress_22936_test_none_multi = regress_22936_test_none_multi;
});
