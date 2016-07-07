dart_library.library('language/identical_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__identical_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const identical_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  identical_test.notIdenticalTest1 = function(a) {
    if (!core.identical("ho", a)) {
      return 2;
    } else {
      return 1;
    }
  };
  dart.fn(identical_test.notIdenticalTest1, dynamicTodynamic());
  identical_test.notIdenticalTest2 = function(a) {
    let x = core.identical("ho", a);
    if (!x) {
      expect$.Expect.equals(false, x);
      return x;
    } else {
      expect$.Expect.equals(true, x);
      return 1;
    }
  };
  dart.fn(identical_test.notIdenticalTest2, dynamicTodynamic());
  identical_test.notIdenticalTest3 = function(a) {
    let x = core.identical("ho", a);
    return !x;
  };
  dart.fn(identical_test.notIdenticalTest3, dynamicTodynamic());
  identical_test.main = function() {
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals(1, identical_test.notIdenticalTest1("ho"));
      expect$.Expect.equals(1, identical_test.notIdenticalTest2("ho"));
      expect$.Expect.equals(false, identical_test.notIdenticalTest3("ho"));
    }
  };
  dart.fn(identical_test.main, VoidTodynamic());
  // Exports:
  exports.identical_test = identical_test;
});
