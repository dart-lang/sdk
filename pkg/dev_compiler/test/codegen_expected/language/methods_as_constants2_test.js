dart_library.library('language/methods_as_constants2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__methods_as_constants2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const methods_as_constants2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  methods_as_constants2_test.topLevelMethod = function() {
    return 42;
  };
  dart.fn(methods_as_constants2_test.topLevelMethod, VoidTodynamic());
  methods_as_constants2_test.A = class A extends core.Object {
    new(f) {
      this.f = f;
    }
  };
  dart.setSignature(methods_as_constants2_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(methods_as_constants2_test.A, [core.Function])})
  });
  let const$;
  methods_as_constants2_test.main = function() {
    expect$.Expect.equals(42, dart.dsend(const$ || (const$ = dart.const(new methods_as_constants2_test.A(methods_as_constants2_test.topLevelMethod))), 'f'));
  };
  dart.fn(methods_as_constants2_test.main, VoidTodynamic());
  // Exports:
  exports.methods_as_constants2_test = methods_as_constants2_test;
});
