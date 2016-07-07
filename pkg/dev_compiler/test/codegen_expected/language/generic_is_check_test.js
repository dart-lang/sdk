dart_library.library('language/generic_is_check_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_is_check_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_is_check_test = Object.create(null);
  let AOfint = () => (AOfint = dart.constFn(generic_is_check_test.A$(core.int)))();
  let A = () => (A = dart.constFn(generic_is_check_test.A$()))();
  let AOfString = () => (AOfString = dart.constFn(generic_is_check_test.A$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_is_check_test.A$ = dart.generic(T => {
    class A extends core.Object {
      foo() {
        return AOfint().is(this);
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return A;
  });
  generic_is_check_test.A = A();
  generic_is_check_test.main = function() {
    expect$.Expect.isTrue(new generic_is_check_test.A().foo());
    expect$.Expect.isTrue(new (AOfint())().foo());
    expect$.Expect.isFalse(new (AOfString())().foo());
  };
  dart.fn(generic_is_check_test.main, VoidTodynamic());
  // Exports:
  exports.generic_is_check_test = generic_is_check_test;
});
