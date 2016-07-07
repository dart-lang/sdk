dart_library.library('language/factory_arrow_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__factory_arrow_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const factory_arrow_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  factory_arrow_test.A = class A extends core.Object {
    foo() {
    }
    static new() {
      return new factory_arrow_test.A.foo();
    }
  };
  dart.defineNamedConstructor(factory_arrow_test.A, 'foo');
  dart.setSignature(factory_arrow_test.A, {
    constructors: () => ({
      foo: dart.definiteFunctionType(factory_arrow_test.A, []),
      new: dart.definiteFunctionType(factory_arrow_test.A, [])
    })
  });
  factory_arrow_test.main = function() {
    expect$.Expect.isTrue(factory_arrow_test.A.is(factory_arrow_test.A.new()));
  };
  dart.fn(factory_arrow_test.main, VoidTodynamic());
  // Exports:
  exports.factory_arrow_test = factory_arrow_test;
});
