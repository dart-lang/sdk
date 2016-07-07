dart_library.library('language/namer2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__namer2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const namer2_test = Object.create(null);
  let A = () => (A = dart.constFn(namer2_test.A$()))();
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(namer2_test.A)))();
  let AOfint = () => (AOfint = dart.constFn(namer2_test.A$(core.int)))();
  let AOfString = () => (AOfString = dart.constFn(namer2_test.A$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  namer2_test.A$ = dart.generic(T => {
    class A extends core.Object {
      new() {
        this.$isA = null;
        this.$eq = null;
        this.$builtinTypeInfo = null;
      }
    }
    dart.addTypeTests(A);
    return A;
  });
  namer2_test.A = A();
  namer2_test.main = function() {
    let c = JSArrayOfA().of([new namer2_test.A()]);
    expect$.Expect.isTrue(namer2_test.A.is(c[dartx.get](0)));
    expect$.Expect.isTrue(dart.equals(c[dartx.get](0), c[dartx.get](0)));
    c = JSArrayOfA().of([new (AOfint())()]);
    c[dartx.get](0).$builtinTypeInfo = 42;
    expect$.Expect.isTrue(!AOfString().is(c[dartx.get](0)));
  };
  dart.fn(namer2_test.main, VoidTodynamic());
  // Exports:
  exports.namer2_test = namer2_test;
});
