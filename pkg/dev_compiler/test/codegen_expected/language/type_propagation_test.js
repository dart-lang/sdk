dart_library.library('language/type_propagation_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_propagation_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_propagation_test = Object.create(null);
  let JSArrayOfB = () => (JSArrayOfB = dart.constFn(_interceptors.JSArray$(type_propagation_test.B)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_propagation_test.A = class A extends core.Object {
    resolveSend(node) {
      if (node == null) {
        return JSArrayOfB().of([new type_propagation_test.B()])[dartx.get](0);
      } else {
        return JSArrayOfObject().of([new type_propagation_test.B(), new type_propagation_test.A()])[dartx.get](1);
      }
    }
    visitSend(node) {
      let target = this.resolveSend(node);
      if (false) {
        if (false) {
          target = dart.dload(target, 'getter');
          if (false) {
            target = new core.Object();
          }
        }
      }
      return true ? target : null;
    }
  };
  dart.setSignature(type_propagation_test.A, {
    methods: () => ({
      resolveSend: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      visitSend: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  type_propagation_test.a = 43;
  type_propagation_test.B = class B extends core.Object {
    new() {
      this.getter = type_propagation_test.a == 42 ? new type_propagation_test.A() : null;
    }
  };
  type_propagation_test.main = function() {
    expect$.Expect.isTrue(type_propagation_test.A.is(new type_propagation_test.A().visitSend(new type_propagation_test.A())));
    expect$.Expect.isTrue(type_propagation_test.B.is(new type_propagation_test.A().visitSend(null)));
  };
  dart.fn(type_propagation_test.main, VoidTodynamic());
  // Exports:
  exports.type_propagation_test = type_propagation_test;
});
