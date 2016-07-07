dart_library.library('language/mixin_black_listed_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_black_listed_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_black_listed_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_black_listed_test_none_multi.C = class C extends core.Object {};
  mixin_black_listed_test_none_multi.D = class D extends core.Object {};
  mixin_black_listed_test_none_multi.C1 = class C1 extends core.Object {};
  mixin_black_listed_test_none_multi.D1 = class D1 extends dart.mixin(core.Object, mixin_black_listed_test_none_multi.C) {};
  mixin_black_listed_test_none_multi.E1 = class E1 extends dart.mixin(core.Object, mixin_black_listed_test_none_multi.C) {};
  mixin_black_listed_test_none_multi.F1 = class F1 extends dart.mixin(core.Object, mixin_black_listed_test_none_multi.C, mixin_black_listed_test_none_multi.D) {};
  mixin_black_listed_test_none_multi.D2 = class D2 extends dart.mixin(core.Object, mixin_black_listed_test_none_multi.C) {};
  mixin_black_listed_test_none_multi.E2 = class E2 extends dart.mixin(core.Object, mixin_black_listed_test_none_multi.C) {};
  mixin_black_listed_test_none_multi.F2 = class F2 extends dart.mixin(core.Object, mixin_black_listed_test_none_multi.C, mixin_black_listed_test_none_multi.D) {};
  mixin_black_listed_test_none_multi.main = function() {
    expect$.Expect.isNotNull(new mixin_black_listed_test_none_multi.C1());
    expect$.Expect.isNotNull(new mixin_black_listed_test_none_multi.D1());
    expect$.Expect.isNotNull(new mixin_black_listed_test_none_multi.E1());
    expect$.Expect.isNotNull(new mixin_black_listed_test_none_multi.F1());
    expect$.Expect.isNotNull(new mixin_black_listed_test_none_multi.D2());
    expect$.Expect.isNotNull(new mixin_black_listed_test_none_multi.E2());
    expect$.Expect.isNotNull(new mixin_black_listed_test_none_multi.F2());
  };
  dart.fn(mixin_black_listed_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.mixin_black_listed_test_none_multi = mixin_black_listed_test_none_multi;
});
