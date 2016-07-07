dart_library.library('language/method_name_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__method_name_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const method_name_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  method_name_test.A = class A extends core.Object {
    get() {
      return 1;
    }
    set() {
      return 2;
    }
    operator() {
      return 3;
    }
  };
  dart.setSignature(method_name_test.A, {
    methods: () => ({
      get: dart.definiteFunctionType(core.int, []),
      set: dart.definiteFunctionType(core.int, []),
      operator: dart.definiteFunctionType(core.int, [])
    })
  });
  method_name_test.B = class B extends core.Object {
    get() {
      return 1;
    }
    set() {
      return 2;
    }
    operator() {
      return 3;
    }
  };
  dart.setSignature(method_name_test.B, {
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, []),
      set: dart.definiteFunctionType(dart.dynamic, []),
      operator: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  method_name_test.main = function() {
    {
      let a = new method_name_test.A();
      expect$.Expect.equals(1, a.get());
      expect$.Expect.equals(2, a.set());
      expect$.Expect.equals(3, a.operator());
    }
    {
      let b = new method_name_test.B();
      expect$.Expect.equals(1, b.get());
      expect$.Expect.equals(2, b.set());
      expect$.Expect.equals(3, b.operator());
    }
  };
  dart.fn(method_name_test.main, VoidTodynamic());
  // Exports:
  exports.method_name_test = method_name_test;
});
