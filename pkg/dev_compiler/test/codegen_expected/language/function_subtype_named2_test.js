dart_library.library('language/function_subtype_named2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_named2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_named2_test = Object.create(null);
  let C = () => (C = dart.constFn(function_subtype_named2_test.C$()))();
  let COfvoid___a_int = () => (COfvoid___a_int = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void___a_int)))();
  let COfvoid_ = () => (COfvoid_ = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void_)))();
  let COfvoid__int = () => (COfvoid__int = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void__int)))();
  let COfvoid___b_int = () => (COfvoid___b_int = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void___b_int)))();
  let COfvoid___a_Object = () => (COfvoid___a_Object = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void___a_Object)))();
  let COfvoid__int__a_int = () => (COfvoid__int__a_int = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void__int__a_int)))();
  let COfvoid___a_double = () => (COfvoid___a_double = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void___a_double)))();
  let COfvoid___a_int_b_int = () => (COfvoid___a_int_b_int = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void___a_int_b_int)))();
  let COfvoid___a_int_b_int_c_int = () => (COfvoid___a_int_b_int_c_int = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void___a_int_b_int_c_int)))();
  let COfvoid___a_int_c_int = () => (COfvoid___a_int_c_int = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void___a_int_c_int)))();
  let COfvoid___b_int_c_int = () => (COfvoid___b_int_c_int = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void___b_int_c_int)))();
  let COfvoid___c_int = () => (COfvoid___c_int = dart.constFn(function_subtype_named2_test.C$(function_subtype_named2_test.void___c_int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_named2_test.C$ = dart.generic(T => {
    class C extends core.Object {}
    dart.addTypeTests(C);
    return C;
  });
  function_subtype_named2_test.C = C();
  function_subtype_named2_test.void_ = dart.typedef('void_', () => dart.functionType(dart.void, []));
  function_subtype_named2_test.void__int = dart.typedef('void__int', () => dart.functionType(dart.void, [core.int]));
  function_subtype_named2_test.void___a_int = dart.typedef('void___a_int', () => dart.functionType(dart.void, [], {a: core.int}));
  function_subtype_named2_test.void___a_int2 = dart.typedef('void___a_int2', () => dart.functionType(dart.void, [], {a: core.int}));
  function_subtype_named2_test.void___b_int = dart.typedef('void___b_int', () => dart.functionType(dart.void, [], {b: core.int}));
  function_subtype_named2_test.void___a_Object = dart.typedef('void___a_Object', () => dart.functionType(dart.void, [], {a: core.Object}));
  function_subtype_named2_test.void__int__a_int = dart.typedef('void__int__a_int', () => dart.functionType(dart.void, [core.int], {a: core.int}));
  function_subtype_named2_test.void__int__a_int2 = dart.typedef('void__int__a_int2', () => dart.functionType(dart.void, [core.int], {a: core.int}));
  function_subtype_named2_test.void___a_double = dart.typedef('void___a_double', () => dart.functionType(dart.void, [], {a: core.double}));
  function_subtype_named2_test.void___a_int_b_int = dart.typedef('void___a_int_b_int', () => dart.functionType(dart.void, [], {a: core.int, b: core.int}));
  function_subtype_named2_test.void___a_int_b_int_c_int = dart.typedef('void___a_int_b_int_c_int', () => dart.functionType(dart.void, [], {a: core.int, b: core.int, c: core.int}));
  function_subtype_named2_test.void___a_int_c_int = dart.typedef('void___a_int_c_int', () => dart.functionType(dart.void, [], {a: core.int, c: core.int}));
  function_subtype_named2_test.void___b_int_c_int = dart.typedef('void___b_int_c_int', () => dart.functionType(dart.void, [], {b: core.int, c: core.int}));
  function_subtype_named2_test.void___c_int = dart.typedef('void___c_int', () => dart.functionType(dart.void, [], {c: core.int}));
  function_subtype_named2_test.main = function() {
    expect$.Expect.isTrue(COfvoid_().is(new (COfvoid___a_int())()));
    expect$.Expect.isFalse(COfvoid__int().is(new (COfvoid___a_int())()));
    expect$.Expect.isFalse(COfvoid___a_int().is(new (COfvoid__int())()));
    expect$.Expect.isTrue(COfvoid___a_int().is(new (COfvoid___a_int())()));
    expect$.Expect.isFalse(COfvoid___b_int().is(new (COfvoid___a_int())()));
    expect$.Expect.isTrue(COfvoid___a_int().is(new (COfvoid___a_Object())()));
    expect$.Expect.isTrue(COfvoid___a_Object().is(new (COfvoid___a_int())()));
    expect$.Expect.isTrue(COfvoid__int__a_int().is(new (COfvoid__int__a_int())()));
    expect$.Expect.isFalse(COfvoid___a_double().is(new (COfvoid___a_int())()));
    expect$.Expect.isFalse(COfvoid___a_int_b_int().is(new (COfvoid___a_int())()));
    expect$.Expect.isTrue(COfvoid___a_int().is(new (COfvoid___a_int_b_int())()));
    expect$.Expect.isTrue(COfvoid___a_int_c_int().is(new (COfvoid___a_int_b_int_c_int())()));
    expect$.Expect.isTrue(COfvoid___b_int_c_int().is(new (COfvoid___a_int_b_int_c_int())()));
    expect$.Expect.isTrue(COfvoid___c_int().is(new (COfvoid___a_int_b_int_c_int())()));
  };
  dart.fn(function_subtype_named2_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_named2_test = function_subtype_named2_test;
});
