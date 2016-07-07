dart_library.library('language/bailout5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bailout5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bailout5_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  bailout5_test.global = null;
  bailout5_test.A = class A extends core.Object {
    new() {
      this.array = null;
    }
    initArray() {
      return dart.dindex(bailout5_test.global, 0) == null ? [null] : core.Map.new();
    }
    bar() {
      this.array = this.initArray();
      do {
        let element = dart.dindex(this.array, 0);
        if (core.Map.is(element)) continue;
        if (element == null) break;
      } while (true);
      return dart.dindex(bailout5_test.global, 0);
    }
    baz() {
      do {
        let element = this.bar();
        if (element == null) return dart.dindex(bailout5_test.global, 0);
        if (core.Map.is(element)) continue;
        if (typeof element == 'number') break;
      } while (true);
      return dart.dindex(bailout5_test.global, 0);
    }
  };
  dart.setSignature(bailout5_test.A, {
    methods: () => ({
      initArray: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, []),
      baz: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  bailout5_test.main = function() {
    bailout5_test.global = JSArrayOfint().of([1]);
    for (let i = 0; i < 2; i++) {
      expect$.Expect.equals(1, new bailout5_test.A().baz());
      expect$.Expect.equals(1, new bailout5_test.A().bar());
    }
    bailout5_test.global = core.Map.new();
    for (let i = 0; i < 2; i++) {
      expect$.Expect.equals(null, new bailout5_test.A().baz());
      expect$.Expect.equals(null, new bailout5_test.A().bar());
    }
    dart.dsetindex(bailout5_test.global, 0, 42);
    for (let i = 0; i < 2; i++) {
      expect$.Expect.equals(42, new bailout5_test.A().baz());
      expect$.Expect.equals(42, new bailout5_test.A().bar());
    }
  };
  dart.fn(bailout5_test.main, VoidTovoid());
  // Exports:
  exports.bailout5_test = bailout5_test;
});
