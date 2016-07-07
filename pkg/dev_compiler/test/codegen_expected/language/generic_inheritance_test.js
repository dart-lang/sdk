dart_library.library('language/generic_inheritance_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_inheritance_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_inheritance_test = Object.create(null);
  let A = () => (A = dart.constFn(generic_inheritance_test.A$()))();
  let AOfString = () => (AOfString = dart.constFn(generic_inheritance_test.A$(core.String)))();
  let AOfObject = () => (AOfObject = dart.constFn(generic_inheritance_test.A$(core.Object)))();
  let AOfint = () => (AOfint = dart.constFn(generic_inheritance_test.A$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_inheritance_test.A$ = dart.generic(T => {
    class A extends core.Object {
      new() {
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(generic_inheritance_test.A$(T), [])})
    });
    return A;
  });
  generic_inheritance_test.A = A();
  generic_inheritance_test.B = class B extends generic_inheritance_test.A$(core.Object) {
    new() {
      super.new();
    }
  };
  dart.addSimpleTypeTests(generic_inheritance_test.B);
  dart.setSignature(generic_inheritance_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(generic_inheritance_test.B, [])})
  });
  generic_inheritance_test.C = class C extends generic_inheritance_test.B {
    new() {
      super.new();
    }
  };
  dart.setSignature(generic_inheritance_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(generic_inheritance_test.C, [])})
  });
  generic_inheritance_test.main = function() {
    let a = new (AOfString())();
    let b = new generic_inheritance_test.B();
    let c = new generic_inheritance_test.C();
    expect$.Expect.isTrue(core.Object.is(a));
    expect$.Expect.isTrue(AOfObject().is(a));
    expect$.Expect.isTrue(AOfString().is(a));
    expect$.Expect.isTrue(!AOfint().is(a));
    expect$.Expect.isTrue(core.Object.is(b));
    expect$.Expect.isTrue(AOfObject().is(b));
    expect$.Expect.isTrue(!AOfString().is(b));
    expect$.Expect.isTrue(core.Object.is(b));
    expect$.Expect.isTrue(core.Object.is(c));
    expect$.Expect.isTrue(AOfObject().is(c));
    expect$.Expect.isTrue(!AOfString().is(c));
    expect$.Expect.isTrue(generic_inheritance_test.B.is(c));
  };
  dart.fn(generic_inheritance_test.main, VoidTodynamic());
  // Exports:
  exports.generic_inheritance_test = generic_inheritance_test;
});
