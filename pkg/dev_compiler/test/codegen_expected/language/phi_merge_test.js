dart_library.library('language/phi_merge_test', null, /* Imports */[
  'dart_sdk'
], function load__phi_merge_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const phi_merge_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  phi_merge_test.A = class A extends core.Object {
    set(index, value) {
      switch (value) {
        case 42:
        {
          break;
        }
        case 43:
        {
          break;
        }
      }
      return value;
    }
  };
  dart.setSignature(phi_merge_test.A, {
    methods: () => ({set: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])})
  });
  phi_merge_test.main = function() {
    let a = null;
    if (true) {
      a = new phi_merge_test.A();
    } else {
      a = new phi_merge_test.A();
    }
    dart.dsetindex(a, 0, 42);
    core.print(a);
  };
  dart.fn(phi_merge_test.main, VoidTodynamic());
  // Exports:
  exports.phi_merge_test = phi_merge_test;
});
