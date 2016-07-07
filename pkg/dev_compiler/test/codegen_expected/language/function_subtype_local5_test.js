dart_library.library('language/function_subtype_local5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_local5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_local5_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(function_subtype_local5_test.Foo$()))();
  let Bar = () => (Bar = dart.constFn(function_subtype_local5_test.Bar$()))();
  let Baz = () => (Baz = dart.constFn(function_subtype_local5_test.Baz$()))();
  let Boz = () => (Boz = dart.constFn(function_subtype_local5_test.Boz$()))();
  let Biz = () => (Biz = dart.constFn(function_subtype_local5_test.Biz$()))();
  let C = () => (C = dart.constFn(function_subtype_local5_test.C$()))();
  let D = () => (D = dart.constFn(function_subtype_local5_test.D$()))();
  let DOfString$bool = () => (DOfString$bool = dart.constFn(function_subtype_local5_test.D$(core.String, core.bool)))();
  let DOfbool$int = () => (DOfbool$int = dart.constFn(function_subtype_local5_test.D$(core.bool, core.int)))();
  let bool__Toint = () => (bool__Toint = dart.constFn(dart.definiteFunctionType(core.int, [core.bool], [core.String])))();
  let bool__Toint$ = () => (bool__Toint$ = dart.constFn(dart.definiteFunctionType(core.int, [core.bool], {b: core.String})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_local5_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(core.int, [T], [core.String]));
    return Foo;
  });
  function_subtype_local5_test.Foo = Foo();
  function_subtype_local5_test.Bar$ = dart.generic(T => {
    const Bar = dart.typedef('Bar', () => dart.functionType(core.int, [T], [core.String]));
    return Bar;
  });
  function_subtype_local5_test.Bar = Bar();
  function_subtype_local5_test.Baz$ = dart.generic(T => {
    const Baz = dart.typedef('Baz', () => dart.functionType(core.int, [T], {b: core.String}));
    return Baz;
  });
  function_subtype_local5_test.Baz = Baz();
  function_subtype_local5_test.Boz$ = dart.generic(T => {
    const Boz = dart.typedef('Boz', () => dart.functionType(core.int, [T]));
    return Boz;
  });
  function_subtype_local5_test.Boz = Boz();
  function_subtype_local5_test.Biz$ = dart.generic(T => {
    const Biz = dart.typedef('Biz', () => dart.functionType(core.int, [T, core.int]));
    return Biz;
  });
  function_subtype_local5_test.Biz = Biz();
  function_subtype_local5_test.C$ = dart.generic(T => {
    let FooOfT = () => (FooOfT = dart.constFn(function_subtype_local5_test.Foo$(T)))();
    let BazOfT = () => (BazOfT = dart.constFn(function_subtype_local5_test.Baz$(T)))();
    let BozOfT = () => (BozOfT = dart.constFn(function_subtype_local5_test.Boz$(T)))();
    let BizOfT = () => (BizOfT = dart.constFn(function_subtype_local5_test.Biz$(T)))();
    class C extends core.Object {
      test(nameOfT, expectedResult) {
        function foo(a, b) {
          if (b === void 0) b = null;
          return null;
        }
        dart.fn(foo, bool__Toint());
        function baz(a, opts) {
          let b = opts && 'b' in opts ? opts.b : null;
          return null;
        }
        dart.fn(baz, bool__Toint$());
        expect$.Expect.equals(expectedResult, FooOfT().is(foo), dart.str`foo is Foo<${nameOfT}>`);
        expect$.Expect.equals(expectedResult, FooOfT().is(foo), dart.str`foo is Bar<${nameOfT}>`);
        expect$.Expect.isFalse(BazOfT().is(foo), dart.str`foo is Baz<${nameOfT}>`);
        expect$.Expect.equals(expectedResult, BozOfT().is(foo), dart.str`foo is Boz<${nameOfT}>`);
        expect$.Expect.isFalse(BizOfT().is(foo), dart.str`foo is Biz<${nameOfT}>`);
        expect$.Expect.isFalse(FooOfT().is(baz), dart.str`baz is Foo<${nameOfT}>`);
        expect$.Expect.isFalse(FooOfT().is(baz), dart.str`baz is Bar<${nameOfT}>`);
        expect$.Expect.equals(expectedResult, BazOfT().is(baz), dart.str`baz is Baz<${nameOfT}>`);
        expect$.Expect.equals(expectedResult, BozOfT().is(baz), dart.str`baz is Boz<${nameOfT}>`);
        expect$.Expect.isFalse(BizOfT().is(baz), dart.str`bar is Biz<${nameOfT}>`);
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({test: dart.definiteFunctionType(dart.void, [core.String, core.bool])})
    });
    return C;
  });
  function_subtype_local5_test.C = C();
  function_subtype_local5_test.D$ = dart.generic((S, T) => {
    class D extends function_subtype_local5_test.C$(T) {}
    return D;
  });
  function_subtype_local5_test.D = D();
  function_subtype_local5_test.main = function() {
    new (DOfString$bool())().test('bool', true);
    new (DOfbool$int())().test('int', false);
    new function_subtype_local5_test.D().test('dynamic', true);
  };
  dart.fn(function_subtype_local5_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_local5_test = function_subtype_local5_test;
});
