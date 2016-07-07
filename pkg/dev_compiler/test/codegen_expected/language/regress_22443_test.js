dart_library.library('language/regress_22443_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_22443_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_22443_test = Object.create(null);
  const regress_22443_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  regress_22443_test.fooCount = 0;
  regress_22443_test.foo = function() {
    regress_22443_test.fooCount = dart.notNull(regress_22443_test.fooCount) + 1;
    return new regress_22443_lib.LazyClass();
  };
  dart.fn(regress_22443_test.foo, VoidTodynamic());
  regress_22443_test.main = function() {
    let caughtIt = false;
    try {
      regress_22443_test.foo();
    } catch (e) {
      caughtIt = true;
    }

    ;
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      regress_22443_test.foo();
      expect$.Expect.isTrue(caughtIt);
      expect$.Expect.equals(2, regress_22443_test.fooCount);
    }, dynamicTodynamic()));
  };
  dart.fn(regress_22443_test.main, VoidTodynamic());
  regress_22443_lib.LazyClass = class LazyClass extends core.Object {};
  // Exports:
  exports.regress_22443_test = regress_22443_test;
  exports.regress_22443_lib = regress_22443_lib;
});
