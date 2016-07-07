dart_library.library('language/closures_initializer2_test', null, /* Imports */[
  'dart_sdk'
], function load__closures_initializer2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const closures_initializer2_test = Object.create(null);
  let A = () => (A = dart.constFn(closures_initializer2_test.A$()))();
  let AOfint = () => (AOfint = dart.constFn(closures_initializer2_test.A$(core.int)))();
  let VoidToType = () => (VoidToType = dart.constFn(dart.definiteFunctionType(core.Type, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closures_initializer2_test.A$ = dart.generic(T => {
    class A extends core.Object {
      new() {
        this.t = dart.fn(() => dart.wrapType(T), VoidToType());
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(closures_initializer2_test.A$(T), [])})
    });
    return A;
  });
  closures_initializer2_test.A = A();
  closures_initializer2_test.expect = function(result, expected) {
    if (!dart.equals(result, expected)) {
      dart.throw(dart.str`Expected ${expected}, got ${result}`);
    }
  };
  dart.fn(closures_initializer2_test.expect, dynamicAnddynamicTodynamic());
  closures_initializer2_test.main = function() {
    for (let i = 0; i < dart.notNull(core.int.parse("1")); i++) {
      closures_initializer2_test.expect(core.Type.is(dart.dsend(new (AOfint())(), 't')), true);
    }
  };
  dart.fn(closures_initializer2_test.main, VoidTodynamic());
  // Exports:
  exports.closures_initializer2_test = closures_initializer2_test;
});
