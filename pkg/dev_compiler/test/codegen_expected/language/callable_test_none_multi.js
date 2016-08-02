dart_library.library('language/callable_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__callable_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const callable_test_none_multi = Object.create(null);
  let Z = () => (Z = dart.constFn(callable_test_none_multi.Z$()))();
  let ZOfint = () => (ZOfint = dart.constFn(callable_test_none_multi.Z$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  callable_test_none_multi.X = dart.callableClass(function X(...args) {
    function call(...args) {
      return call.call.apply(call, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class X extends core.Object {
    call() {
      return 42;
    }
  });
  dart.setSignature(callable_test_none_multi.X, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [])})
  });
  callable_test_none_multi.Y = dart.callableClass(function Y(...args) {
    function call(...args) {
      return call.call.apply(call, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class Y extends core.Object {
    call(x) {
      return 87 + dart.notNull(x);
    }
    static staticMethod(x) {
      return dart.notNull(x) + 1;
    }
  });
  dart.setSignature(callable_test_none_multi.Y, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [core.int])}),
    statics: () => ({staticMethod: dart.definiteFunctionType(core.int, [core.int])}),
    names: ['staticMethod']
  });
  callable_test_none_multi.Z$ = dart.generic(T => {
    const Z = dart.callableClass(function Z(...args) {
      function call(...args) {
        return call.call.apply(call, args);
      }
      call.__proto__ = this.__proto__;
      call.new.apply(call, args);
      return call;
    }, class Z extends core.Object {
      new(value) {
        this.value = value;
      }
      call() {
        return this.value;
      }
      static staticMethod(x) {
        return dart.notNull(x) + 1;
      }
    });
    dart.addTypeTests(Z);
    dart.setSignature(Z, {
      constructors: () => ({new: dart.definiteFunctionType(callable_test_none_multi.Z$(T), [T])}),
      methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [])}),
      statics: () => ({staticMethod: dart.definiteFunctionType(core.int, [core.int])}),
      names: ['staticMethod']
    });
    return Z;
  });
  callable_test_none_multi.Z = Z();
  callable_test_none_multi.F = dart.typedef('F', () => dart.functionType(dart.dynamic, [core.int]));
  callable_test_none_multi.G = dart.typedef('G', () => dart.functionType(dart.dynamic, [core.String]));
  callable_test_none_multi.main = function() {
    let x = new callable_test_none_multi.X();
    let f = x;
    let y = new callable_test_none_multi.Y();
    let g = y;
    let f0 = y;
    expect$.Expect.equals(dart.dcall(f), 42);
    expect$.Expect.equals(dart.dcall(g, 100), 187);
    let z = new (ZOfint())(123);
    expect$.Expect.equals(z(), 123);
    expect$.Expect.equals(callable_test_none_multi.Y.staticMethod(6), 7);
    expect$.Expect.equals(callable_test_none_multi.Z.staticMethod(6), 7);
  };
  dart.fn(callable_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.callable_test_none_multi = callable_test_none_multi;
});
