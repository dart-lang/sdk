dart_library.library('language/factory_redirection2_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__factory_redirection2_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const factory_redirection2_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  factory_redirection2_test_none_multi.Foo = class Foo extends core.Object {
    new() {
    }
  };
  dart.setSignature(factory_redirection2_test_none_multi.Foo, {
    constructors: () => ({new: dart.definiteFunctionType(factory_redirection2_test_none_multi.Foo, [])})
  });
  factory_redirection2_test_none_multi.Bar = class Bar extends factory_redirection2_test_none_multi.Foo {
    static new() {
      return null;
    }
  };
  dart.setSignature(factory_redirection2_test_none_multi.Bar, {
    constructors: () => ({new: dart.definiteFunctionType(factory_redirection2_test_none_multi.Bar, [])})
  });
  factory_redirection2_test_none_multi.main = function() {
    expect$.Expect.isTrue(factory_redirection2_test_none_multi.Foo.is(new factory_redirection2_test_none_multi.Foo()));
    expect$.Expect.isFalse(factory_redirection2_test_none_multi.Bar.is(new factory_redirection2_test_none_multi.Foo()));
  };
  dart.fn(factory_redirection2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.factory_redirection2_test_none_multi = factory_redirection2_test_none_multi;
});
