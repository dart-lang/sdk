dart_library.library('language/private_selector_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__private_selector_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const private_selector_test = Object.create(null);
  const private_selector_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _private = Symbol('_private');
  private_selector_lib.A = class A extends core.Object {
    public() {
      new private_selector_test.B()[_private]();
    }
    [_private]() {
      private_selector_lib.executed = true;
    }
  };
  dart.setSignature(private_selector_lib.A, {
    methods: () => ({
      public: dart.definiteFunctionType(dart.dynamic, []),
      [_private]: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  private_selector_test.B = class B extends private_selector_lib.A {};
  private_selector_test.main = function() {
    new private_selector_lib.A().public();
    expect$.Expect.isTrue(private_selector_lib.executed);
  };
  dart.fn(private_selector_test.main, VoidTodynamic());
  private_selector_lib.executed = false;
  // Exports:
  exports.private_selector_test = private_selector_test;
  exports.private_selector_lib = private_selector_lib;
});
