dart_library.library('language/crash_12118_test', null, /* Imports */[
  'dart_sdk'
], function load__crash_12118_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const crash_12118_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  crash_12118_test.X = 42;
  crash_12118_test.A = class A extends core.Object {
    new(opts) {
      let x = opts && 'x' in opts ? opts.x : crash_12118_test.X;
      this.x = x;
    }
  };
  dart.setSignature(crash_12118_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(crash_12118_test.A, [], {x: dart.dynamic})})
  });
  crash_12118_test.B = class B extends crash_12118_test.A {
    new() {
      super.new();
    }
  };
  crash_12118_test.main = function() {
    if (!dart.equals(new crash_12118_test.B().x, 42)) {
      dart.throw('Test failed');
    }
  };
  dart.fn(crash_12118_test.main, VoidTovoid());
  // Exports:
  exports.crash_12118_test = crash_12118_test;
});
