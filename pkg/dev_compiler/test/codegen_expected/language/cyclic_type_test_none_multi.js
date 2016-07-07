dart_library.library('language/cyclic_type_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__cyclic_type_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const cyclic_type_test_none_multi = Object.create(null);
  let Base = () => (Base = dart.constFn(cyclic_type_test_none_multi.Base$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cyclic_type_test_none_multi.Base$ = dart.generic(T => {
    class Base extends core.Object {
      get t() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(Base);
    return Base;
  });
  cyclic_type_test_none_multi.Base = Base();
  cyclic_type_test_none_multi.main = function() {
    let d = null;
  };
  dart.fn(cyclic_type_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.cyclic_type_test_none_multi = cyclic_type_test_none_multi;
});
