dart_library.library('language/constructor8_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor8_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor8_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor8_test.A = class A extends core.Object {
    withClosure(a) {
      this.b = null;
      let c = null;
      let f = dart.fn(() => c = 42, VoidToint());
      this.b = f();
      expect$.Expect.equals(42, this.b);
      expect$.Expect.equals(42, c);
    }
  };
  dart.defineNamedConstructor(constructor8_test.A, 'withClosure');
  dart.setSignature(constructor8_test.A, {
    constructors: () => ({withClosure: dart.definiteFunctionType(constructor8_test.A, [core.Map])})
  });
  constructor8_test.main = function() {
    new constructor8_test.A.withClosure(null);
    new constructor8_test.A.withClosure(dart.map());
  };
  dart.fn(constructor8_test.main, VoidTodynamic());
  // Exports:
  exports.constructor8_test = constructor8_test;
});
