dart_library.library('language/malbounded_type_test_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__malbounded_type_test_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const malbounded_type_test_test_none_multi = Object.create(null);
  let Super = () => (Super = dart.constFn(malbounded_type_test_test_none_multi.Super$()))();
  let SuperOfint = () => (SuperOfint = dart.constFn(malbounded_type_test_test_none_multi.Super$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  malbounded_type_test_test_none_multi.Super$ = dart.generic(T => {
    class Super extends core.Object {}
    dart.addTypeTests(Super);
    return Super;
  });
  malbounded_type_test_test_none_multi.Super = Super();
  malbounded_type_test_test_none_multi.main = function() {
    let s = new (SuperOfint())();
  };
  dart.fn(malbounded_type_test_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.malbounded_type_test_test_none_multi = malbounded_type_test_test_none_multi;
});
