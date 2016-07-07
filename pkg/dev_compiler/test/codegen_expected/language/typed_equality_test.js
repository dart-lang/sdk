dart_library.library('language/typed_equality_test', null, /* Imports */[
  'dart_sdk'
], function load__typed_equality_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const typed_equality_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_equality_test.foo = function(a, b) {
    if (core.identical(a, b)) return;
    dart.throw('broken');
  };
  dart.fn(typed_equality_test.foo, dynamicAnddynamicTodynamic());
  typed_equality_test.D = class D extends core.Object {};
  typed_equality_test.C = class C extends core.Object {};
  typed_equality_test.C[dart.implements] = () => [typed_equality_test.D];
  typed_equality_test.main = function() {
    let c = new typed_equality_test.C();
    typed_equality_test.foo(c, c);
  };
  dart.fn(typed_equality_test.main, VoidTodynamic());
  // Exports:
  exports.typed_equality_test = typed_equality_test;
});
