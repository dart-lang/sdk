dart_library.library('language/regress_21998_2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_21998_2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_21998_2_test = Object.create(null);
  const regress_21998_lib1 = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndStringAndStringToString = () => (StringAndStringAndStringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String, core.String, core.String])))();
  regress_21998_2_test.main = function() {
    expect$.Expect.equals(4, new regress_21998_2_test.C().m());
  };
  dart.fn(regress_21998_2_test.main, VoidTodynamic());
  regress_21998_2_test.C = class C extends core.Object {
    max(a) {
      return a;
    }
    m() {
      return this.max(math.max(core.int)(2, regress_21998_lib1.max('a', 'b', 'cd')[dartx.length]));
    }
  };
  dart.setSignature(regress_21998_2_test.C, {
    methods: () => ({
      max: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      m: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  regress_21998_lib1.max = function(a, b, c) {
    return dart.str`${a}${b}${c}`;
  };
  dart.fn(regress_21998_lib1.max, StringAndStringAndStringToString());
  // Exports:
  exports.regress_21998_2_test = regress_21998_2_test;
  exports.regress_21998_lib1 = regress_21998_lib1;
});
