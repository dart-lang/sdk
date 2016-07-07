dart_library.library('language/super_operator_index_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__super_operator_index_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const super_operator_index_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_operator_index_test_none_multi.A = class A extends core.Object {
    set(a, b) {
      return b;
    }
  };
  dart.setSignature(super_operator_index_test_none_multi.A, {
    methods: () => ({set: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])})
  });
  super_operator_index_test_none_multi.B = class B extends super_operator_index_test_none_multi.A {
    foo() {
      super.set(4, 42);
    }
  };
  dart.setSignature(super_operator_index_test_none_multi.B, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_operator_index_test_none_multi.C = class C extends core.Object {
    get(a) {}
  };
  dart.setSignature(super_operator_index_test_none_multi.C, {
    methods: () => ({get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  super_operator_index_test_none_multi.D = class D extends super_operator_index_test_none_multi.C {
    foo() {
      return super.get(2);
    }
  };
  dart.setSignature(super_operator_index_test_none_multi.D, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_operator_index_test_none_multi.E = class E extends core.Object {
    foo() {}
  };
  dart.setSignature(super_operator_index_test_none_multi.E, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_operator_index_test_none_multi.main = function() {
    new super_operator_index_test_none_multi.B().foo();
    new super_operator_index_test_none_multi.D().foo();
    new super_operator_index_test_none_multi.E().foo();
  };
  dart.fn(super_operator_index_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.super_operator_index_test_none_multi = super_operator_index_test_none_multi;
});
