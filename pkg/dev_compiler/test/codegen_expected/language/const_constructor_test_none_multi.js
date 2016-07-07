dart_library.library('language/const_constructor_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_constructor_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_constructor_test_none_multi = Object.create(null);
  let A = () => (A = dart.constFn(const_constructor_test_none_multi.A$()))();
  let AOfint = () => (AOfint = dart.constFn(const_constructor_test_none_multi.A$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_constructor_test_none_multi.A$ = dart.generic(T => {
    class A extends core.Object {
      named() {
        this.x = 42;
      }
      new() {
        this.x = null;
      }
    }
    dart.addTypeTests(A);
    dart.defineNamedConstructor(A, 'named');
    dart.setSignature(A, {
      constructors: () => ({
        named: dart.definiteFunctionType(const_constructor_test_none_multi.A$(T), []),
        new: dart.definiteFunctionType(const_constructor_test_none_multi.A$(T), [])
      })
    });
    return A;
  });
  const_constructor_test_none_multi.A = A();
  let const$;
  const_constructor_test_none_multi.main = function() {
    expect$.Expect.equals(42, (const$ || (const$ = dart.const(new (AOfint()).named()))).x);
    expect$.Expect.equals(42, new (AOfint()).named().x);
  };
  dart.fn(const_constructor_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.const_constructor_test_none_multi = const_constructor_test_none_multi;
});
