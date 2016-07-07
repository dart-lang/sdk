dart_library.library('language/final_field_override_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__final_field_override_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const final_field_override_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const _x = Symbol('_x');
  final_field_override_test.A = class A extends core.Object {
    new() {
      this[_x] = 42;
    }
    set x(val) {
      this[_x] = val;
    }
    get x() {
      return this[_x];
    }
  };
  final_field_override_test.B = class B extends final_field_override_test.A {
    new() {
      this[x] = 3;
      super.new();
    }
    get x() {
      return this[x];
    }
    set x(value) {
      super.x = value;
    }
    get y() {
      return this[_x];
    }
  };
  const x = Symbol(final_field_override_test.B.name + "." + 'x'.toString());
  final_field_override_test.main = function() {
    let b = new final_field_override_test.B();
    expect$.Expect.equals(3, b.x);
    b.x = 21;
    expect$.Expect.equals(3, b.x);
    expect$.Expect.equals(21, b.y);
  };
  dart.fn(final_field_override_test.main, VoidTovoid());
  // Exports:
  exports.final_field_override_test = final_field_override_test;
});
