dart_library.library('language/callable_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__callable_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const callable_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  callable_test_none_multi.X = dart.callableClass(function X(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
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
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class Y extends core.Object {
    call(x) {
      return 87;
    }
  });
  dart.setSignature(callable_test_none_multi.Y, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [core.int])})
  });
  callable_test_none_multi.F = dart.typedef('F', () => dart.functionType(dart.dynamic, [core.int]));
  callable_test_none_multi.G = dart.typedef('G', () => dart.functionType(dart.dynamic, [core.String]));
  callable_test_none_multi.main = function() {
    let x = new callable_test_none_multi.X();
    let f = x;
    let y = new callable_test_none_multi.Y();
    let g = y;
    let f0 = y;
  };
  dart.fn(callable_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.callable_test_none_multi = callable_test_none_multi;
});
