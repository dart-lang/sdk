dart_library.library('language/external_test_10_multi', null, /* Imports */[
  'dart_sdk'
], function load__external_test_10_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const external_test_10_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  external_test_10_multi.Bar = class Bar extends core.Object {
    new(val) {
    }
  };
  dart.setSignature(external_test_10_multi.Bar, {
    constructors: () => ({new: dart.definiteFunctionType(external_test_10_multi.Bar, [dart.dynamic])})
  });
  external_test_10_multi.Foo = class Foo extends core.Object {
    f() {}
    new() {
      this.x = 0;
    }
    f10() {
      return this.f10();
    }
  };
  dart.setSignature(external_test_10_multi.Foo, {
    constructors: () => ({new: dart.definiteFunctionType(external_test_10_multi.Foo, [])}),
    methods: () => ({
      f: dart.definiteFunctionType(dart.dynamic, []),
      f10: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  external_test_10_multi.main = function() {
    let foo = new external_test_10_multi.Foo();
    new external_test_10_multi.Foo().f10();
  };
  dart.fn(external_test_10_multi.main, VoidTodynamic());
  // Exports:
  exports.external_test_10_multi = external_test_10_multi;
});
