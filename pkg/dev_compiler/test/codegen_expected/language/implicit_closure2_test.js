dart_library.library('language/implicit_closure2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__implicit_closure2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const implicit_closure2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  implicit_closure2_test.B = class B extends core.Object {
    foo(i) {
      return 499 + dart.notNull(core.num._check(i));
    }
  };
  dart.setSignature(implicit_closure2_test.B, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  implicit_closure2_test.A = class A extends core.Object {
    new() {
      this.b = new implicit_closure2_test.B();
    }
    foo(i) {
      return dart.fn(() => dart.dsend(this.b, 'foo', i), VoidTodynamic())();
    }
  };
  dart.setSignature(implicit_closure2_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(implicit_closure2_test.A, [])}),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  implicit_closure2_test.main = function() {
    let a = new implicit_closure2_test.A();
    expect$.Expect.equals(510, a.foo(11));
    let f = dart.bind(a, 'foo');
    expect$.Expect.equals(521, dart.dcall(f, 22));
  };
  dart.fn(implicit_closure2_test.main, VoidTodynamic());
  // Exports:
  exports.implicit_closure2_test = implicit_closure2_test;
});
