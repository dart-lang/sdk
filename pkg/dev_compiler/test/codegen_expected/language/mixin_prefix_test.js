dart_library.library('language/mixin_prefix_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_prefix_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_prefix_test = Object.create(null);
  const mixin_prefix_lib = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  mixin_prefix_lib.MixinClass = class MixinClass extends core.Object {
    bar() {
      return convert.JSON.encode(dart.map({a: 1}));
    }
  };
  dart.setSignature(mixin_prefix_lib.MixinClass, {
    methods: () => ({bar: dart.definiteFunctionType(core.String, [])})
  });
  mixin_prefix_test.A = class A extends dart.mixin(core.Object, mixin_prefix_lib.MixinClass) {
    baz() {
      return this.bar();
    }
  };
  dart.setSignature(mixin_prefix_test.A, {
    methods: () => ({baz: dart.definiteFunctionType(core.String, [])})
  });
  mixin_prefix_test.main = function() {
    let a = new mixin_prefix_test.A();
    expect$.Expect.equals('{"a":1}', a.baz());
  };
  dart.fn(mixin_prefix_test.main, VoidTovoid());
  // Exports:
  exports.mixin_prefix_test = mixin_prefix_test;
  exports.mixin_prefix_lib = mixin_prefix_lib;
});
