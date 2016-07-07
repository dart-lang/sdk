dart_library.library('language/regress_21998_4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_21998_4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_21998_4_test = Object.create(null);
  const regress_21998_lib1 = Object.create(null);
  const regress_21998_lib2 = Object.create(null);
  const regress_21998_lib3 = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndStringAndStringToString = () => (StringAndStringAndStringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String, core.String, core.String])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  regress_21998_4_test.main = function() {
    expect$.Expect.equals(4, new regress_21998_4_test.C().m());
  };
  dart.fn(regress_21998_4_test.main, VoidTodynamic());
  regress_21998_4_test.C = class C extends core.Object {
    max(a) {
      return a;
    }
    m() {
      return this.max(math.max(core.num)(core.num._check(regress_21998_lib3.lib3_max(0, regress_21998_lib2.lib2_max(1, 2))), regress_21998_lib1.max('a', 'b', 'cd')[dartx.length]));
    }
  };
  dart.setSignature(regress_21998_4_test.C, {
    methods: () => ({
      max: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      m: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  regress_21998_lib1.max = function(a, b, c) {
    return dart.str`${a}${b}${c}`;
  };
  dart.fn(regress_21998_lib1.max, StringAndStringAndStringToString());
  regress_21998_lib2.lib2_max = function(a, b) {
    return math.max(core.num)(core.num._check(a), core.num._check(b));
  };
  dart.fn(regress_21998_lib2.lib2_max, dynamicAnddynamicTodynamic());
  regress_21998_lib3.lib3_max = function(a, b) {
    return math.max(core.num)(core.num._check(a), core.num._check(b));
  };
  dart.fn(regress_21998_lib3.lib3_max, dynamicAnddynamicTodynamic());
  // Exports:
  exports.regress_21998_4_test = regress_21998_4_test;
  exports.regress_21998_lib1 = regress_21998_lib1;
  exports.regress_21998_lib2 = regress_21998_lib2;
  exports.regress_21998_lib3 = regress_21998_lib3;
});
