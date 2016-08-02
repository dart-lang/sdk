dart_library.library('language/cascade2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cascade2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cascade2_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cascade2_test.A = dart.callableClass(function A(...args) {
    function call(...args) {
      return call.call.apply(call, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class A extends core.Object {
    new() {
      this.foo = null;
    }
    add(list) {
      this.foo = list;
      dart.dsend(list, 'add', 2.5);
      return this;
    }
    call(arg) {
      return arg;
    }
  });
  dart.setSignature(cascade2_test.A, {
    methods: () => ({
      add: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      call: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  cascade2_test.main = function() {
    let foo = [42, 0];
    let a = new cascade2_test.A();
    let bar = ((() => {
      dart.dcall(a.add(foo), 'WHAT');
      return a;
    })());
    dart.dsetindex(a.foo, 0, new core.Object());
    expect$.Expect.throws(dart.fn(() => dart.dsend(foo[dartx.get](0), '+', 2), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(cascade2_test.main, VoidTodynamic());
  // Exports:
  exports.cascade2_test = cascade2_test;
});
