dart_library.library('language/function_subtype_optional1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_optional1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_optional1_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let __Tovoid = () => (__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [], [core.int])))();
  let __Tovoid$ = () => (__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [], [core.Object])))();
  let int__Tovoid = () => (int__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int], [core.int])))();
  let int__Tovoid$ = () => (int__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [core.int], [core.int, core.int])))();
  let doubleTovoid = () => (doubleTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.double])))();
  let __Tovoid$0 = () => (__Tovoid$0 = dart.constFn(dart.definiteFunctionType(dart.void, [], [core.int, core.int])))();
  let __Tovoid$1 = () => (__Tovoid$1 = dart.constFn(dart.definiteFunctionType(dart.void, [], [core.int, core.int, core.int])))();
  let __Tovoid$2 = () => (__Tovoid$2 = dart.constFn(dart.definiteFunctionType(dart.void, [], [core.Object, core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_optional1_test.void_ = function() {
  };
  dart.fn(function_subtype_optional1_test.void_, VoidTovoid());
  function_subtype_optional1_test.void__int = function(i) {
  };
  dart.fn(function_subtype_optional1_test.void__int, intTovoid());
  function_subtype_optional1_test.void___int = function(i) {
    if (i === void 0) i = null;
  };
  dart.fn(function_subtype_optional1_test.void___int, __Tovoid());
  function_subtype_optional1_test.void___int2 = function(i) {
    if (i === void 0) i = null;
  };
  dart.fn(function_subtype_optional1_test.void___int2, __Tovoid());
  function_subtype_optional1_test.void___Object = function(o) {
    if (o === void 0) o = null;
  };
  dart.fn(function_subtype_optional1_test.void___Object, __Tovoid$());
  function_subtype_optional1_test.void__int__int = function(i1, i2) {
    if (i2 === void 0) i2 = null;
  };
  dart.fn(function_subtype_optional1_test.void__int__int, int__Tovoid());
  function_subtype_optional1_test.void__int__int2 = function(i1, i2) {
    if (i2 === void 0) i2 = null;
  };
  dart.fn(function_subtype_optional1_test.void__int__int2, int__Tovoid());
  function_subtype_optional1_test.void__int__int_int = function(i1, i2, i3) {
    if (i2 === void 0) i2 = null;
    if (i3 === void 0) i3 = null;
  };
  dart.fn(function_subtype_optional1_test.void__int__int_int, int__Tovoid$());
  function_subtype_optional1_test.void___double = function(d) {
  };
  dart.fn(function_subtype_optional1_test.void___double, doubleTovoid());
  function_subtype_optional1_test.void___int_int = function(i1, i2) {
    if (i1 === void 0) i1 = null;
    if (i2 === void 0) i2 = null;
  };
  dart.fn(function_subtype_optional1_test.void___int_int, __Tovoid$0());
  function_subtype_optional1_test.void___int_int_int = function(i1, i2, i3) {
    if (i1 === void 0) i1 = null;
    if (i2 === void 0) i2 = null;
    if (i3 === void 0) i3 = null;
  };
  dart.fn(function_subtype_optional1_test.void___int_int_int, __Tovoid$1());
  function_subtype_optional1_test.void___Object_int = function(o, i) {
    if (o === void 0) o = null;
    if (i === void 0) i = null;
  };
  dart.fn(function_subtype_optional1_test.void___Object_int, __Tovoid$2());
  function_subtype_optional1_test.t_void_ = dart.typedef('t_void_', () => dart.functionType(dart.void, []));
  function_subtype_optional1_test.t_void__int = dart.typedef('t_void__int', () => dart.functionType(dart.void, [core.int]));
  function_subtype_optional1_test.t_void___int = dart.typedef('t_void___int', () => dart.functionType(dart.void, [], [core.int]));
  function_subtype_optional1_test.t_void___int2 = dart.typedef('t_void___int2', () => dart.functionType(dart.void, [], [core.int]));
  function_subtype_optional1_test.t_void___Object = dart.typedef('t_void___Object', () => dart.functionType(dart.void, [], [core.Object]));
  function_subtype_optional1_test.t_void__int__int = dart.typedef('t_void__int__int', () => dart.functionType(dart.void, [core.int], [core.int]));
  function_subtype_optional1_test.t_void__int__int2 = dart.typedef('t_void__int__int2', () => dart.functionType(dart.void, [core.int], [core.int]));
  function_subtype_optional1_test.t_void__int__int_int = dart.typedef('t_void__int__int_int', () => dart.functionType(dart.void, [core.int], [core.int, core.int]));
  function_subtype_optional1_test.t_void___double = dart.typedef('t_void___double', () => dart.functionType(dart.void, [core.double]));
  function_subtype_optional1_test.t_void___int_int = dart.typedef('t_void___int_int', () => dart.functionType(dart.void, [], [core.int, core.int]));
  function_subtype_optional1_test.t_void___int_int_int = dart.typedef('t_void___int_int_int', () => dart.functionType(dart.void, [], [core.int, core.int, core.int]));
  function_subtype_optional1_test.t_void___Object_int = dart.typedef('t_void___Object_int', () => dart.functionType(dart.void, [], [core.Object, core.int]));
  function_subtype_optional1_test.main = function() {
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void_.is(function_subtype_optional1_test.void___int));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void__int.is(function_subtype_optional1_test.void___int));
    expect$.Expect.isFalse(function_subtype_optional1_test.t_void___int.is(function_subtype_optional1_test.void__int));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void___int2.is(function_subtype_optional1_test.void___int));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void___int.is(function_subtype_optional1_test.void___Object));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void___Object.is(function_subtype_optional1_test.void___int));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void__int.is(function_subtype_optional1_test.void__int__int));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void__int__int2.is(function_subtype_optional1_test.void__int__int));
    expect$.Expect.isFalse(function_subtype_optional1_test.t_void___int.is(function_subtype_optional1_test.void__int));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void__int.is(function_subtype_optional1_test.void___int_int));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void__int__int.is(function_subtype_optional1_test.void___int_int));
    expect$.Expect.isFalse(function_subtype_optional1_test.t_void__int__int_int.is(function_subtype_optional1_test.void___int_int));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void__int__int_int.is(function_subtype_optional1_test.void___int_int_int));
    expect$.Expect.isFalse(function_subtype_optional1_test.t_void___double.is(function_subtype_optional1_test.void___int));
    expect$.Expect.isFalse(function_subtype_optional1_test.t_void___int_int.is(function_subtype_optional1_test.void___int));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void___int.is(function_subtype_optional1_test.void___int_int));
    expect$.Expect.isTrue(function_subtype_optional1_test.t_void___int.is(function_subtype_optional1_test.void___Object_int));
  };
  dart.fn(function_subtype_optional1_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_optional1_test = function_subtype_optional1_test;
});
