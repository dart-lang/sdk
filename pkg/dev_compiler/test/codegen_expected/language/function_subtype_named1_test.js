dart_library.library('language/function_subtype_named1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_named1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_named1_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let __Tovoid = () => (__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [], {a: core.int})))();
  let __Tovoid$ = () => (__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [], {b: core.int})))();
  let __Tovoid$0 = () => (__Tovoid$0 = dart.constFn(dart.definiteFunctionType(dart.void, [], {a: core.Object})))();
  let int__Tovoid = () => (int__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int], {a: core.int})))();
  let __Tovoid$1 = () => (__Tovoid$1 = dart.constFn(dart.definiteFunctionType(dart.void, [], {a: core.double})))();
  let __Tovoid$2 = () => (__Tovoid$2 = dart.constFn(dart.definiteFunctionType(dart.void, [], {a: core.int, b: core.int})))();
  let __Tovoid$3 = () => (__Tovoid$3 = dart.constFn(dart.definiteFunctionType(dart.void, [], {a: core.int, b: core.int, c: core.int})))();
  let __Tovoid$4 = () => (__Tovoid$4 = dart.constFn(dart.definiteFunctionType(dart.void, [], {a: core.int, c: core.int})))();
  let __Tovoid$5 = () => (__Tovoid$5 = dart.constFn(dart.definiteFunctionType(dart.void, [], {b: core.int, c: core.int})))();
  let __Tovoid$6 = () => (__Tovoid$6 = dart.constFn(dart.definiteFunctionType(dart.void, [], {c: core.int})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_named1_test.void_ = function() {
  };
  dart.fn(function_subtype_named1_test.void_, VoidTovoid());
  function_subtype_named1_test.void__int = function(i) {
  };
  dart.fn(function_subtype_named1_test.void__int, intTovoid());
  function_subtype_named1_test.void___a_int = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
  };
  dart.fn(function_subtype_named1_test.void___a_int, __Tovoid());
  function_subtype_named1_test.void___a_int2 = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
  };
  dart.fn(function_subtype_named1_test.void___a_int2, __Tovoid());
  function_subtype_named1_test.void___b_int = function(opts) {
    let b = opts && 'b' in opts ? opts.b : null;
  };
  dart.fn(function_subtype_named1_test.void___b_int, __Tovoid$());
  function_subtype_named1_test.void___a_Object = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
  };
  dart.fn(function_subtype_named1_test.void___a_Object, __Tovoid$0());
  function_subtype_named1_test.void__int__a_int = function(i1, opts) {
    let a = opts && 'a' in opts ? opts.a : null;
  };
  dart.fn(function_subtype_named1_test.void__int__a_int, int__Tovoid());
  function_subtype_named1_test.void__int__a_int2 = function(i1, opts) {
    let a = opts && 'a' in opts ? opts.a : null;
  };
  dart.fn(function_subtype_named1_test.void__int__a_int2, int__Tovoid());
  function_subtype_named1_test.void___a_double = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
  };
  dart.fn(function_subtype_named1_test.void___a_double, __Tovoid$1());
  function_subtype_named1_test.void___a_int_b_int = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    let b = opts && 'b' in opts ? opts.b : null;
  };
  dart.fn(function_subtype_named1_test.void___a_int_b_int, __Tovoid$2());
  function_subtype_named1_test.void___a_int_b_int_c_int = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    let b = opts && 'b' in opts ? opts.b : null;
    let c = opts && 'c' in opts ? opts.c : null;
  };
  dart.fn(function_subtype_named1_test.void___a_int_b_int_c_int, __Tovoid$3());
  function_subtype_named1_test.void___a_int_c_int = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    let c = opts && 'c' in opts ? opts.c : null;
  };
  dart.fn(function_subtype_named1_test.void___a_int_c_int, __Tovoid$4());
  function_subtype_named1_test.void___b_int_c_int = function(opts) {
    let b = opts && 'b' in opts ? opts.b : null;
    let c = opts && 'c' in opts ? opts.c : null;
  };
  dart.fn(function_subtype_named1_test.void___b_int_c_int, __Tovoid$5());
  function_subtype_named1_test.void___c_int = function(opts) {
    let c = opts && 'c' in opts ? opts.c : null;
  };
  dart.fn(function_subtype_named1_test.void___c_int, __Tovoid$6());
  function_subtype_named1_test.t_void_ = dart.typedef('t_void_', () => dart.functionType(dart.void, []));
  function_subtype_named1_test.t_void__int = dart.typedef('t_void__int', () => dart.functionType(dart.void, [core.int]));
  function_subtype_named1_test.t_void___a_int = dart.typedef('t_void___a_int', () => dart.functionType(dart.void, [], {a: core.int}));
  function_subtype_named1_test.t_void___a_int2 = dart.typedef('t_void___a_int2', () => dart.functionType(dart.void, [], {a: core.int}));
  function_subtype_named1_test.t_void___b_int = dart.typedef('t_void___b_int', () => dart.functionType(dart.void, [], {b: core.int}));
  function_subtype_named1_test.t_void___a_Object = dart.typedef('t_void___a_Object', () => dart.functionType(dart.void, [], {a: core.Object}));
  function_subtype_named1_test.t_void__int__a_int = dart.typedef('t_void__int__a_int', () => dart.functionType(dart.void, [core.int], {a: core.int}));
  function_subtype_named1_test.t_void__int__a_int2 = dart.typedef('t_void__int__a_int2', () => dart.functionType(dart.void, [core.int], {a: core.int}));
  function_subtype_named1_test.t_void___a_double = dart.typedef('t_void___a_double', () => dart.functionType(dart.void, [], {a: core.double}));
  function_subtype_named1_test.t_void___a_int_b_int = dart.typedef('t_void___a_int_b_int', () => dart.functionType(dart.void, [], {a: core.int, b: core.int}));
  function_subtype_named1_test.t_void___a_int_b_int_c_int = dart.typedef('t_void___a_int_b_int_c_int', () => dart.functionType(dart.void, [], {a: core.int, b: core.int, c: core.int}));
  function_subtype_named1_test.t_void___a_int_c_int = dart.typedef('t_void___a_int_c_int', () => dart.functionType(dart.void, [], {a: core.int, c: core.int}));
  function_subtype_named1_test.t_void___b_int_c_int = dart.typedef('t_void___b_int_c_int', () => dart.functionType(dart.void, [], {b: core.int, c: core.int}));
  function_subtype_named1_test.t_void___c_int = dart.typedef('t_void___c_int', () => dart.functionType(dart.void, [], {c: core.int}));
  function_subtype_named1_test.main = function() {
    expect$.Expect.isTrue(function_subtype_named1_test.t_void_.is(function_subtype_named1_test.void___a_int));
    expect$.Expect.isFalse(function_subtype_named1_test.t_void__int.is(function_subtype_named1_test.void___a_int));
    expect$.Expect.isFalse(function_subtype_named1_test.t_void___a_int.is(function_subtype_named1_test.void__int));
    expect$.Expect.isTrue(function_subtype_named1_test.t_void___a_int2.is(function_subtype_named1_test.void___a_int));
    expect$.Expect.isFalse(function_subtype_named1_test.t_void___b_int.is(function_subtype_named1_test.void___a_int));
    expect$.Expect.isTrue(function_subtype_named1_test.t_void___a_int.is(function_subtype_named1_test.void___a_Object));
    expect$.Expect.isTrue(function_subtype_named1_test.t_void___a_Object.is(function_subtype_named1_test.void___a_int));
    expect$.Expect.isTrue(function_subtype_named1_test.t_void__int__a_int2.is(function_subtype_named1_test.void__int__a_int));
    expect$.Expect.isFalse(function_subtype_named1_test.t_void___a_double.is(function_subtype_named1_test.void___a_int));
    expect$.Expect.isFalse(function_subtype_named1_test.t_void___a_int_b_int.is(function_subtype_named1_test.void___a_int));
    expect$.Expect.isTrue(function_subtype_named1_test.t_void___a_int.is(function_subtype_named1_test.void___a_int_b_int));
    expect$.Expect.isTrue(function_subtype_named1_test.t_void___a_int_c_int.is(function_subtype_named1_test.void___a_int_b_int_c_int));
    expect$.Expect.isTrue(function_subtype_named1_test.t_void___b_int_c_int.is(function_subtype_named1_test.void___a_int_b_int_c_int));
    expect$.Expect.isTrue(function_subtype_named1_test.t_void___c_int.is(function_subtype_named1_test.void___a_int_b_int_c_int));
  };
  dart.fn(function_subtype_named1_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_named1_test = function_subtype_named1_test;
});
