dart_library.library('language/bailout2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bailout2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bailout2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  bailout2_test.a = null;
  bailout2_test.main = function() {
    for (let i = 0; i < 10; i++) {
      if (bailout2_test.a != null) new bailout2_test.A().foo([]);
      expect$.Expect.equals(42, new bailout2_test.A().foo(new bailout2_test.A()));
    }
  };
  dart.fn(bailout2_test.main, VoidTodynamic());
  bailout2_test.A = class A extends core.Object {
    foo(a) {
      return dart.dindex(a, dart.dload(a, 'length'));
    }
    get length() {
      return 42;
    }
    get(index) {
      return 42;
    }
  };
  dart.setSignature(bailout2_test.A, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  // Exports:
  exports.bailout2_test = bailout2_test;
});
