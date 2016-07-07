dart_library.library('language/malbounded_instantiation_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__malbounded_instantiation_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const malbounded_instantiation_test_none_multi = Object.create(null);
  let Super = () => (Super = dart.constFn(malbounded_instantiation_test_none_multi.Super$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  malbounded_instantiation_test_none_multi.Super$ = dart.generic(T => {
    class Super extends core.Object {}
    dart.addTypeTests(Super);
    return Super;
  });
  malbounded_instantiation_test_none_multi.Super = Super();
  malbounded_instantiation_test_none_multi.main = function() {
  };
  dart.fn(malbounded_instantiation_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.malbounded_instantiation_test_none_multi = malbounded_instantiation_test_none_multi;
});
