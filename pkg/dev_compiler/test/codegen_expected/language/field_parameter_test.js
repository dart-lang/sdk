dart_library.library('language/field_parameter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__field_parameter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const field_parameter_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  field_parameter_test.A = class A extends core.Object {
    new(x) {
      this.x = x;
    }
    named(x) {
      if (x === void 0) x = null;
      this.x = x;
    }
    named2(x) {
      if (x === void 0) x = 2;
      this.x = x;
    }
    named3() {
      this.x = 4;
    }
  };
  dart.defineNamedConstructor(field_parameter_test.A, 'named');
  dart.defineNamedConstructor(field_parameter_test.A, 'named2');
  dart.defineNamedConstructor(field_parameter_test.A, 'named3');
  dart.setSignature(field_parameter_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(field_parameter_test.A, [core.int]),
      named: dart.definiteFunctionType(field_parameter_test.A, [], [core.int]),
      named2: dart.definiteFunctionType(field_parameter_test.A, [], [core.int]),
      named3: dart.definiteFunctionType(field_parameter_test.A, [])
    })
  });
  field_parameter_test.B = class B extends field_parameter_test.A {
    new(x) {
      super.new(core.int._check(dart.dsend(x, '+', 10)));
    }
    named_() {
      super.named();
    }
    named(x) {
      super.named(core.int._check(dart.dsend(x, '+', 10)));
    }
    named2_() {
      super.named2();
    }
    named2(x) {
      super.named2(core.int._check(dart.dsend(x, '+', 10)));
    }
    named3() {
      super.named3();
    }
  };
  dart.defineNamedConstructor(field_parameter_test.B, 'named_');
  dart.defineNamedConstructor(field_parameter_test.B, 'named');
  dart.defineNamedConstructor(field_parameter_test.B, 'named2_');
  dart.defineNamedConstructor(field_parameter_test.B, 'named2');
  dart.defineNamedConstructor(field_parameter_test.B, 'named3');
  dart.setSignature(field_parameter_test.B, {
    constructors: () => ({
      new: dart.definiteFunctionType(field_parameter_test.B, [dart.dynamic]),
      named_: dart.definiteFunctionType(field_parameter_test.B, []),
      named: dart.definiteFunctionType(field_parameter_test.B, [dart.dynamic]),
      named2_: dart.definiteFunctionType(field_parameter_test.B, []),
      named2: dart.definiteFunctionType(field_parameter_test.B, [dart.dynamic]),
      named3: dart.definiteFunctionType(field_parameter_test.B, [])
    })
  });
  field_parameter_test.main = function() {
    expect$.Expect.equals(0, new field_parameter_test.A(0).x);
    expect$.Expect.equals(null, new field_parameter_test.A.named().x);
    expect$.Expect.equals(1, new field_parameter_test.A.named(1).x);
    expect$.Expect.equals(2, new field_parameter_test.A.named2().x);
    expect$.Expect.equals(3, new field_parameter_test.A.named2(3).x);
    expect$.Expect.equals(4, new field_parameter_test.A.named3().x);
    expect$.Expect.equals(10, new field_parameter_test.B(0).x);
    expect$.Expect.equals(null, new field_parameter_test.B.named_().x);
    expect$.Expect.equals(11, new field_parameter_test.B.named(1).x);
    expect$.Expect.equals(2, new field_parameter_test.B.named2_().x);
    expect$.Expect.equals(13, new field_parameter_test.B.named2(3).x);
    expect$.Expect.equals(4, new field_parameter_test.B.named3().x);
  };
  dart.fn(field_parameter_test.main, VoidTodynamic());
  // Exports:
  exports.field_parameter_test = field_parameter_test;
});
