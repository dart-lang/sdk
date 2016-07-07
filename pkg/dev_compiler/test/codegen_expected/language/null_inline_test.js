dart_library.library('language/null_inline_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null_inline_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null_inline_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  null_inline_test.A = class A extends core.Object {
    foo() {
      return this;
    }
  };
  dart.setSignature(null_inline_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  null_inline_test.global = null;
  null_inline_test.main = function() {
    expect$.Expect.throws(dart.fn(() => dart.dsend(null_inline_test.global, 'foo'), VoidTovoid()));
    null_inline_test.global = new null_inline_test.A();
    expect$.Expect.equals(null_inline_test.global, dart.dsend(null_inline_test.global, 'foo'));
  };
  dart.fn(null_inline_test.main, VoidTodynamic());
  // Exports:
  exports.null_inline_test = null_inline_test;
});
