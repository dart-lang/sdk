dart_library.library('language/function_subtype1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype1_test = Object.create(null);
  let C = () => (C = dart.constFn(function_subtype1_test.C$()))();
  let COfint_ = () => (COfint_ = dart.constFn(function_subtype1_test.C$(function_subtype1_test.int_)))();
  let COfFunction = () => (COfFunction = dart.constFn(function_subtype1_test.C$(core.Function)))();
  let COf_ = () => (COf_ = dart.constFn(function_subtype1_test.C$(function_subtype1_test._)))();
  let COfvoid_ = () => (COfvoid_ = dart.constFn(function_subtype1_test.C$(function_subtype1_test.void_)))();
  let COfObject_ = () => (COfObject_ = dart.constFn(function_subtype1_test.C$(function_subtype1_test.Object_)))();
  let COfdouble_ = () => (COfdouble_ = dart.constFn(function_subtype1_test.C$(function_subtype1_test.double_)))();
  let COfvoid__int = () => (COfvoid__int = dart.constFn(function_subtype1_test.C$(function_subtype1_test.void__int)))();
  let COfint__int = () => (COfint__int = dart.constFn(function_subtype1_test.C$(function_subtype1_test.int__int)))();
  let COfint__Object = () => (COfint__Object = dart.constFn(function_subtype1_test.C$(function_subtype1_test.int__Object)))();
  let COfObject__int = () => (COfObject__int = dart.constFn(function_subtype1_test.C$(function_subtype1_test.Object__int)))();
  let COfint__double = () => (COfint__double = dart.constFn(function_subtype1_test.C$(function_subtype1_test.int__double)))();
  let COfint__int_int = () => (COfint__int_int = dart.constFn(function_subtype1_test.C$(function_subtype1_test.int__int_int)))();
  let COfinline_void_ = () => (COfinline_void_ = dart.constFn(function_subtype1_test.C$(function_subtype1_test.inline_void_)))();
  let COfinline_void__int = () => (COfinline_void__int = dart.constFn(function_subtype1_test.C$(function_subtype1_test.inline_void__int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype1_test.C$ = dart.generic(T => {
    class C extends core.Object {}
    dart.addTypeTests(C);
    return C;
  });
  function_subtype1_test.C = C();
  function_subtype1_test._ = dart.typedef('_', () => dart.functionType(dart.dynamic, []));
  function_subtype1_test.void_ = dart.typedef('void_', () => dart.functionType(dart.void, []));
  function_subtype1_test.void_2 = dart.typedef('void_2', () => dart.functionType(dart.void, []));
  function_subtype1_test.int_ = dart.typedef('int_', () => dart.functionType(core.int, []));
  function_subtype1_test.int_2 = dart.typedef('int_2', () => dart.functionType(core.int, []));
  function_subtype1_test.Object_ = dart.typedef('Object_', () => dart.functionType(core.Object, []));
  function_subtype1_test.double_ = dart.typedef('double_', () => dart.functionType(core.double, []));
  function_subtype1_test.void__int = dart.typedef('void__int', () => dart.functionType(dart.void, [core.int]));
  function_subtype1_test.int__int = dart.typedef('int__int', () => dart.functionType(core.int, [core.int]));
  function_subtype1_test.int__int2 = dart.typedef('int__int2', () => dart.functionType(core.int, [core.int]));
  function_subtype1_test.int__Object = dart.typedef('int__Object', () => dart.functionType(core.int, [core.Object]));
  function_subtype1_test.Object__int = dart.typedef('Object__int', () => dart.functionType(core.Object, [core.int]));
  function_subtype1_test.int__double = dart.typedef('int__double', () => dart.functionType(core.int, [core.double]));
  function_subtype1_test.int__int_int = dart.typedef('int__int_int', () => dart.functionType(core.int, [core.int, core.int]));
  function_subtype1_test.inline_void_ = dart.typedef('inline_void_', () => dart.functionType(dart.void, [dart.functionType(dart.void, [])]));
  function_subtype1_test.inline_void__int = dart.typedef('inline_void__int', () => dart.functionType(dart.void, [dart.functionType(dart.void, [core.int])]));
  function_subtype1_test.main = function() {
    expect$.Expect.isTrue(COfFunction().is(new (COfint_())()));
    expect$.Expect.isFalse(COfint_().is(new (COfFunction())()));
    expect$.Expect.isTrue(COf_().is(new (COf_())()));
    expect$.Expect.isTrue(COfvoid_().is(new (COf_())()));
    expect$.Expect.isTrue(COf_().is(new (COfvoid_())()));
    expect$.Expect.isTrue(COfvoid_().is(new (COfint_())()));
    expect$.Expect.isFalse(COfint_().is(new (COfvoid_())()));
    expect$.Expect.isTrue(COfvoid_().is(new (COfvoid_())()));
    expect$.Expect.isTrue(COfint_().is(new (COfint_())()));
    expect$.Expect.isTrue(COfObject_().is(new (COfint_())()));
    expect$.Expect.isFalse(COfdouble_().is(new (COfint_())()));
    expect$.Expect.isFalse(COfvoid__int().is(new (COfint_())()));
    expect$.Expect.isFalse(COfint__int().is(new (COfvoid_())()));
    expect$.Expect.isFalse(COfvoid__int().is(new (COfvoid_())()));
    expect$.Expect.isTrue(COfint__int().is(new (COfint__int())()));
    expect$.Expect.isTrue(COfObject__int().is(new (COfint__Object())()));
    expect$.Expect.isFalse(COfint__double().is(new (COfint__int())()));
    expect$.Expect.isFalse(COfint__int().is(new (COfint_())()));
    expect$.Expect.isFalse(COfint__int_int().is(new (COfint__int())()));
    expect$.Expect.isFalse(COfint__int().is(new (COfint__int_int())()));
    expect$.Expect.isFalse(COfinline_void__int().is(new (COfinline_void_())()));
    expect$.Expect.isFalse(COfinline_void_().is(new (COfinline_void__int())()));
  };
  dart.fn(function_subtype1_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype1_test = function_subtype1_test;
});
