dart_library.library('language/mixin_cyclic_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__mixin_cyclic_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_cyclic_test_none_multi = Object.create(null);
  let A = () => (A = dart.constFn(mixin_cyclic_test_none_multi.A$()))();
  let M = () => (M = dart.constFn(mixin_cyclic_test_none_multi.M$()))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  mixin_cyclic_test_none_multi.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  mixin_cyclic_test_none_multi.A = A();
  mixin_cyclic_test_none_multi.S = class S extends core.Object {};
  mixin_cyclic_test_none_multi.M$ = dart.generic(T => {
    class M extends core.Object {}
    dart.addTypeTests(M);
    return M;
  });
  mixin_cyclic_test_none_multi.M = M();
  mixin_cyclic_test_none_multi.C1 = class C1 extends dart.mixin(mixin_cyclic_test_none_multi.S, mixin_cyclic_test_none_multi.M) {
    new() {
      super.new();
    }
  };
  mixin_cyclic_test_none_multi.C3 = class C3 extends dart.mixin(mixin_cyclic_test_none_multi.S, mixin_cyclic_test_none_multi.M) {
    new() {
      super.new();
    }
  };
  mixin_cyclic_test_none_multi.main = function() {
    new mixin_cyclic_test_none_multi.C1();
    new mixin_cyclic_test_none_multi.C3();
  };
  dart.fn(mixin_cyclic_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.mixin_cyclic_test_none_multi = mixin_cyclic_test_none_multi;
});
