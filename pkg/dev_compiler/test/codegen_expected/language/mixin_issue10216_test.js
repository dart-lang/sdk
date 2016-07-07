dart_library.library('language/mixin_issue10216_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_issue10216_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_issue10216_test = Object.create(null);
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(mixin_issue10216_test.A)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_issue10216_test.A = class A extends core.Object {
    foo(x, y) {
      if (y === void 0) y = null;
      return dart.str`${x};${y}`;
    }
  };
  dart.setSignature(mixin_issue10216_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic])})
  });
  mixin_issue10216_test.M1 = class M1 extends core.Object {};
  mixin_issue10216_test.M2 = class M2 extends core.Object {
    plain(x) {
      return dart.str`P ${x}`;
    }
    bar(x, y) {
      if (y === void 0) y = null;
      return dart.str`${y},${x}`;
    }
  };
  dart.setSignature(mixin_issue10216_test.M2, {
    methods: () => ({
      plain: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic])
    })
  });
  mixin_issue10216_test.M3 = class M3 extends core.Object {};
  mixin_issue10216_test.B = class B extends dart.mixin(mixin_issue10216_test.A, mixin_issue10216_test.M1, mixin_issue10216_test.M2, mixin_issue10216_test.M3) {};
  mixin_issue10216_test.makeB = function() {
    return mixin_issue10216_test.B.as(JSArrayOfA().of([new mixin_issue10216_test.A(), new mixin_issue10216_test.B()])[dartx.last]);
  };
  dart.fn(mixin_issue10216_test.makeB, VoidTodynamic());
  mixin_issue10216_test.main = function() {
    let b = mixin_issue10216_test.makeB();
    expect$.Expect.equals('1;2', dart.dsend(b, 'foo', 1, 2));
    expect$.Expect.equals('2;null', dart.dsend(b, 'foo', 2));
    expect$.Expect.equals('P 3', dart.dsend(b, 'plain', 3));
    expect$.Expect.equals('100,4', dart.dsend(b, 'bar', 4, 100));
    expect$.Expect.equals('null,5', dart.dsend(b, 'bar', 5));
  };
  dart.fn(mixin_issue10216_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_issue10216_test = mixin_issue10216_test;
});
