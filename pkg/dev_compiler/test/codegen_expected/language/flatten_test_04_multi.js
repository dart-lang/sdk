dart_library.library('language/flatten_test_04_multi', null, /* Imports */[
  'dart_sdk'
], function load__flatten_test_04_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const flatten_test_04_multi = Object.create(null);
  let Derived = () => (Derived = dart.constFn(flatten_test_04_multi.Derived$()))();
  let FixedPoint = () => (FixedPoint = dart.constFn(flatten_test_04_multi.FixedPoint$()))();
  let DerivedOfint = () => (DerivedOfint = dart.constFn(flatten_test_04_multi.Derived$(core.int)))();
  let FutureOfint = () => (FutureOfint = dart.constFn(async.Future$(core.int)))();
  let VoidToFutureOfint = () => (VoidToFutureOfint = dart.constFn(dart.definiteFunctionType(FutureOfint(), [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  flatten_test_04_multi.Derived$ = dart.generic(T => {
    let FutureOfT = () => (FutureOfT = dart.constFn(async.Future$(T)))();
    let StreamOfT = () => (StreamOfT = dart.constFn(async.Stream$(T)))();
    class Derived extends core.Object {
      noSuchMethod(invocation) {
        return super.noSuchMethod(invocation);
      }
      wait(T) {
        return (futures, opts) => {
          return async.Future$(core.List$(T))._check(this.noSuchMethod(new dart.InvocationImpl('wait', [futures], {namedArguments: opts, isMethod: true})));
        };
      }
      any(T) {
        return futures => {
          return async.Future$(T)._check(this.noSuchMethod(new dart.InvocationImpl('any', [futures], {isMethod: true})));
        };
      }
      forEach(input, f) {
        return async.Future._check(this.noSuchMethod(new dart.InvocationImpl('forEach', [input, f], {isMethod: true})));
      }
      doWhile(f) {
        return async.Future._check(this.noSuchMethod(new dart.InvocationImpl('doWhile', [f], {isMethod: true})));
      }
      then(S) {
        return (onValue, opts) => {
          return async.Future$(S)._check(this.noSuchMethod(new dart.InvocationImpl('then', [onValue], {namedArguments: opts, isMethod: true})));
        };
      }
      catchError(onError, opts) {
        return FutureOfT()._check(this.noSuchMethod(new dart.InvocationImpl('catchError', [onError], {namedArguments: opts, isMethod: true})));
      }
      whenComplete(action) {
        return FutureOfT()._check(this.noSuchMethod(new dart.InvocationImpl('whenComplete', [action], {isMethod: true})));
      }
      asStream() {
        return StreamOfT()._check(this.noSuchMethod(new dart.InvocationImpl('asStream', [], {isMethod: true})));
      }
      timeout(timeLimit, opts) {
        return FutureOfT()._check(this.noSuchMethod(new dart.InvocationImpl('timeout', [timeLimit], {namedArguments: opts, isMethod: true})));
      }
      get _nullFuture() {
        return async._Future._check(this.noSuchMethod(new dart.InvocationImpl('_nullFuture', [], {isGetter: true})));
      }
    }
    dart.addTypeTests(Derived);
    Derived[dart.implements] = () => [FutureOfT()];
    return Derived;
  });
  flatten_test_04_multi.Derived = Derived();
  flatten_test_04_multi.FixedPoint$ = dart.generic(T => {
    let FixedPointOfT = () => (FixedPointOfT = dart.constFn(flatten_test_04_multi.FixedPoint$(T)))();
    let FutureOfFixedPointOfT = () => (FutureOfFixedPointOfT = dart.constFn(async.Future$(FixedPointOfT())))();
    let StreamOfFixedPointOfT = () => (StreamOfFixedPointOfT = dart.constFn(async.Stream$(FixedPointOfT())))();
    class FixedPoint extends core.Object {
      noSuchMethod(invocation) {
        return super.noSuchMethod(invocation);
      }
      wait(T) {
        return (futures, opts) => {
          return async.Future$(core.List$(T))._check(this.noSuchMethod(new dart.InvocationImpl('wait', [futures], {namedArguments: opts, isMethod: true})));
        };
      }
      any(T) {
        return futures => {
          return async.Future$(T)._check(this.noSuchMethod(new dart.InvocationImpl('any', [futures], {isMethod: true})));
        };
      }
      forEach(input, f) {
        return async.Future._check(this.noSuchMethod(new dart.InvocationImpl('forEach', [input, f], {isMethod: true})));
      }
      doWhile(f) {
        return async.Future._check(this.noSuchMethod(new dart.InvocationImpl('doWhile', [f], {isMethod: true})));
      }
      then(S) {
        return (onValue, opts) => {
          return async.Future$(S)._check(this.noSuchMethod(new dart.InvocationImpl('then', [onValue], {namedArguments: opts, isMethod: true})));
        };
      }
      catchError(onError, opts) {
        return FutureOfFixedPointOfT()._check(this.noSuchMethod(new dart.InvocationImpl('catchError', [onError], {namedArguments: opts, isMethod: true})));
      }
      whenComplete(action) {
        return FutureOfFixedPointOfT()._check(this.noSuchMethod(new dart.InvocationImpl('whenComplete', [action], {isMethod: true})));
      }
      asStream() {
        return StreamOfFixedPointOfT()._check(this.noSuchMethod(new dart.InvocationImpl('asStream', [], {isMethod: true})));
      }
      timeout(timeLimit, opts) {
        return FutureOfFixedPointOfT()._check(this.noSuchMethod(new dart.InvocationImpl('timeout', [timeLimit], {namedArguments: opts, isMethod: true})));
      }
      get _nullFuture() {
        return async._Future._check(this.noSuchMethod(new dart.InvocationImpl('_nullFuture', [], {isGetter: true})));
      }
    }
    dart.addTypeTests(FixedPoint);
    FixedPoint[dart.implements] = () => [FutureOfFixedPointOfT()];
    return FixedPoint;
  });
  flatten_test_04_multi.FixedPoint = FixedPoint();
  flatten_test_04_multi.test = function() {
    return dart.async(function*() {
      let x = dart.fn(() => dart.async(function*() {
        return new (DerivedOfint())();
      }, core.int), VoidToFutureOfint())();
    }, dart.dynamic);
  };
  dart.fn(flatten_test_04_multi.test, VoidTodynamic());
  flatten_test_04_multi.main = function() {
    flatten_test_04_multi.test();
  };
  dart.fn(flatten_test_04_multi.main, VoidTodynamic());
  // Exports:
  exports.flatten_test_04_multi = flatten_test_04_multi;
});
