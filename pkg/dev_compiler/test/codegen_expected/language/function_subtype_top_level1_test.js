dart_library.library('language/function_subtype_top_level1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_top_level1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_top_level1_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(function_subtype_top_level1_test.Foo$()))();
  let Bar = () => (Bar = dart.constFn(function_subtype_top_level1_test.Bar$()))();
  let Baz = () => (Baz = dart.constFn(function_subtype_top_level1_test.Baz$()))();
  let Boz = () => (Boz = dart.constFn(function_subtype_top_level1_test.Boz$()))();
  let C = () => (C = dart.constFn(function_subtype_top_level1_test.C$()))();
  let COfbool = () => (COfbool = dart.constFn(function_subtype_top_level1_test.C$(core.bool)))();
  let COfint = () => (COfint = dart.constFn(function_subtype_top_level1_test.C$(core.int)))();
  let bool__Toint = () => (bool__Toint = dart.constFn(dart.definiteFunctionType(core.int, [core.bool], [core.String])))();
  let bool__Toint$ = () => (bool__Toint$ = dart.constFn(dart.definiteFunctionType(core.int, [core.bool], {b: core.String})))();
  let bool__Toint$0 = () => (bool__Toint$0 = dart.constFn(dart.definiteFunctionType(core.int, [core.bool], {b: core.int})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_top_level1_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(core.int, [T], [core.String]));
    return Foo;
  });
  function_subtype_top_level1_test.Foo = Foo();
  function_subtype_top_level1_test.Bar$ = dart.generic(T => {
    const Bar = dart.typedef('Bar', () => dart.functionType(core.int, [T], [core.String]));
    return Bar;
  });
  function_subtype_top_level1_test.Bar = Bar();
  function_subtype_top_level1_test.Baz$ = dart.generic(T => {
    const Baz = dart.typedef('Baz', () => dart.functionType(core.int, [T], {b: core.String}));
    return Baz;
  });
  function_subtype_top_level1_test.Baz = Baz();
  function_subtype_top_level1_test.Boz$ = dart.generic(T => {
    const Boz = dart.typedef('Boz', () => dart.functionType(core.int, [T]));
    return Boz;
  });
  function_subtype_top_level1_test.Boz = Boz();
  function_subtype_top_level1_test.foo = function(a, b) {
    if (b === void 0) b = null;
    return null;
  };
  dart.fn(function_subtype_top_level1_test.foo, bool__Toint());
  function_subtype_top_level1_test.baz = function(a, opts) {
    let b = opts && 'b' in opts ? opts.b : null;
    return null;
  };
  dart.fn(function_subtype_top_level1_test.baz, bool__Toint$());
  function_subtype_top_level1_test.boz = function(a, opts) {
    let b = opts && 'b' in opts ? opts.b : null;
    return null;
  };
  dart.fn(function_subtype_top_level1_test.boz, bool__Toint$0());
  function_subtype_top_level1_test.C$ = dart.generic(T => {
    let FooOfT = () => (FooOfT = dart.constFn(function_subtype_top_level1_test.Foo$(T)))();
    let BazOfT = () => (BazOfT = dart.constFn(function_subtype_top_level1_test.Baz$(T)))();
    let BozOfT = () => (BozOfT = dart.constFn(function_subtype_top_level1_test.Boz$(T)))();
    class C extends core.Object {
      test(nameOfT, expectedResult) {
        expect$.Expect.equals(expectedResult, FooOfT().is(function_subtype_top_level1_test.foo), dart.str`foo is Foo<${nameOfT}>`);
        expect$.Expect.equals(expectedResult, FooOfT().is(function_subtype_top_level1_test.foo), dart.str`foo is Bar<${nameOfT}>`);
        expect$.Expect.isFalse(BazOfT().is(function_subtype_top_level1_test.foo), dart.str`foo is Baz<${nameOfT}>`);
        expect$.Expect.equals(expectedResult, BozOfT().is(function_subtype_top_level1_test.foo), dart.str`foo is Boz<${nameOfT}>`);
        expect$.Expect.isFalse(FooOfT().is(function_subtype_top_level1_test.baz), dart.str`foo is Foo<${nameOfT}>`);
        expect$.Expect.isFalse(FooOfT().is(function_subtype_top_level1_test.baz), dart.str`foo is Bar<${nameOfT}>`);
        expect$.Expect.equals(expectedResult, BazOfT().is(function_subtype_top_level1_test.baz), dart.str`foo is Baz<${nameOfT}>`);
        expect$.Expect.equals(expectedResult, BozOfT().is(function_subtype_top_level1_test.baz), dart.str`foo is Boz<${nameOfT}>`);
        expect$.Expect.isFalse(FooOfT().is(function_subtype_top_level1_test.boz), dart.str`foo is Foo<${nameOfT}>`);
        expect$.Expect.isFalse(FooOfT().is(function_subtype_top_level1_test.boz), dart.str`foo is Bar<${nameOfT}>`);
        expect$.Expect.isFalse(BazOfT().is(function_subtype_top_level1_test.boz), dart.str`foo is Baz<${nameOfT}>`);
        expect$.Expect.equals(expectedResult, BozOfT().is(function_subtype_top_level1_test.boz), dart.str`foo is Boz<${nameOfT}>`);
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({test: dart.definiteFunctionType(dart.void, [core.String, core.bool])})
    });
    return C;
  });
  function_subtype_top_level1_test.C = C();
  function_subtype_top_level1_test.main = function() {
    new (COfbool())().test('bool', true);
    new (COfint())().test('int', false);
    new function_subtype_top_level1_test.C().test('dynamic', true);
  };
  dart.fn(function_subtype_top_level1_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_top_level1_test = function_subtype_top_level1_test;
});
