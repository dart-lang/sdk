dart_library.library('language/default_implementation2_test', null, /* Imports */[
  'dart_sdk'
], function load__default_implementation2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const default_implementation2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  default_implementation2_test.Point = class Point extends core.Object {
    static new(x, y) {
      return new default_implementation2_test.PointImplementation(x, y);
    }
  };
  dart.setSignature(default_implementation2_test.Point, {
    constructors: () => ({new: dart.definiteFunctionType(default_implementation2_test.Point, [dart.dynamic, dart.dynamic])})
  });
  default_implementation2_test.PointImplementation = class PointImplementation extends core.Object {
    new(x, y) {
    }
  };
  default_implementation2_test.PointImplementation[dart.implements] = () => [default_implementation2_test.Point];
  dart.setSignature(default_implementation2_test.PointImplementation, {
    constructors: () => ({new: dart.definiteFunctionType(default_implementation2_test.PointImplementation, [core.int, core.int])})
  });
  default_implementation2_test.main = function() {
    default_implementation2_test.Point.new(1, 2);
  };
  dart.fn(default_implementation2_test.main, VoidTodynamic());
  // Exports:
  exports.default_implementation2_test = default_implementation2_test;
});
