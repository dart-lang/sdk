dart_library.library('language/override_method_with_field_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__override_method_with_field_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const override_method_with_field_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  override_method_with_field_test_none_multi.Super = class Super extends core.Object {
    new() {
    }
    instanceMethod() {
      return 42;
    }
  };
  dart.setSignature(override_method_with_field_test_none_multi.Super, {
    constructors: () => ({new: dart.definiteFunctionType(override_method_with_field_test_none_multi.Super, [])}),
    methods: () => ({instanceMethod: dart.definiteFunctionType(dart.dynamic, [])})
  });
  override_method_with_field_test_none_multi.Sub = class Sub extends override_method_with_field_test_none_multi.Super {
    new() {
      super.new();
    }
    superInstanceMethod() {
      return super.instanceMethod();
    }
  };
  dart.setSignature(override_method_with_field_test_none_multi.Sub, {
    constructors: () => ({new: dart.definiteFunctionType(override_method_with_field_test_none_multi.Sub, [])}),
    methods: () => ({superInstanceMethod: dart.definiteFunctionType(dart.dynamic, [])})
  });
  override_method_with_field_test_none_multi.main = function() {
    let s = new override_method_with_field_test_none_multi.Sub();
    let sup = s;
    let sub = s;
    core.print(dart.bind(s, 'instanceMethod'));
    expect$.Expect.equals(42, s.superInstanceMethod());
    expect$.Expect.equals(42, sub.superInstanceMethod());
  };
  dart.fn(override_method_with_field_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.override_method_with_field_test_none_multi = override_method_with_field_test_none_multi;
});
