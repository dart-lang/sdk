dart_library.library('language/regress_21998_1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_21998_1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_21998_1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_21998_1_test.main = function() {
    expect$.Expect.equals(4, new regress_21998_1_test.C().m());
  };
  dart.fn(regress_21998_1_test.main, VoidTodynamic());
  regress_21998_1_test.C = class C extends core.Object {
    max(a) {
      return a;
    }
    m() {
      return this.max(math.max(core.int)(2, 4));
    }
  };
  dart.setSignature(regress_21998_1_test.C, {
    methods: () => ({
      max: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      m: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  // Exports:
  exports.regress_21998_1_test = regress_21998_1_test;
});
