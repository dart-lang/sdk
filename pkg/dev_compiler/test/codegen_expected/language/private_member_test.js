dart_library.library('language/private_member_test', null, /* Imports */[
  'dart_sdk'
], function load__private_member_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const private_member_test = Object.create(null);
  const private_member_lib_b = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const _instanceField = Symbol('_instanceField');
  const _fun1 = Symbol('_fun1');
  const _fun2 = Symbol('_fun2');
  private_member_test.A = class A extends core.Object {
    new() {
      this.i = null;
      this[_instanceField] = null;
    }
    [_fun1]() {
      return 1;
    }
    [_fun2](i) {}
  };
  dart.setSignature(private_member_test.A, {
    methods: () => ({
      [_fun1]: dart.definiteFunctionType(core.int, []),
      [_fun2]: dart.definiteFunctionType(dart.void, [core.int])
    })
  });
  private_member_test.A._staticField = null;
  const _instanceField$ = Symbol('_instanceField');
  const _fun1$ = Symbol('_fun1');
  const _fun2$ = Symbol('_fun2');
  private_member_lib_b.B = class B extends private_member_test.A {
    new() {
      this[_instanceField$] = null;
      super.new();
    }
    [_fun1$](b) {
      return true;
    }
    [_fun2$]() {}
  };
  dart.setSignature(private_member_lib_b.B, {
    methods: () => ({
      [_fun1$]: dart.definiteFunctionType(core.bool, [core.bool]),
      [_fun2$]: dart.definiteFunctionType(dart.void, [])
    })
  });
  private_member_lib_b.B._staticField = null;
  private_member_test.Test = class Test extends private_member_lib_b.B {
    new() {
      super.new();
    }
    test() {
      this.i = this[_instanceField];
      this.i = private_member_test.A._staticField;
      this.i = this[_fun1]();
      this[_fun2](42);
    }
  };
  dart.setSignature(private_member_test.Test, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  private_member_test.main = function() {
    new private_member_test.Test().test();
  };
  dart.fn(private_member_test.main, VoidTovoid());
  // Exports:
  exports.private_member_test = private_member_test;
  exports.private_member_lib_b = private_member_lib_b;
});
