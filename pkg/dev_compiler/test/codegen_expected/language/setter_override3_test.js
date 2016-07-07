dart_library.library('language/setter_override3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__setter_override3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const setter_override3_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const _x = Symbol('_x');
  setter_override3_test.A = class A extends core.Object {
    new() {
      this[_x] = 42;
    }
    get x() {
      return this[_x];
    }
  };
  setter_override3_test.B = class B extends setter_override3_test.A {
    new() {
      super.new();
    }
    set x(val) {
      this[_x] = val;
    }
    get x() {
      return super.x;
    }
  };
  setter_override3_test.main = function() {
    let b = new setter_override3_test.B();
    expect$.Expect.equals(42, b.x);
    b.x = 21;
    expect$.Expect.equals(21, b.x);
  };
  dart.fn(setter_override3_test.main, VoidTovoid());
  // Exports:
  exports.setter_override3_test = setter_override3_test;
});
