dart_library.library('language/issue10747_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__issue10747_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const issue10747_test = Object.create(null);
  let B = () => (B = dart.constFn(issue10747_test.B$()))();
  let A = () => (A = dart.constFn(issue10747_test.A$()))();
  let AOfint = () => (AOfint = dart.constFn(issue10747_test.A$(core.int)))();
  let AOfString = () => (AOfString = dart.constFn(issue10747_test.A$(core.String)))();
  let BOfint = () => (BOfint = dart.constFn(issue10747_test.B$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue10747_test.B$ = dart.generic(T => {
    class B extends core.Object {}
    dart.addTypeTests(B);
    return B;
  });
  issue10747_test.B = B();
  issue10747_test.A$ = dart.generic(T => {
    let BOfT = () => (BOfT = dart.constFn(issue10747_test.B$(T)))();
    class A extends core.Object {
      new(field) {
        this.field = field;
      }
      asTypeVariable() {
        return T.as(this.field);
      }
      asBOfT() {
        return BOfT().as(this.field);
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(issue10747_test.A$(T), [dart.dynamic])}),
      methods: () => ({
        asTypeVariable: dart.definiteFunctionType(dart.dynamic, []),
        asBOfT: dart.definiteFunctionType(dart.dynamic, [])
      })
    });
    return A;
  });
  issue10747_test.A = A();
  issue10747_test.main = function() {
    expect$.Expect.equals(42, new (AOfint())(42).asTypeVariable());
    expect$.Expect.throws(dart.fn(() => new (AOfString())(42).asTypeVariable(), VoidTovoid()), dart.fn(e => core.CastError.is(e), dynamicTobool()));
    let b = new (BOfint())();
    expect$.Expect.equals(b, new (AOfint())(b).asBOfT());
    expect$.Expect.throws(dart.fn(() => new (AOfString())(b).asBOfT(), VoidTovoid()), dart.fn(e => core.CastError.is(e), dynamicTobool()));
  };
  dart.fn(issue10747_test.main, VoidTodynamic());
  // Exports:
  exports.issue10747_test = issue10747_test;
});
