dart_library.library('language/external_test_21_multi', null, /* Imports */[
  'dart_sdk'
], function load__external_test_21_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const external_test_21_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  external_test_21_multi.Bar = class Bar extends core.Object {
    new(val) {
    }
  };
  dart.setSignature(external_test_21_multi.Bar, {
    constructors: () => ({new: dart.definiteFunctionType(external_test_21_multi.Bar, [dart.dynamic])})
  });
  external_test_21_multi.Foo = class Foo extends core.Object {
    f() {}
    new() {
      this.x = 0;
    }
  };
  dart.defineNamedConstructor(external_test_21_multi.Foo, 'n21');
  dart.setSignature(external_test_21_multi.Foo, {
    constructors: () => ({
      new: dart.definiteFunctionType(external_test_21_multi.Foo, []),
      n21: dart.definiteFunctionType(external_test_21_multi.Foo, [dart.dynamic])
    }),
    methods: () => ({f: dart.definiteFunctionType(dart.dynamic, [])})
  });
  external_test_21_multi.main = function() {
    let foo = new external_test_21_multi.Foo();
    new external_test_21_multi.Foo.n21(1);
  };
  dart.fn(external_test_21_multi.main, VoidTodynamic());
  // Exports:
  exports.external_test_21_multi = external_test_21_multi;
});
