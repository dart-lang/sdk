dart_library.library('language/flatten_test_07_multi', null, /* Imports */[
  'dart_sdk'
], function load__flatten_test_07_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const flatten_test_07_multi = Object.create(null);
  let Derived = () => (Derived = dart.constFn(flatten_test_07_multi.Derived$()))();
  let FixedPoint = () => (FixedPoint = dart.constFn(flatten_test_07_multi.FixedPoint$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  flatten_test_07_multi.Derived$ = dart.generic(T => {
    let FutureOfT = () => (FutureOfT = dart.constFn(async.Future$(T)))();
    class Derived extends core.Object {
      noSuchMethod(invocation) {
        return super.noSuchMethod(invocation);
      }
    }
    dart.addTypeTests(Derived);
    Derived[dart.implements] = () => [FutureOfT()];
    return Derived;
  });
  flatten_test_07_multi.Derived = Derived();
  flatten_test_07_multi.FixedPoint$ = dart.generic(T => {
    let FixedPointOfT = () => (FixedPointOfT = dart.constFn(flatten_test_07_multi.FixedPoint$(T)))();
    let FutureOfFixedPointOfT = () => (FutureOfFixedPointOfT = dart.constFn(async.Future$(FixedPointOfT())))();
    class FixedPoint extends core.Object {
      noSuchMethod(invocation) {
        return super.noSuchMethod(invocation);
      }
    }
    dart.addTypeTests(FixedPoint);
    FixedPoint[dart.implements] = () => [FutureOfFixedPointOfT()];
    return FixedPoint;
  });
  flatten_test_07_multi.FixedPoint = FixedPoint();
  flatten_test_07_multi.test = function() {
    return dart.async(function*() {
    }, dart.dynamic);
  };
  dart.fn(flatten_test_07_multi.test, VoidTodynamic());
  flatten_test_07_multi.main = function() {
    flatten_test_07_multi.test();
  };
  dart.fn(flatten_test_07_multi.main, VoidTodynamic());
  // Exports:
  exports.flatten_test_07_multi = flatten_test_07_multi;
});
