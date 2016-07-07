dart_library.library('language/setter3_test_02_multi', null, /* Imports */[
  'dart_sdk'
], function load__setter3_test_02_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const setter3_test_02_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  setter3_test_02_multi.A = class A extends core.Object {
    set foo(x) {}
    set bar(x) {}
    set bob(x) {}
  };
  setter3_test_02_multi.main = function() {
    new setter3_test_02_multi.A();
  };
  dart.fn(setter3_test_02_multi.main, VoidTodynamic());
  // Exports:
  exports.setter3_test_02_multi = setter3_test_02_multi;
});
