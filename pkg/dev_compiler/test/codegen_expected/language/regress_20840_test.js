dart_library.library('language/regress_20840_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_20840_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_20840_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  regress_20840_test.SomeClass = class SomeClass extends core.Object {
    new() {
      this.someField = null;
      JSArrayOfint().of([1])[dartx.forEach](dart.fn(o => this.someMethod(), intTovoid()));
      this.someField = new core.Object();
    }
    someMethod() {
      if (this.someField != null) {
        dart.throw("FAIL");
      }
    }
  };
  dart.setSignature(regress_20840_test.SomeClass, {
    constructors: () => ({new: dart.definiteFunctionType(regress_20840_test.SomeClass, [])}),
    methods: () => ({someMethod: dart.definiteFunctionType(dart.void, [])})
  });
  regress_20840_test.main = function() {
    new regress_20840_test.SomeClass();
  };
  dart.fn(regress_20840_test.main, VoidTovoid());
  // Exports:
  exports.regress_20840_test = regress_20840_test;
});
