dart_library.library('language/bailout4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bailout4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bailout4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  bailout4_test.A = class A extends core.Object {
    get(index) {
      return 42;
    }
  };
  dart.setSignature(bailout4_test.A, {
    methods: () => ({get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  dart.defineLazy(bailout4_test, {
    get a() {
      return new bailout4_test.A();
    },
    set a(_) {}
  });
  dart.defineLazy(bailout4_test, {
    get b() {
      return core.List.new(4);
    },
    set b(_) {}
  });
  bailout4_test.count = 0;
  bailout4_test.main = function() {
    if (bailout4_test.b[dartx.get](0) != null) bailout4_test.main();
    for (let i = 0; i < 2; i++) {
      for (let j = 0; j < 2; j++) {
        for (let k = 0; k < 2; k++) {
          expect$.Expect.equals(42, bailout4_test.a.get(i + j + k));
          bailout4_test.count = dart.notNull(bailout4_test.count) + 1;
        }
      }
    }
    expect$.Expect.equals(8, bailout4_test.count);
  };
  dart.fn(bailout4_test.main, VoidTodynamic());
  // Exports:
  exports.bailout4_test = bailout4_test;
});
