dart_library.library('language/setter4_test', null, /* Imports */[
  'dart_sdk'
], function load__setter4_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const setter4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  setter4_test.A = class A extends core.Object {
    a() {
      return 1;
    }
    set a(val) {
      let i = core.int._check(val);
    }
  };
  dart.setSignature(setter4_test.A, {
    methods: () => ({a: dart.definiteFunctionType(core.int, [])})
  });
  setter4_test.main = function() {
  };
  dart.fn(setter4_test.main, VoidTodynamic());
  // Exports:
  exports.setter4_test = setter4_test;
});
