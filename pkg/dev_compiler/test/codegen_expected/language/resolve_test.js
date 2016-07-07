dart_library.library('language/resolve_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__resolve_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const resolve_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  resolve_test.A = class A extends core.Object {
    static staticCall() {
      return 4;
    }
    dynamicCall() {
      return 5;
    }
    ovrDynamicCall() {
      return 6;
    }
  };
  dart.setSignature(resolve_test.A, {
    methods: () => ({
      dynamicCall: dart.definiteFunctionType(dart.dynamic, []),
      ovrDynamicCall: dart.definiteFunctionType(dart.dynamic, [])
    }),
    statics: () => ({staticCall: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['staticCall']
  });
  resolve_test.B = class B extends resolve_test.A {
    ovrDynamicCall() {
      return -6;
    }
  };
  resolve_test.ResolveTest = class ResolveTest extends core.Object {
    static testMain() {
      let b = new resolve_test.B();
      expect$.Expect.equals(3, dart.dsend(dart.dsend(b.dynamicCall(), '+', resolve_test.A.staticCall()), '+', b.ovrDynamicCall()));
    }
  };
  dart.setSignature(resolve_test.ResolveTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  resolve_test.main = function() {
    resolve_test.ResolveTest.testMain();
  };
  dart.fn(resolve_test.main, VoidTodynamic());
  // Exports:
  exports.resolve_test = resolve_test;
});
