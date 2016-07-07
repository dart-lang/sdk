dart_library.library('language/issue14014_3_test', null, /* Imports */[
  'dart_sdk'
], function load__issue14014_3_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue14014_3_test = Object.create(null);
  let A = () => (A = dart.constFn(issue14014_3_test.A$()))();
  let foo = () => (foo = dart.constFn(issue14014_3_test.foo$()))();
  let B = () => (B = dart.constFn(issue14014_3_test.B$()))();
  let BOfint = () => (BOfint = dart.constFn(issue14014_3_test.B$(core.int)))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue14014_3_test.A$ = dart.generic(T => {
    class A extends core.Object {
      new(f) {
        this.f = f;
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(issue14014_3_test.A$(T), [dart.dynamic])})
    });
    return A;
  });
  issue14014_3_test.A = A();
  issue14014_3_test.foo$ = dart.generic(T => {
    const foo = dart.typedef('foo', () => dart.functionType(dart.dynamic, [T]));
    return foo;
  });
  issue14014_3_test.foo = foo();
  issue14014_3_test.B$ = dart.generic(T => {
    let fooOfT = () => (fooOfT = dart.constFn(issue14014_3_test.foo$(T)))();
    let TTovoid = () => (TTovoid = dart.constFn(dart.functionType(dart.void, [T])))();
    class B extends issue14014_3_test.A$(T) {
      new(opts) {
        let f = opts && 'f' in opts ? opts.f : null;
        super.new(dart.fn(() => fooOfT().is(f), VoidTobool()));
      }
    }
    dart.setSignature(B, {
      constructors: () => ({new: dart.definiteFunctionType(issue14014_3_test.B$(T), [], {f: TTovoid()})})
    });
    return B;
  });
  issue14014_3_test.B = B();
  issue14014_3_test.main = function() {
    let t = new (BOfint())({f: dart.fn(a => 42, intToint())});
    if (!dart.test(dart.dsend(t, 'f'))) {
      dart.throw('Test failed');
    }
  };
  dart.fn(issue14014_3_test.main, VoidTodynamic());
  // Exports:
  exports.issue14014_3_test = issue14014_3_test;
});
