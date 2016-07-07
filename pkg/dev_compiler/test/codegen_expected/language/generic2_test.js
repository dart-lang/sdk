dart_library.library('language/generic2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic2_test = Object.create(null);
  let A = () => (A = dart.constFn(generic2_test.A$()))();
  let AOfObject = () => (AOfObject = dart.constFn(generic2_test.A$(core.Object)))();
  let AOfint = () => (AOfint = dart.constFn(generic2_test.A$(core.int)))();
  let AOfB = () => (AOfB = dart.constFn(generic2_test.A$(generic2_test.B)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let AOfListOfint = () => (AOfListOfint = dart.constFn(generic2_test.A$(ListOfint())))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic2_test.A$ = dart.generic(T => {
    class A extends core.Object {
      foo(o) {
        return T.is(o);
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
    });
    return A;
  });
  generic2_test.A = A();
  generic2_test.B = class B extends core.Object {};
  generic2_test.C = class C extends generic2_test.A$(core.int) {};
  dart.addSimpleTypeTests(generic2_test.C);
  generic2_test.main = function() {
    expect$.Expect.isTrue(new (AOfObject())().foo(new generic2_test.B()));
    expect$.Expect.isTrue(new (AOfObject())().foo(1));
    expect$.Expect.isFalse(new (AOfint())().foo(new core.Object()));
    expect$.Expect.isFalse(new (AOfint())().foo('hest'));
    expect$.Expect.isTrue(new (AOfB())().foo(new generic2_test.B()));
    expect$.Expect.isFalse(new (AOfB())().foo(new core.Object()));
    expect$.Expect.isFalse(new (AOfB())().foo(1));
    expect$.Expect.isTrue(new generic2_test.C().foo(1));
    expect$.Expect.isFalse(new generic2_test.C().foo(new core.Object()));
    expect$.Expect.isFalse(new generic2_test.C().foo('hest'));
    expect$.Expect.isTrue(new (AOfListOfint())().foo(ListOfint().new()));
    expect$.Expect.isFalse(new (AOfListOfint())().foo(ListOfString().new()));
  };
  dart.fn(generic2_test.main, VoidTodynamic());
  // Exports:
  exports.generic2_test = generic2_test;
});
