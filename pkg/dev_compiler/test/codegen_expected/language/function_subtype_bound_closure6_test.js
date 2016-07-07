dart_library.library('language/function_subtype_bound_closure6_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_bound_closure6_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_bound_closure6_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(function_subtype_bound_closure6_test.Foo$()))();
  let Bar = () => (Bar = dart.constFn(function_subtype_bound_closure6_test.Bar$()))();
  let Baz = () => (Baz = dart.constFn(function_subtype_bound_closure6_test.Baz$()))();
  let Boz = () => (Boz = dart.constFn(function_subtype_bound_closure6_test.Boz$()))();
  let Biz = () => (Biz = dart.constFn(function_subtype_bound_closure6_test.Biz$()))();
  let C = () => (C = dart.constFn(function_subtype_bound_closure6_test.C$()))();
  let COfbool = () => (COfbool = dart.constFn(function_subtype_bound_closure6_test.C$(core.bool)))();
  let COfint = () => (COfint = dart.constFn(function_subtype_bound_closure6_test.C$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_bound_closure6_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(core.int, [T], [core.String]));
    return Foo;
  });
  function_subtype_bound_closure6_test.Foo = Foo();
  function_subtype_bound_closure6_test.Bar$ = dart.generic(T => {
    const Bar = dart.typedef('Bar', () => dart.functionType(core.int, [T], [core.String]));
    return Bar;
  });
  function_subtype_bound_closure6_test.Bar = Bar();
  function_subtype_bound_closure6_test.Baz$ = dart.generic(T => {
    const Baz = dart.typedef('Baz', () => dart.functionType(core.int, [T], {b: core.String}));
    return Baz;
  });
  function_subtype_bound_closure6_test.Baz = Baz();
  function_subtype_bound_closure6_test.Boz$ = dart.generic(T => {
    const Boz = dart.typedef('Boz', () => dart.functionType(core.int, [T]));
    return Boz;
  });
  function_subtype_bound_closure6_test.Boz = Boz();
  function_subtype_bound_closure6_test.Biz$ = dart.generic(T => {
    const Biz = dart.typedef('Biz', () => dart.functionType(core.int, [T, core.int]));
    return Biz;
  });
  function_subtype_bound_closure6_test.Biz = Biz();
  function_subtype_bound_closure6_test.C$ = dart.generic(T => {
    let FooOfT = () => (FooOfT = dart.constFn(function_subtype_bound_closure6_test.Foo$(T)))();
    let BazOfT = () => (BazOfT = dart.constFn(function_subtype_bound_closure6_test.Baz$(T)))();
    let BozOfT = () => (BozOfT = dart.constFn(function_subtype_bound_closure6_test.Boz$(T)))();
    let BizOfT = () => (BizOfT = dart.constFn(function_subtype_bound_closure6_test.Biz$(T)))();
    class C extends core.Object {
      foo(a, b) {
        if (b === void 0) b = null;
        return null;
      }
      baz(a, opts) {
        let b = opts && 'b' in opts ? opts.b : null;
        return null;
      }
      test(nameOfT, expectedResult) {
        const localMethod = (function() {
          expect$.Expect.equals(expectedResult, FooOfT().is(dart.bind(this, 'foo')), dart.str`foo is Foo<${nameOfT}>`);
          expect$.Expect.equals(expectedResult, FooOfT().is(dart.bind(this, 'foo')), dart.str`foo is Bar<${nameOfT}>`);
          expect$.Expect.isFalse(BazOfT().is(dart.bind(this, 'foo')), dart.str`foo is Baz<${nameOfT}>`);
          expect$.Expect.equals(expectedResult, BozOfT().is(dart.bind(this, 'foo')), dart.str`foo is Boz<${nameOfT}>`);
          expect$.Expect.isFalse(BizOfT().is(dart.bind(this, 'foo')), dart.str`foo is Biz<${nameOfT}>`);
          expect$.Expect.isFalse(FooOfT().is(dart.bind(this, 'baz')), dart.str`baz is Foo<${nameOfT}>`);
          expect$.Expect.isFalse(FooOfT().is(dart.bind(this, 'baz')), dart.str`baz is Bar<${nameOfT}>`);
          expect$.Expect.equals(expectedResult, BazOfT().is(dart.bind(this, 'baz')), dart.str`baz is Baz<${nameOfT}>`);
          expect$.Expect.equals(expectedResult, BozOfT().is(dart.bind(this, 'baz')), dart.str`baz is Boz<${nameOfT}>`);
          expect$.Expect.isFalse(BizOfT().is(dart.bind(this, 'baz')), dart.str`bar is Biz<${nameOfT}>`);
        }).bind(this);
        dart.fn(localMethod, VoidTovoid());
        localMethod();
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({
        foo: dart.definiteFunctionType(core.int, [core.bool], [core.String]),
        baz: dart.definiteFunctionType(core.int, [core.bool], {b: core.String}),
        test: dart.definiteFunctionType(dart.void, [core.String, core.bool])
      })
    });
    return C;
  });
  function_subtype_bound_closure6_test.C = C();
  function_subtype_bound_closure6_test.main = function() {
    new (COfbool())().test('bool', true);
    new (COfint())().test('int', false);
    new function_subtype_bound_closure6_test.C().test('dynamic', true);
  };
  dart.fn(function_subtype_bound_closure6_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_bound_closure6_test = function_subtype_bound_closure6_test;
});
