dart_library.library('language/mixin_issue10216_2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_issue10216_2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_issue10216_2_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_issue10216_2_test.M0 = class M0 extends core.Object {
    foo() {
      return 42;
    }
  };
  dart.setSignature(mixin_issue10216_2_test.M0, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  mixin_issue10216_2_test.M1 = class M1 extends dart.mixin(core.Object, mixin_issue10216_2_test.M0) {};
  mixin_issue10216_2_test.M2 = class M2 extends dart.mixin(core.Object, mixin_issue10216_2_test.M1) {};
  mixin_issue10216_2_test.makeM2 = function() {
    return mixin_issue10216_2_test.M2.as(JSArrayOfObject().of([new core.Object(), new mixin_issue10216_2_test.M2()])[dartx.last]);
  };
  dart.fn(mixin_issue10216_2_test.makeM2, VoidTodynamic());
  mixin_issue10216_2_test.main = function() {
    expect$.Expect.equals(42, dart.dsend(mixin_issue10216_2_test.makeM2(), 'foo'));
  };
  dart.fn(mixin_issue10216_2_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_issue10216_2_test = mixin_issue10216_2_test;
});
