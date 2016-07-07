dart_library.library('language/getter_override3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__getter_override3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const getter_override3_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const _x = Symbol('_x');
  getter_override3_test.A = class A extends core.Object {
    new() {
      this[_x] = 42;
    }
    set x(val) {
      this[_x] = val;
    }
  };
  getter_override3_test.B = class B extends getter_override3_test.A {
    new() {
      super.new();
    }
    get x() {
      return this[_x];
    }
    set x(value) {
      super.x = value;
    }
  };
  getter_override3_test.main = function() {
    let b = new getter_override3_test.B();
    expect$.Expect.equals(42, b.x);
    b.x = 21;
    expect$.Expect.equals(21, b.x);
  };
  dart.fn(getter_override3_test.main, VoidTovoid());
  // Exports:
  exports.getter_override3_test = getter_override3_test;
});
