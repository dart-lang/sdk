dart_library.library('language/function_subtype0_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype0_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype0_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.functionType(dart.void, [core.int])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidToObject = () => (VoidToObject = dart.constFn(dart.definiteFunctionType(core.Object, [])))();
  let VoidTodouble = () => (VoidTodouble = dart.constFn(dart.definiteFunctionType(core.double, [])))();
  let intTovoid$ = () => (intTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let ObjectToint = () => (ObjectToint = dart.constFn(dart.definiteFunctionType(core.int, [core.Object])))();
  let intToObject = () => (intToObject = dart.constFn(dart.definiteFunctionType(core.Object, [core.int])))();
  let doubleToint = () => (doubleToint = dart.constFn(dart.definiteFunctionType(core.int, [core.double])))();
  let intAndintToint = () => (intAndintToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int, core.int])))();
  let FnTovoid = () => (FnTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [VoidTovoid()])))();
  let FnTovoid$ = () => (FnTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [intTovoid()])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype0_test.t__ = dart.typedef('t__', () => dart.functionType(dart.dynamic, []));
  function_subtype0_test.t_void_ = dart.typedef('t_void_', () => dart.functionType(dart.void, []));
  function_subtype0_test.t_void_2 = dart.typedef('t_void_2', () => dart.functionType(dart.void, []));
  function_subtype0_test.t_int_ = dart.typedef('t_int_', () => dart.functionType(core.int, []));
  function_subtype0_test.t_int_2 = dart.typedef('t_int_2', () => dart.functionType(core.int, []));
  function_subtype0_test.t_Object_ = dart.typedef('t_Object_', () => dart.functionType(core.Object, []));
  function_subtype0_test.t_double_ = dart.typedef('t_double_', () => dart.functionType(core.double, []));
  function_subtype0_test.t_void__int = dart.typedef('t_void__int', () => dart.functionType(dart.void, [core.int]));
  function_subtype0_test.t_int__int = dart.typedef('t_int__int', () => dart.functionType(core.int, [core.int]));
  function_subtype0_test.t_int__int2 = dart.typedef('t_int__int2', () => dart.functionType(core.int, [core.int]));
  function_subtype0_test.t_int__Object = dart.typedef('t_int__Object', () => dart.functionType(core.int, [core.Object]));
  function_subtype0_test.t_Object__int = dart.typedef('t_Object__int', () => dart.functionType(core.Object, [core.int]));
  function_subtype0_test.t_int__double = dart.typedef('t_int__double', () => dart.functionType(core.int, [core.double]));
  function_subtype0_test.t_int__int_int = dart.typedef('t_int__int_int', () => dart.functionType(core.int, [core.int, core.int]));
  function_subtype0_test.t_inline_void_ = dart.typedef('t_inline_void_', () => dart.functionType(dart.void, [dart.functionType(dart.void, [])]));
  function_subtype0_test.t_inline_void__int = dart.typedef('t_inline_void__int', () => dart.functionType(dart.void, [dart.functionType(dart.void, [core.int])]));
  function_subtype0_test._ = function() {
    return null;
  };
  dart.fn(function_subtype0_test._, VoidTovoid$());
  function_subtype0_test.void_ = function() {
  };
  dart.fn(function_subtype0_test.void_, VoidTovoid$());
  function_subtype0_test.void_2 = function() {
  };
  dart.fn(function_subtype0_test.void_2, VoidTovoid$());
  function_subtype0_test.int_ = function() {
    return 0;
  };
  dart.fn(function_subtype0_test.int_, VoidToint());
  function_subtype0_test.int_2 = function() {
    return 0;
  };
  dart.fn(function_subtype0_test.int_2, VoidToint());
  function_subtype0_test.Object_ = function() {
    return null;
  };
  dart.fn(function_subtype0_test.Object_, VoidToObject());
  function_subtype0_test.double_ = function() {
    return 0.0;
  };
  dart.fn(function_subtype0_test.double_, VoidTodouble());
  function_subtype0_test.void__int = function(i) {
  };
  dart.fn(function_subtype0_test.void__int, intTovoid$());
  function_subtype0_test.int__int = function(i) {
    return 0;
  };
  dart.fn(function_subtype0_test.int__int, intToint());
  function_subtype0_test.int__int2 = function(i) {
    return 0;
  };
  dart.fn(function_subtype0_test.int__int2, intToint());
  function_subtype0_test.int__Object = function(o) {
    return 0;
  };
  dart.fn(function_subtype0_test.int__Object, ObjectToint());
  function_subtype0_test.Object__int = function(i) {
    return null;
  };
  dart.fn(function_subtype0_test.Object__int, intToObject());
  function_subtype0_test.int__double = function(d) {
    return 0;
  };
  dart.fn(function_subtype0_test.int__double, doubleToint());
  function_subtype0_test.int__int_int = function(i1, i2) {
    return 0;
  };
  dart.fn(function_subtype0_test.int__int_int, intAndintToint());
  function_subtype0_test.inline_void_ = function(f) {
  };
  dart.fn(function_subtype0_test.inline_void_, FnTovoid());
  function_subtype0_test.inline_void__int = function(f) {
  };
  dart.fn(function_subtype0_test.inline_void__int, FnTovoid$());
  function_subtype0_test.main = function() {
    expect$.Expect.isTrue(core.Function.is(function_subtype0_test.int_));
    expect$.Expect.isTrue(function_subtype0_test.t__.is(function_subtype0_test._));
    expect$.Expect.isTrue(function_subtype0_test.t_void_.is(function_subtype0_test._));
    expect$.Expect.isTrue(function_subtype0_test.t__.is(function_subtype0_test.void_));
    expect$.Expect.isTrue(function_subtype0_test.t_void_.is(function_subtype0_test.int_));
    expect$.Expect.isFalse(function_subtype0_test.t_int_.is(function_subtype0_test.void_));
    expect$.Expect.isTrue(function_subtype0_test.t_void_2.is(function_subtype0_test.void_));
    expect$.Expect.isTrue(function_subtype0_test.t_int_2.is(function_subtype0_test.int_));
    expect$.Expect.isTrue(function_subtype0_test.t_Object_.is(function_subtype0_test.int_));
    expect$.Expect.isFalse(function_subtype0_test.t_double_.is(function_subtype0_test.int_));
    expect$.Expect.isFalse(function_subtype0_test.t_void__int.is(function_subtype0_test.int_));
    expect$.Expect.isFalse(function_subtype0_test.t_int__int.is(function_subtype0_test.void_));
    expect$.Expect.isFalse(function_subtype0_test.t_void__int.is(function_subtype0_test.void_));
    expect$.Expect.isTrue(function_subtype0_test.t_int__int2.is(function_subtype0_test.int__int));
    expect$.Expect.isTrue(function_subtype0_test.t_Object__int.is(function_subtype0_test.int__Object));
    expect$.Expect.isFalse(function_subtype0_test.t_int__double.is(function_subtype0_test.int__int));
    expect$.Expect.isFalse(function_subtype0_test.t_int__int.is(function_subtype0_test.int_));
    expect$.Expect.isFalse(function_subtype0_test.t_int__int_int.is(function_subtype0_test.int__int));
    expect$.Expect.isFalse(function_subtype0_test.t_int__int.is(function_subtype0_test.int__int_int));
    expect$.Expect.isFalse(function_subtype0_test.t_inline_void__int.is(function_subtype0_test.inline_void_));
    expect$.Expect.isFalse(function_subtype0_test.t_inline_void_.is(function_subtype0_test.inline_void__int));
  };
  dart.fn(function_subtype0_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype0_test = function_subtype0_test;
});
