dart_library.library('corelib/apply4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__apply4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const apply4_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  apply4_test.A = class A extends core.Object {
    foo(x, y, z, a, b, c, d, e, f, g, h, i, j) {
      if (y === void 0) y = null;
      if (z === void 0) z = null;
      if (a === void 0) a = null;
      if (b === void 0) b = null;
      if (c === void 0) c = null;
      if (d === void 0) d = 99;
      if (e === void 0) e = null;
      if (f === void 0) f = null;
      if (g === void 0) g = null;
      if (h === void 0) h = null;
      if (i === void 0) i = null;
      if (j === void 0) j = null;
      return dart.str`${x} ${d}`;
    }
  };
  dart.setSignature(apply4_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])})
  });
  apply4_test.main = function() {
    let a = new apply4_test.A();
    let clos = dart.bind(a, 'foo');
    expect$.Expect.equals(core.Function.apply(clos, JSArrayOfString().of(["well"])), "well 99");
    expect$.Expect.equals(core.Function.apply(clos, JSArrayOfObject().of(["well", 0, 2, 4, 3, 6, 9, 10])), "well 9");
  };
  dart.fn(apply4_test.main, VoidTodynamic());
  // Exports:
  exports.apply4_test = apply4_test;
});
