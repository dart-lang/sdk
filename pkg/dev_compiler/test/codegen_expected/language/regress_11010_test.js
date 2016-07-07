dart_library.library('language/regress_11010_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_11010_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_11010_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(regress_11010_test, {
    get caller() {
      return new regress_11010_test.Caller();
    },
    set caller(_) {}
  });
  regress_11010_test.Caller = dart.callableClass(function Caller(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class Caller extends core.Object {
    call(a, b) {
      return dart.dsend(a, '+', b);
    }
  });
  dart.setSignature(regress_11010_test.Caller, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])})
  });
  regress_11010_test.main = function() {
    if (!dart.equals(dart.dcall(regress_11010_test.caller, 42, 87), 42 + 87)) {
      dart.throw('unexpected result');
    }
  };
  dart.fn(regress_11010_test.main, VoidTodynamic());
  // Exports:
  exports.regress_11010_test = regress_11010_test;
});
