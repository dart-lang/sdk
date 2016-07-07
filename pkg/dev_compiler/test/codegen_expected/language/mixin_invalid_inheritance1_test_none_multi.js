dart_library.library('language/mixin_invalid_inheritance1_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__mixin_invalid_inheritance1_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_invalid_inheritance1_test_none_multi = Object.create(null);
  let C = () => (C = dart.constFn(mixin_invalid_inheritance1_test_none_multi.C$()))();
  let COfC = () => (COfC = dart.constFn(mixin_invalid_inheritance1_test_none_multi.C$(mixin_invalid_inheritance1_test_none_multi.C)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_invalid_inheritance1_test_none_multi.C$ = dart.generic(T => {
    class C extends core.Object {}
    dart.addTypeTests(C);
    return C;
  });
  mixin_invalid_inheritance1_test_none_multi.C = C();
  mixin_invalid_inheritance1_test_none_multi.main = function() {
    return new (COfC())();
  };
  dart.fn(mixin_invalid_inheritance1_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.mixin_invalid_inheritance1_test_none_multi = mixin_invalid_inheritance1_test_none_multi;
});
