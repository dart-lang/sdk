dart_library.library('language/exception_in_increment_test', null, /* Imports */[
  'dart_sdk'
], function load__exception_in_increment_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const exception_in_increment_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  exception_in_increment_test.main = function() {
    let a = new exception_in_increment_test.A();
    a.field = new exception_in_increment_test.A();
    for (let i = 0; i < 20; i++) {
      try {
        a.foo(i);
      } catch (e) {
      }

    }
  };
  dart.fn(exception_in_increment_test.main, VoidTodynamic());
  exception_in_increment_test.A = class A extends core.Object {
    new() {
      this.field = null;
    }
    foo(i) {
      this.field = dart.dsend(this.field, '+', 1);
    }
  };
  dart.setSignature(exception_in_increment_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  // Exports:
  exports.exception_in_increment_test = exception_in_increment_test;
});
