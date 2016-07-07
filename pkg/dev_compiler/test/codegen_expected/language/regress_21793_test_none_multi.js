dart_library.library('language/regress_21793_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__regress_21793_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_21793_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_21793_test_none_multi.A = dart.callableClass(function A(...args) {
    const self = this;
    function call(...args) {
      return self.call.apply(self, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class A extends core.Object {
    call(x) {
      return x;
    }
  });
  dart.setSignature(regress_21793_test_none_multi.A, {
    methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  regress_21793_test_none_multi.main = function() {
    core.print(dart.dcall(new regress_21793_test_none_multi.A(), 499));
  };
  dart.fn(regress_21793_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.regress_21793_test_none_multi = regress_21793_test_none_multi;
});
