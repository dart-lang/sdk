dart_library.library('language/regress_10996_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_10996_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_10996_test = Object.create(null);
  const regress_10996_lib = Object.create(null);
  let dynamic__Todynamic = () => (dynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic])))();
  let dynamic__Todynamic$ = () => (dynamic__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {d: dart.dynamic})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_10996_test.foo = function(a, b) {
    if (b === void 0) b = null;
    return dart.dsend(dart.dsend(dart.dsend(a, '+', b), '+', regress_10996_lib.a), '+', regress_10996_lib.b);
  };
  dart.fn(regress_10996_test.foo, dynamic__Todynamic());
  regress_10996_test.bar = function(c, opts) {
    let d = opts && 'd' in opts ? opts.d : null;
    return dart.dsend(dart.dsend(dart.dsend(c, '+', d), '+', regress_10996_lib.c), '+', regress_10996_lib.d);
  };
  dart.fn(regress_10996_test.bar, dynamic__Todynamic$());
  regress_10996_test.main = function() {
    expect$.Expect.equals(1 + 2 + 3 + 4, regress_10996_test.foo(1, 2));
    expect$.Expect.equals(7 + 8 + 3 + 4, regress_10996_test.foo(7, 8));
    expect$.Expect.equals(3 + 4 + 5 + 6, regress_10996_test.bar(3, {d: 4}));
    expect$.Expect.equals(7 + 8 + 5 + 6, regress_10996_test.bar(7, {d: 8}));
  };
  dart.fn(regress_10996_test.main, VoidTodynamic());
  regress_10996_lib.a = 3;
  regress_10996_lib.b = 4;
  regress_10996_lib.c = 5;
  regress_10996_lib.d = 6;
  // Exports:
  exports.regress_10996_test = regress_10996_test;
  exports.regress_10996_lib = regress_10996_lib;
});
