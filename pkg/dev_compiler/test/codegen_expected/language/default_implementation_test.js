dart_library.library('language/default_implementation_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__default_implementation_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const default_implementation_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  default_implementation_test.Point = class Point extends core.Object {
    static new(x, y) {
      return new default_implementation_test.PointImplementation(x, y);
    }
  };
  dart.setSignature(default_implementation_test.Point, {
    constructors: () => ({new: dart.definiteFunctionType(default_implementation_test.Point, [core.int, core.int])})
  });
  default_implementation_test.PointImplementation = class PointImplementation extends core.Object {
    new(x, y) {
      this.x = x;
      this.y = y;
    }
  };
  default_implementation_test.PointImplementation[dart.implements] = () => [default_implementation_test.Point];
  dart.setSignature(default_implementation_test.PointImplementation, {
    constructors: () => ({new: dart.definiteFunctionType(default_implementation_test.PointImplementation, [core.int, core.int])})
  });
  default_implementation_test.DefaultImplementationTest = class DefaultImplementationTest extends core.Object {
    static testMain() {
      let point = default_implementation_test.Point.new(4, 2);
      expect$.Expect.equals(4, point.x);
      expect$.Expect.equals(2, point.y);
    }
  };
  dart.setSignature(default_implementation_test.DefaultImplementationTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  default_implementation_test.main = function() {
    default_implementation_test.DefaultImplementationTest.testMain();
  };
  dart.fn(default_implementation_test.main, VoidTodynamic());
  // Exports:
  exports.default_implementation_test = default_implementation_test;
});
