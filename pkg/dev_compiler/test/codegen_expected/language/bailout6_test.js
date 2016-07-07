dart_library.library('language/bailout6_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bailout6_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bailout6_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  bailout6_test.global = null;
  bailout6_test.A = class A extends core.Object {
    new() {
      this.array = null;
    }
    foo() {
      do {
        let element = bailout6_test.global;
        if (core.Map.is(element)) continue;
        if (typeof element == 'number') break;
      } while (true);
      return dart.dindex(this.array, 0);
    }
  };
  dart.setSignature(bailout6_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  bailout6_test.main = function() {
    let a = new bailout6_test.A();
    a.array = JSArrayOfint().of([42]);
    bailout6_test.global = 42;
    for (let i = 0; i < 2; i++) {
      expect$.Expect.equals(42, a.foo());
    }
    a.array = core.Map.new();
    dart.dsetindex(a.array, 0, 42);
    for (let i = 0; i < 2; i++) {
      expect$.Expect.equals(42, a.foo());
    }
    bailout6_test.global = null;
  };
  dart.fn(bailout6_test.main, VoidTovoid());
  // Exports:
  exports.bailout6_test = bailout6_test;
});
