dart_library.library('language/external_test_13_multi', null, /* Imports */[
  'dart_sdk'
], function load__external_test_13_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const external_test_13_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  external_test_13_multi.Bar = class Bar extends core.Object {
    new(val) {
    }
  };
  dart.setSignature(external_test_13_multi.Bar, {
    constructors: () => ({new: dart.definiteFunctionType(external_test_13_multi.Bar, [dart.dynamic])})
  });
  external_test_13_multi.Foo = class Foo extends core.Object {
    f() {}
    new() {
      this.x = 0;
    }
  };
  dart.setSignature(external_test_13_multi.Foo, {
    constructors: () => ({new: dart.definiteFunctionType(external_test_13_multi.Foo, [])}),
    methods: () => ({f: dart.definiteFunctionType(dart.dynamic, [])}),
    statics: () => ({f13: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['f13']
  });
  external_test_13_multi.main = function() {
    let foo = new external_test_13_multi.Foo();
    external_test_13_multi.Foo.f13();
  };
  dart.fn(external_test_13_multi.main, VoidTodynamic());
  // Exports:
  exports.external_test_13_multi = external_test_13_multi;
});
