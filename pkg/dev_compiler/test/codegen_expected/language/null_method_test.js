dart_library.library('language/null_method_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null_method_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null_method_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  null_method_test.C = class C extends core.Object {
    foo(s) {
      return dart.hashCode(s);
    }
  };
  dart.setSignature(null_method_test.C, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  null_method_test.main = function() {
    let c = new null_method_test.C();
    expect$.Expect.isNotNull(c.foo('foo'));
    expect$.Expect.isNotNull(c.foo(null));
  };
  dart.fn(null_method_test.main, VoidTodynamic());
  // Exports:
  exports.null_method_test = null_method_test;
});
