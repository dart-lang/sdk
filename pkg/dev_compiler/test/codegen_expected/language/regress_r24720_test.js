dart_library.library('language/regress_r24720_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_r24720_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_r24720_test = Object.create(null);
  let A = () => (A = dart.constFn(regress_r24720_test.A$()))();
  let AOfint = () => (AOfint = dart.constFn(regress_r24720_test.A$(core.int)))();
  let AOfString = () => (AOfString = dart.constFn(regress_r24720_test.A$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_r24720_test.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  regress_r24720_test.A = A();
  regress_r24720_test.B = class B extends regress_r24720_test.A$(core.int) {
    new() {
      B.prototype.foo.call(this);
    }
    foo() {
    }
  };
  dart.addSimpleTypeTests(regress_r24720_test.B);
  dart.defineNamedConstructor(regress_r24720_test.B, 'foo');
  dart.setSignature(regress_r24720_test.B, {
    constructors: () => ({
      new: dart.definiteFunctionType(regress_r24720_test.B, []),
      foo: dart.definiteFunctionType(regress_r24720_test.B, [])
    })
  });
  regress_r24720_test.main = function() {
    expect$.Expect.isTrue(regress_r24720_test.B.is(new regress_r24720_test.B()));
    expect$.Expect.isTrue(AOfint().is(new regress_r24720_test.B()));
    expect$.Expect.isFalse(AOfString().is(new regress_r24720_test.B()));
  };
  dart.fn(regress_r24720_test.main, VoidTodynamic());
  // Exports:
  exports.regress_r24720_test = regress_r24720_test;
});
