dart_library.library('language/library1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__library1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const library1_test = Object.create(null);
  const library1_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  library1_test.main = function() {
    library1_test.Library1Test.testMain();
  };
  dart.fn(library1_test.main, VoidTodynamic());
  library1_test.Library1Test = class Library1Test extends core.Object {
    static testMain() {
      let a = new library1_lib.A();
      let s = a.foo();
      expect$.Expect.equals(s, "foo-rty two");
    }
  };
  dart.setSignature(library1_test.Library1Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  library1_lib.A = class A extends core.Object {
    new() {
    }
    foo() {
      return "foo-rty two";
    }
  };
  dart.setSignature(library1_lib.A, {
    constructors: () => ({new: dart.definiteFunctionType(library1_lib.A, [])}),
    methods: () => ({foo: dart.definiteFunctionType(core.String, [])})
  });
  // Exports:
  exports.library1_test = library1_test;
  exports.library1_lib = library1_lib;
});
