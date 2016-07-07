dart_library.library('language/field_optimization_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__field_optimization_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const field_optimization_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  field_optimization_test.A = class A extends core.Object {
    new() {
      this.x = 0;
    }
    foo() {
      this.x = dart.dsend(this.x, '+', 1);
    }
    toto() {
      this.x = 99;
    }
    bar(y) {
      this.x = y;
    }
  };
  dart.setSignature(field_optimization_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(field_optimization_test.A, [])}),
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      toto: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])
    })
  });
  field_optimization_test.B = class B extends core.Object {
    ['+'](other) {
      return "ok";
    }
  };
  dart.setSignature(field_optimization_test.B, {
    methods: () => ({'+': dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  field_optimization_test.main = function() {
    let a = new field_optimization_test.A();
    a.foo();
    a.toto();
    a.bar("str");
    a.bar(new field_optimization_test.B());
    a.foo();
    expect$.Expect.equals("ok", a.x);
  };
  dart.fn(field_optimization_test.main, VoidTodynamic());
  // Exports:
  exports.field_optimization_test = field_optimization_test;
});
