dart_library.library('language/bailout7_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bailout7_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bailout7_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  bailout7_test.global = null;
  bailout7_test.A = class A extends core.Object {
    new() {
      this.array = null;
    }
    initArray() {
      if (dart.dindex(bailout7_test.global, 0) == null) {
        return JSArrayOfint().of([2]);
      } else {
        let map = core.Map.new();
        map[dartx.set](0, 2);
        return map;
      }
    }
    bar() {
      this.array = this.initArray();
      let element = null;
      do {
        element = dart.dindex(this.array, 0);
        if (core.Map.is(element)) continue;
        if (element == null) break;
      } while (!dart.equals(element, 2));
      return dart.dindex(bailout7_test.global, 0);
    }
  };
  dart.setSignature(bailout7_test.A, {
    methods: () => ({
      initArray: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  bailout7_test.main = function() {
    bailout7_test.global = JSArrayOfint().of([2]);
    for (let i = 0; i < 2; i++) {
      expect$.Expect.equals(2, new bailout7_test.A().bar());
    }
    bailout7_test.global = core.Map.new();
    dart.dsetindex(bailout7_test.global, 0, 2);
    for (let i = 0; i < 2; i++) {
      expect$.Expect.equals(2, new bailout7_test.A().bar());
    }
  };
  dart.fn(bailout7_test.main, VoidTovoid());
  // Exports:
  exports.bailout7_test = bailout7_test;
});
