dart_library.library('corelib/regress_r21715_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_r21715_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_r21715_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_r21715_test.sll = function(x, shift) {
    return dart.dsend(x, '<<', shift);
  };
  dart.fn(regress_r21715_test.sll, dynamicAnddynamicTodynamic());
  regress_r21715_test.main = function() {
    for (let i = 0; i < 10; i++) {
      let x = 1342177280;
      let shift = 34;
      expect$.Expect.equals(regress_r21715_test.sll(x, shift), 23058430092136939520);
    }
  };
  dart.fn(regress_r21715_test.main, VoidTodynamic());
  // Exports:
  exports.regress_r21715_test = regress_r21715_test;
});
