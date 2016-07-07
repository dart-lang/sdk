dart_library.library('language/const_native_factory_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__const_native_factory_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const const_native_factory_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_native_factory_test_none_multi.Cake = class Cake extends core.Object {
    new(name) {
      this.name = name;
    }
  };
  dart.setSignature(const_native_factory_test_none_multi.Cake, {
    constructors: () => ({new: dart.definiteFunctionType(const_native_factory_test_none_multi.Cake, [dart.dynamic])})
  });
  let const$;
  const_native_factory_test_none_multi.main = function() {
    let c = const$ || (const$ = dart.const(new const_native_factory_test_none_multi.Cake("Sacher")));
  };
  dart.fn(const_native_factory_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.const_native_factory_test_none_multi = const_native_factory_test_none_multi;
});
