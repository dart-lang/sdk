dart_library.library('language/for_in2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__for_in2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const for_in2_test = Object.create(null);
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  dart.defineLazy(for_in2_test, {
    get set() {
      return SetOfint().from(JSArrayOfint().of([1, 2]));
    },
    set set(_) {}
  });
  for_in2_test.x = null;
  for_in2_test.A = class A extends core.Object {
    new() {
      this.field = null;
    }
    test() {
      let count = 0;
      for (/* Unimplemented unknown name */field of for_in2_test.set) {
        count = dart.notNull(count) + dart.notNull(core.int._check(this.field));
      }
      expect$.Expect.equals(3, count);
      count = 0;
      for (/* Unimplemented unknown name */x of for_in2_test.set) {
        count = dart.notNull(count) + dart.notNull(core.int._check(for_in2_test.x));
      }
      expect$.Expect.equals(3, count);
    }
  };
  dart.setSignature(for_in2_test.A, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  for_in2_test.main = function() {
    new for_in2_test.A().test();
  };
  dart.fn(for_in2_test.main, VoidTovoid());
  // Exports:
  exports.for_in2_test = for_in2_test;
});
