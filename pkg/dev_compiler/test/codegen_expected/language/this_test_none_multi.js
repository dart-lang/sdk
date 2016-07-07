dart_library.library('language/this_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__this_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const this_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  this_test_none_multi.Foo = class Foo extends core.Object {
    new() {
      this.x = null;
    }
    f() {}
    testMe() {}
  };
  dart.setSignature(this_test_none_multi.Foo, {
    methods: () => ({
      f: dart.definiteFunctionType(dart.dynamic, []),
      testMe: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  this_test_none_multi.main = function() {
    new this_test_none_multi.Foo().testMe();
  };
  dart.fn(this_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.this_test_none_multi = this_test_none_multi;
});
