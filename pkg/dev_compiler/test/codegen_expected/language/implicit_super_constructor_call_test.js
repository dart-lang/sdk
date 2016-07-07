dart_library.library('language/implicit_super_constructor_call_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__implicit_super_constructor_call_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const implicit_super_constructor_call_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  implicit_super_constructor_call_test.A = class A extends core.Object {
    new(opts) {
      let x = opts && 'x' in opts ? opts.x : "foo";
      this.x = x;
      expect$.Expect.equals("foo", dart.toString(this.x));
    }
  };
  dart.setSignature(implicit_super_constructor_call_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(implicit_super_constructor_call_test.A, [], {x: dart.dynamic})})
  });
  implicit_super_constructor_call_test.C = class C extends implicit_super_constructor_call_test.A {
    new(foobar) {
      super.new();
    }
  };
  dart.setSignature(implicit_super_constructor_call_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(implicit_super_constructor_call_test.C, [dart.dynamic])})
  });
  implicit_super_constructor_call_test.main = function() {
    let c = new implicit_super_constructor_call_test.C(499);
    expect$.Expect.equals("foo", dart.toString(c.x));
  };
  dart.fn(implicit_super_constructor_call_test.main, VoidTodynamic());
  // Exports:
  exports.implicit_super_constructor_call_test = implicit_super_constructor_call_test;
});
