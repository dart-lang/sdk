dart_library.library('language/type_propagation3_test', null, /* Imports */[
  'dart_sdk'
], function load__type_propagation3_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_propagation3_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_propagation3_test.A = class A extends core.Object {
    next() {
      return new type_propagation3_test.B();
    }
    doIt() {
      return null;
    }
    get isEmpty() {
      return false;
    }
    foo() {
      return 42;
    }
    bar() {
      return 54;
    }
  };
  dart.setSignature(type_propagation3_test.A, {
    methods: () => ({
      next: dart.definiteFunctionType(dart.dynamic, []),
      doIt: dart.definiteFunctionType(dart.dynamic, []),
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  type_propagation3_test.entered = false;
  type_propagation3_test.B = class B extends type_propagation3_test.A {
    foo() {
      return 54;
    }
    doIt() {
      return new type_propagation3_test.A();
    }
    get isEmpty() {
      return true;
    }
    bar() {
      return type_propagation3_test.entered = true;
    }
  };
  type_propagation3_test.main = function() {
    let a = new type_propagation3_test.A();
    for (let i of JSArrayOfint().of([42])) {
      a = type_propagation3_test.A._check(a.next());
    }
    let b = a;
    while (dart.test(b.isEmpty)) {
      b.foo();
      b.bar();
      b = type_propagation3_test.A._check(b.doIt());
    }
    if (!dart.test(type_propagation3_test.entered)) dart.throw('Test failed');
  };
  dart.fn(type_propagation3_test.main, VoidTodynamic());
  // Exports:
  exports.type_propagation3_test = type_propagation3_test;
});
