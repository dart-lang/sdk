dart_library.library('language/function_subtype_simple2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_simple2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_simple2_test = Object.create(null);
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic])))();
  let dynamic__Todynamic = () => (dynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic])))();
  let __Todynamic$ = () => (__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], [dart.dynamic, dart.dynamic])))();
  let dynamic__Todynamic$ = () => (dynamic__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], [dart.dynamic, dart.dynamic])))();
  let __Todynamic$0 = () => (__Todynamic$0 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic})))();
  let dynamic__Todynamic$0 = () => (dynamic__Todynamic$0 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {b: dart.dynamic})))();
  let __Todynamic$1 = () => (__Todynamic$1 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic, b: dart.dynamic})))();
  let dynamic__Todynamic$1 = () => (dynamic__Todynamic$1 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic], {b: dart.dynamic, c: dart.dynamic})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_simple2_test.Args0 = dart.typedef('Args0', () => dart.functionType(dart.dynamic, []));
  function_subtype_simple2_test.Args1 = dart.typedef('Args1', () => dart.functionType(dart.dynamic, [dart.dynamic]));
  function_subtype_simple2_test.Args2 = dart.typedef('Args2', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic]));
  function_subtype_simple2_test.Args3 = dart.typedef('Args3', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic]));
  function_subtype_simple2_test.Args4 = dart.typedef('Args4', () => dart.functionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]));
  function_subtype_simple2_test.args0_1 = function(a) {
    if (a === void 0) a = null;
  };
  dart.fn(function_subtype_simple2_test.args0_1, __Todynamic());
  function_subtype_simple2_test.args1_2 = function(a, b) {
    if (b === void 0) b = null;
  };
  dart.fn(function_subtype_simple2_test.args1_2, dynamic__Todynamic());
  function_subtype_simple2_test.args0_2 = function(a, b) {
    if (a === void 0) a = null;
    if (b === void 0) b = null;
  };
  dart.fn(function_subtype_simple2_test.args0_2, __Todynamic$());
  function_subtype_simple2_test.args1_3 = function(a, b, c) {
    if (b === void 0) b = null;
    if (c === void 0) c = null;
  };
  dart.fn(function_subtype_simple2_test.args1_3, dynamic__Todynamic$());
  function_subtype_simple2_test.args0_1_named = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
  };
  dart.fn(function_subtype_simple2_test.args0_1_named, __Todynamic$0());
  function_subtype_simple2_test.args1_2_named = function(a, opts) {
    let b = opts && 'b' in opts ? opts.b : null;
  };
  dart.fn(function_subtype_simple2_test.args1_2_named, dynamic__Todynamic$0());
  function_subtype_simple2_test.args0_2_named = function(opts) {
    let a = opts && 'a' in opts ? opts.a : null;
    let b = opts && 'b' in opts ? opts.b : null;
  };
  dart.fn(function_subtype_simple2_test.args0_2_named, __Todynamic$1());
  function_subtype_simple2_test.args1_3_named = function(a, opts) {
    let b = opts && 'b' in opts ? opts.b : null;
    let c = opts && 'c' in opts ? opts.c : null;
  };
  dart.fn(function_subtype_simple2_test.args1_3_named, dynamic__Todynamic$1());
  function_subtype_simple2_test.main = function() {
    expect$.Expect.isTrue(function_subtype_simple2_test.Args0.is(function_subtype_simple2_test.args0_1));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args1.is(function_subtype_simple2_test.args0_1));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args2.is(function_subtype_simple2_test.args0_1));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args3.is(function_subtype_simple2_test.args0_1));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args4.is(function_subtype_simple2_test.args0_1));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args0.is(function_subtype_simple2_test.args1_2));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args1.is(function_subtype_simple2_test.args1_2));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args2.is(function_subtype_simple2_test.args1_2));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args3.is(function_subtype_simple2_test.args1_2));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args4.is(function_subtype_simple2_test.args1_2));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args0.is(function_subtype_simple2_test.args0_2));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args1.is(function_subtype_simple2_test.args0_2));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args2.is(function_subtype_simple2_test.args0_2));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args3.is(function_subtype_simple2_test.args0_2));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args4.is(function_subtype_simple2_test.args0_2));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args0.is(function_subtype_simple2_test.args1_3));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args1.is(function_subtype_simple2_test.args1_3));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args2.is(function_subtype_simple2_test.args1_3));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args3.is(function_subtype_simple2_test.args1_3));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args4.is(function_subtype_simple2_test.args1_3));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args0.is(function_subtype_simple2_test.args0_1_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args1.is(function_subtype_simple2_test.args0_1_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args2.is(function_subtype_simple2_test.args0_1_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args3.is(function_subtype_simple2_test.args0_1_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args4.is(function_subtype_simple2_test.args0_1_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args0.is(function_subtype_simple2_test.args1_2_named));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args1.is(function_subtype_simple2_test.args1_2_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args2.is(function_subtype_simple2_test.args1_2_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args3.is(function_subtype_simple2_test.args1_2_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args4.is(function_subtype_simple2_test.args1_2_named));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args0.is(function_subtype_simple2_test.args0_2_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args1.is(function_subtype_simple2_test.args0_2_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args2.is(function_subtype_simple2_test.args0_2_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args3.is(function_subtype_simple2_test.args0_2_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args4.is(function_subtype_simple2_test.args0_2_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args0.is(function_subtype_simple2_test.args1_3_named));
    expect$.Expect.isTrue(function_subtype_simple2_test.Args1.is(function_subtype_simple2_test.args1_3_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args2.is(function_subtype_simple2_test.args1_3_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args3.is(function_subtype_simple2_test.args1_3_named));
    expect$.Expect.isFalse(function_subtype_simple2_test.Args4.is(function_subtype_simple2_test.args1_3_named));
  };
  dart.fn(function_subtype_simple2_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_simple2_test = function_subtype_simple2_test;
});
