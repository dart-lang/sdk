dart_library.library('language/closure_with_super_send_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_with_super_send_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_with_super_send_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_with_super_send_test.Super = class Super extends core.Object {
    m() {
      return "super";
    }
  };
  dart.setSignature(closure_with_super_send_test.Super, {
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [])})
  });
  closure_with_super_send_test.Sub = class Sub extends closure_with_super_send_test.Super {
    m() {
      return "sub";
    }
    test() {
      let x = null;
      JSArrayOfint().of([0])[dartx.forEach](dart.fn(e => x = super.m(), intTovoid()));
      return x;
    }
  };
  dart.setSignature(closure_with_super_send_test.Sub, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  closure_with_super_send_test.main = function() {
    expect$.Expect.equals("super", new closure_with_super_send_test.Sub().test());
    expect$.Expect.equals("super", new closure_with_super_send_test.Super().m());
    expect$.Expect.equals("sub", new closure_with_super_send_test.Sub().m());
  };
  dart.fn(closure_with_super_send_test.main, VoidTodynamic());
  // Exports:
  exports.closure_with_super_send_test = closure_with_super_send_test;
});
