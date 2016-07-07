dart_library.library('language/await_regression_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__await_regression_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const await_regression_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic, b: dart.dynamic})))();
  await_regression_test.later = function(vodka) {
    return async.Future.value(vodka);
  };
  dart.fn(await_regression_test.later, dynamicTodynamic());
  await_regression_test.manana = function(tequila) {
    return dart.async(function*(tequila) {
      return tequila;
    }, dart.dynamic, tequila);
  };
  dart.fn(await_regression_test.manana, dynamicTodynamic());
  await_regression_test.testNestedFunctions = function() {
    return dart.async(function*() {
      let a = (yield dart.dsend(await_regression_test.later('Asterix'), 'then', dart.fn(tonic => await_regression_test.later(tonic), dynamicTodynamic())));
      let o = (yield dart.dsend(await_regression_test.manana('Obelix'), 'then', await_regression_test.manana));
      expect$.Expect.equals(dart.str`${a} and ${o}`, "Asterix and Obelix");
    }, dart.dynamic);
  };
  dart.fn(await_regression_test.testNestedFunctions, VoidTodynamic());
  await_regression_test.addLater = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    let b = opts && 'b' in opts ? opts.b : null;
    return async.Future.value(dart.dsend(a, '+', b));
  };
  dart.fn(await_regression_test.addLater, __Todynamic());
  await_regression_test.testNamedArguments = function() {
    return dart.async(function*() {
      let sum = (yield await_regression_test.addLater({a: 5, b: 10}));
      expect$.Expect.equals(sum, 15);
      sum = (yield await_regression_test.addLater({b: 11, a: -11}));
      expect$.Expect.equals(sum, 0);
    }, dart.dynamic);
  };
  dart.fn(await_regression_test.testNamedArguments, VoidTodynamic());
  await_regression_test.main = function() {
    return dart.async(function*() {
      await_regression_test.testNestedFunctions();
      await_regression_test.testNamedArguments();
    }, dart.dynamic);
  };
  dart.fn(await_regression_test.main, VoidTodynamic());
  // Exports:
  exports.await_regression_test = await_regression_test;
});
