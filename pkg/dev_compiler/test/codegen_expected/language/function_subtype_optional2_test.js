dart_library.library('language/function_subtype_optional2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_optional2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_optional2_test = Object.create(null);
  let C = () => (C = dart.constFn(function_subtype_optional2_test.C$()))();
  let COfvoid___int = () => (COfvoid___int = dart.constFn(function_subtype_optional2_test.C$(function_subtype_optional2_test.void___int)))();
  let COfvoid_ = () => (COfvoid_ = dart.constFn(function_subtype_optional2_test.C$(function_subtype_optional2_test.void_)))();
  let COfvoid__int = () => (COfvoid__int = dart.constFn(function_subtype_optional2_test.C$(function_subtype_optional2_test.void__int)))();
  let COfvoid___Object = () => (COfvoid___Object = dart.constFn(function_subtype_optional2_test.C$(function_subtype_optional2_test.void___Object)))();
  let COfvoid__int__int = () => (COfvoid__int__int = dart.constFn(function_subtype_optional2_test.C$(function_subtype_optional2_test.void__int__int)))();
  let COfvoid___int_int = () => (COfvoid___int_int = dart.constFn(function_subtype_optional2_test.C$(function_subtype_optional2_test.void___int_int)))();
  let COfvoid__int__int_int = () => (COfvoid__int__int_int = dart.constFn(function_subtype_optional2_test.C$(function_subtype_optional2_test.void__int__int_int)))();
  let COfvoid___int_int_int = () => (COfvoid___int_int_int = dart.constFn(function_subtype_optional2_test.C$(function_subtype_optional2_test.void___int_int_int)))();
  let COfvoid___double = () => (COfvoid___double = dart.constFn(function_subtype_optional2_test.C$(function_subtype_optional2_test.void___double)))();
  let COfvoid___Object_int = () => (COfvoid___Object_int = dart.constFn(function_subtype_optional2_test.C$(function_subtype_optional2_test.void___Object_int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_optional2_test.C$ = dart.generic(T => {
    class C extends core.Object {}
    dart.addTypeTests(C);
    return C;
  });
  function_subtype_optional2_test.C = C();
  function_subtype_optional2_test.void_ = dart.typedef('void_', () => dart.functionType(dart.void, []));
  function_subtype_optional2_test.void__int = dart.typedef('void__int', () => dart.functionType(dart.void, [core.int]));
  function_subtype_optional2_test.void___int = dart.typedef('void___int', () => dart.functionType(dart.void, [], [core.int]));
  function_subtype_optional2_test.void___int2 = dart.typedef('void___int2', () => dart.functionType(dart.void, [], [core.int]));
  function_subtype_optional2_test.void___Object = dart.typedef('void___Object', () => dart.functionType(dart.void, [], [core.Object]));
  function_subtype_optional2_test.void__int__int = dart.typedef('void__int__int', () => dart.functionType(dart.void, [core.int], [core.int]));
  function_subtype_optional2_test.void__int__int2 = dart.typedef('void__int__int2', () => dart.functionType(dart.void, [core.int], [core.int]));
  function_subtype_optional2_test.void__int__int_int = dart.typedef('void__int__int_int', () => dart.functionType(dart.void, [core.int], [core.int, core.int]));
  function_subtype_optional2_test.void___double = dart.typedef('void___double', () => dart.functionType(dart.void, [core.double]));
  function_subtype_optional2_test.void___int_int = dart.typedef('void___int_int', () => dart.functionType(dart.void, [], [core.int, core.int]));
  function_subtype_optional2_test.void___int_int_int = dart.typedef('void___int_int_int', () => dart.functionType(dart.void, [], [core.int, core.int, core.int]));
  function_subtype_optional2_test.void___Object_int = dart.typedef('void___Object_int', () => dart.functionType(dart.void, [], [core.Object, core.int]));
  function_subtype_optional2_test.main = function() {
    expect$.Expect.isTrue(COfvoid_().is(new (COfvoid___int())()));
    expect$.Expect.isTrue(COfvoid__int().is(new (COfvoid___int())()));
    expect$.Expect.isFalse(COfvoid___int().is(new (COfvoid__int())()));
    expect$.Expect.isTrue(COfvoid___int().is(new (COfvoid___int())()));
    expect$.Expect.isTrue(COfvoid___int().is(new (COfvoid___Object())()));
    expect$.Expect.isTrue(COfvoid___Object().is(new (COfvoid___int())()));
    expect$.Expect.isTrue(COfvoid__int().is(new (COfvoid__int__int())()));
    expect$.Expect.isTrue(COfvoid__int__int().is(new (COfvoid__int__int())()));
    expect$.Expect.isFalse(COfvoid___int().is(new (COfvoid__int())()));
    expect$.Expect.isTrue(COfvoid__int().is(new (COfvoid___int_int())()));
    expect$.Expect.isTrue(COfvoid__int__int().is(new (COfvoid___int_int())()));
    expect$.Expect.isFalse(COfvoid__int__int_int().is(new (COfvoid___int_int())()));
    expect$.Expect.isTrue(COfvoid__int__int_int().is(new (COfvoid___int_int_int())()));
    expect$.Expect.isFalse(COfvoid___double().is(new (COfvoid___int())()));
    expect$.Expect.isFalse(COfvoid___int_int().is(new (COfvoid___int())()));
    expect$.Expect.isTrue(COfvoid___int().is(new (COfvoid___int_int())()));
    expect$.Expect.isTrue(COfvoid___int().is(new (COfvoid___Object_int())()));
  };
  dart.fn(function_subtype_optional2_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_optional2_test = function_subtype_optional2_test;
});
