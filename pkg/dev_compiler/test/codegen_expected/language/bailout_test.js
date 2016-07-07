dart_library.library('language/bailout_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bailout_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bailout_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(bailout_test, {
    get reachedAfoo() {
      return new bailout_test.C();
    },
    set reachedAfoo(_) {}
  });
  bailout_test.A = class A extends core.Object {
    foo() {
      bailout_test.reachedAfoo = bailout_test.reachedAfoo['+'](1);
    }
  };
  dart.setSignature(bailout_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  bailout_test.B = class B extends bailout_test.A {
    foo() {
      bailout_test.reachedAfoo = bailout_test.reachedAfoo['+'](1);
      expect$.Expect.fail('Should never reach B.foo');
    }
    bar() {
      super.foo();
    }
  };
  dart.setSignature(bailout_test.B, {
    methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [])})
  });
  bailout_test.C = class C extends core.Object {
    new() {
      this.value = 0;
    }
    ['+'](val) {
      this.value = dart.notNull(this.value) + dart.notNull(core.int._check(val));
      return this;
    }
  };
  dart.setSignature(bailout_test.C, {
    methods: () => ({'+': dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  bailout_test.main = function() {
    while (bailout_test.reachedAfoo.value != 0) {
      new bailout_test.A().foo();
      new bailout_test.B().foo();
    }
    new bailout_test.B().bar();
    expect$.Expect.equals(1, bailout_test.reachedAfoo.value);
  };
  dart.fn(bailout_test.main, VoidTodynamic());
  // Exports:
  exports.bailout_test = bailout_test;
});
