dart_library.library('language/function_subtype_top_level0_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_top_level0_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_top_level0_test = Object.create(null);
  let bool__Toint = () => (bool__Toint = dart.constFn(dart.definiteFunctionType(core.int, [core.bool], [core.String])))();
  let bool__Toint$ = () => (bool__Toint$ = dart.constFn(dart.definiteFunctionType(core.int, [core.bool], {b: core.String})))();
  let bool__Toint$0 = () => (bool__Toint$0 = dart.constFn(dart.definiteFunctionType(core.int, [core.bool], {b: core.int})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_top_level0_test.Foo = dart.typedef('Foo', () => dart.functionType(core.int, [core.bool], [core.String]));
  function_subtype_top_level0_test.Bar = dart.typedef('Bar', () => dart.functionType(core.int, [core.bool], [core.String]));
  function_subtype_top_level0_test.Baz = dart.typedef('Baz', () => dart.functionType(core.int, [core.bool], {b: core.String}));
  function_subtype_top_level0_test.Boz = dart.typedef('Boz', () => dart.functionType(core.int, [core.bool]));
  function_subtype_top_level0_test.foo = function(a, b) {
    if (b === void 0) b = null;
    return null;
  };
  dart.fn(function_subtype_top_level0_test.foo, bool__Toint());
  function_subtype_top_level0_test.baz = function(a, opts) {
    let b = opts && 'b' in opts ? opts.b : null;
    return null;
  };
  dart.fn(function_subtype_top_level0_test.baz, bool__Toint$());
  function_subtype_top_level0_test.boz = function(a, opts) {
    let b = opts && 'b' in opts ? opts.b : null;
    return null;
  };
  dart.fn(function_subtype_top_level0_test.boz, bool__Toint$0());
  function_subtype_top_level0_test.main = function() {
    expect$.Expect.isTrue(function_subtype_top_level0_test.Foo.is(function_subtype_top_level0_test.foo), 'foo is Foo');
    expect$.Expect.isTrue(function_subtype_top_level0_test.Bar.is(function_subtype_top_level0_test.foo), 'foo is Bar');
    expect$.Expect.isFalse(function_subtype_top_level0_test.Baz.is(function_subtype_top_level0_test.foo), 'foo is Baz');
    expect$.Expect.isTrue(function_subtype_top_level0_test.Boz.is(function_subtype_top_level0_test.foo), 'foo is Boz');
    expect$.Expect.isFalse(function_subtype_top_level0_test.Foo.is(function_subtype_top_level0_test.baz), 'foo is Foo');
    expect$.Expect.isFalse(function_subtype_top_level0_test.Bar.is(function_subtype_top_level0_test.baz), 'foo is Bar');
    expect$.Expect.isTrue(function_subtype_top_level0_test.Baz.is(function_subtype_top_level0_test.baz), 'foo is Baz');
    expect$.Expect.isTrue(function_subtype_top_level0_test.Boz.is(function_subtype_top_level0_test.baz), 'foo is Boz');
    expect$.Expect.isFalse(function_subtype_top_level0_test.Foo.is(function_subtype_top_level0_test.boz), 'foo is Foo');
    expect$.Expect.isFalse(function_subtype_top_level0_test.Bar.is(function_subtype_top_level0_test.boz), 'foo is Bar');
    expect$.Expect.isFalse(function_subtype_top_level0_test.Baz.is(function_subtype_top_level0_test.boz), 'foo is Baz');
    expect$.Expect.isTrue(function_subtype_top_level0_test.Boz.is(function_subtype_top_level0_test.boz), 'foo is Boz');
  };
  dart.fn(function_subtype_top_level0_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_top_level0_test = function_subtype_top_level0_test;
});
