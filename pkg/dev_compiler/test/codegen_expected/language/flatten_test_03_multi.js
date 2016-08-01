dart_library.library('language/flatten_test_03_multi', null, /* Imports */[
  'dart_sdk'
], function load__flatten_test_03_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const flatten_test_03_multi = Object.create(null);
  let Derived = () => (Derived = dart.constFn(flatten_test_03_multi.Derived$()))();
  let FixedPoint = () => (FixedPoint = dart.constFn(flatten_test_03_multi.FixedPoint$()))();
  let DerivedOfint = () => (DerivedOfint = dart.constFn(flatten_test_03_multi.Derived$(core.int)))();
  let FutureOfint = () => (FutureOfint = dart.constFn(async.Future$(core.int)))();
  let VoidToFutureOfint = () => (VoidToFutureOfint = dart.constFn(dart.definiteFunctionType(FutureOfint(), [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  flatten_test_03_multi.Derived$ = dart.generic(T => {
    let FutureOfT = () => (FutureOfT = dart.constFn(async.Future$(T)))();
    let StreamOfT = () => (StreamOfT = dart.constFn(async.Stream$(T)))();
    class Derived extends core.Object {
      noSuchMethod(invocation) {
        return super.noSuchMethod(invocation);
      }
      wait(T) {
        return (...args) => {
          return async.Future$(core.List$(T))._check(this.noSuchMethod(new dart.InvocationImpl('wait', args, {namedArguments: dart.extractNamedArgs(args), isMethod: true})));
        };
      }
      any(T) {
        return (...args) => {
          return async.Future$(T)._check(this.noSuchMethod(new dart.InvocationImpl('any', args, {isMethod: true})));
        };
      }
      forEach(...args) {
        return async.Future._check(this.noSuchMethod(new dart.InvocationImpl('forEach', args, {isMethod: true})));
      }
      doWhile(...args) {
        return async.Future._check(this.noSuchMethod(new dart.InvocationImpl('doWhile', args, {isMethod: true})));
      }
      then(S) {
        return (...args) => {
          return async.Future$(S)._check(this.noSuchMethod(new dart.InvocationImpl('then', args, {namedArguments: dart.extractNamedArgs(args), isMethod: true})));
        };
      }
      catchError(...args) {
        return FutureOfT()._check(this.noSuchMethod(new dart.InvocationImpl('catchError', args, {namedArguments: dart.extractNamedArgs(args), isMethod: true})));
      }
      whenComplete(...args) {
        return FutureOfT()._check(this.noSuchMethod(new dart.InvocationImpl('whenComplete', args, {isMethod: true})));
      }
      asStream(...args) {
        return StreamOfT()._check(this.noSuchMethod(new dart.InvocationImpl('asStream', args, {isMethod: true})));
      }
      timeout(...args) {
        return FutureOfT()._check(this.noSuchMethod(new dart.InvocationImpl('timeout', args, {namedArguments: dart.extractNamedArgs(args), isMethod: true})));
      }
      get _nullFuture() {
        return async._Future._check(this.noSuchMethod(new dart.InvocationImpl('_nullFuture', [], {isGetter: true})));
      }
    }
    dart.addTypeTests(Derived);
    Derived[dart.implements] = () => [FutureOfT()];
    return Derived;
  });
  flatten_test_03_multi.Derived = Derived();
  flatten_test_03_multi.FixedPoint$ = dart.generic(T => {
    let FixedPointOfT = () => (FixedPointOfT = dart.constFn(flatten_test_03_multi.FixedPoint$(T)))();
    let FutureOfFixedPointOfT = () => (FutureOfFixedPointOfT = dart.constFn(async.Future$(FixedPointOfT())))();
    let StreamOfFixedPointOfT = () => (StreamOfFixedPointOfT = dart.constFn(async.Stream$(FixedPointOfT())))();
    class FixedPoint extends core.Object {
      noSuchMethod(invocation) {
        return super.noSuchMethod(invocation);
      }
      wait(T) {
        return (...args) => {
          return async.Future$(core.List$(T))._check(this.noSuchMethod(new dart.InvocationImpl('wait', args, {namedArguments: dart.extractNamedArgs(args), isMethod: true})));
        };
      }
      any(T) {
        return (...args) => {
          return async.Future$(T)._check(this.noSuchMethod(new dart.InvocationImpl('any', args, {isMethod: true})));
        };
      }
      forEach(...args) {
        return async.Future._check(this.noSuchMethod(new dart.InvocationImpl('forEach', args, {isMethod: true})));
      }
      doWhile(...args) {
        return async.Future._check(this.noSuchMethod(new dart.InvocationImpl('doWhile', args, {isMethod: true})));
      }
      then(S) {
        return (...args) => {
          return async.Future$(S)._check(this.noSuchMethod(new dart.InvocationImpl('then', args, {namedArguments: dart.extractNamedArgs(args), isMethod: true})));
        };
      }
      catchError(...args) {
        return FutureOfFixedPointOfT()._check(this.noSuchMethod(new dart.InvocationImpl('catchError', args, {namedArguments: dart.extractNamedArgs(args), isMethod: true})));
      }
      whenComplete(...args) {
        return FutureOfFixedPointOfT()._check(this.noSuchMethod(new dart.InvocationImpl('whenComplete', args, {isMethod: true})));
      }
      asStream(...args) {
        return StreamOfFixedPointOfT()._check(this.noSuchMethod(new dart.InvocationImpl('asStream', args, {isMethod: true})));
      }
      timeout(...args) {
        return FutureOfFixedPointOfT()._check(this.noSuchMethod(new dart.InvocationImpl('timeout', args, {namedArguments: dart.extractNamedArgs(args), isMethod: true})));
      }
      get _nullFuture() {
        return async._Future._check(this.noSuchMethod(new dart.InvocationImpl('_nullFuture', [], {isGetter: true})));
      }
    }
    dart.addTypeTests(FixedPoint);
    FixedPoint[dart.implements] = () => [FutureOfFixedPointOfT()];
    return FixedPoint;
  });
  flatten_test_03_multi.FixedPoint = FixedPoint();
  flatten_test_03_multi.test = function() {
    return dart.async(function*() {
      function f() {
        return dart.async(function*() {
          return new (DerivedOfint())();
        }, core.int);
      }
      dart.fn(f, VoidToFutureOfint());
    }, dart.dynamic);
  };
  dart.fn(flatten_test_03_multi.test, VoidTodynamic());
  flatten_test_03_multi.main = function() {
    flatten_test_03_multi.test();
  };
  dart.fn(flatten_test_03_multi.main, VoidTodynamic());
  // Exports:
  exports.flatten_test_03_multi = flatten_test_03_multi;
});
