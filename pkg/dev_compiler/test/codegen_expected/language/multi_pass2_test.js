dart_library.library('language/multi_pass2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__multi_pass2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const multi_pass2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  multi_pass2_test.Base = class Base extends core.Object {
    new(value) {
      this.value = value;
    }
  };
  dart.setSignature(multi_pass2_test.Base, {
    constructors: () => ({new: dart.definiteFunctionType(multi_pass2_test.Base, [dart.dynamic])})
  });
  multi_pass2_test.MultiPass2Test = class MultiPass2Test extends core.Object {
    static testMain() {
      let a = new multi_pass2_test.B(5);
      expect$.Expect.equals(5, a.value);
    }
  };
  dart.setSignature(multi_pass2_test.MultiPass2Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  multi_pass2_test.main = function() {
    multi_pass2_test.MultiPass2Test.testMain();
  };
  dart.fn(multi_pass2_test.main, VoidTodynamic());
  multi_pass2_test.A = class A extends multi_pass2_test.Base {
    new(v) {
      super.new(v);
    }
  };
  dart.setSignature(multi_pass2_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(multi_pass2_test.A, [dart.dynamic])})
  });
  multi_pass2_test.B = class B extends multi_pass2_test.A {
    new(v) {
      super.new(v);
    }
  };
  dart.setSignature(multi_pass2_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(multi_pass2_test.B, [dart.dynamic])})
  });
  // Exports:
  exports.multi_pass2_test = multi_pass2_test;
});
