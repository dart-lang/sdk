dart_library.library('language/function_subtype_local1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_local1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_local1_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(function_subtype_local1_test.Foo$()))();
  let Bar = () => (Bar = dart.constFn(function_subtype_local1_test.Bar$()))();
  let Baz = () => (Baz = dart.constFn(function_subtype_local1_test.Baz$()))();
  let Boz = () => (Boz = dart.constFn(function_subtype_local1_test.Boz$()))();
  let FooOfbool = () => (FooOfbool = dart.constFn(function_subtype_local1_test.Foo$(core.bool)))();
  let BazOfbool = () => (BazOfbool = dart.constFn(function_subtype_local1_test.Baz$(core.bool)))();
  let BozOfbool = () => (BozOfbool = dart.constFn(function_subtype_local1_test.Boz$(core.bool)))();
  let FooOfint = () => (FooOfint = dart.constFn(function_subtype_local1_test.Foo$(core.int)))();
  let BazOfint = () => (BazOfint = dart.constFn(function_subtype_local1_test.Baz$(core.int)))();
  let BozOfint = () => (BozOfint = dart.constFn(function_subtype_local1_test.Boz$(core.int)))();
  let bool__Toint = () => (bool__Toint = dart.constFn(dart.definiteFunctionType(core.int, [core.bool], [core.String])))();
  let bool__Toint$ = () => (bool__Toint$ = dart.constFn(dart.definiteFunctionType(core.int, [core.bool], {b: core.String})))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_local1_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(core.int, [T], [core.String]));
    return Foo;
  });
  function_subtype_local1_test.Foo = Foo();
  function_subtype_local1_test.Bar$ = dart.generic(T => {
    const Bar = dart.typedef('Bar', () => dart.functionType(core.int, [T], [core.String]));
    return Bar;
  });
  function_subtype_local1_test.Bar = Bar();
  function_subtype_local1_test.Baz$ = dart.generic(T => {
    const Baz = dart.typedef('Baz', () => dart.functionType(core.int, [T], {b: core.String}));
    return Baz;
  });
  function_subtype_local1_test.Baz = Baz();
  function_subtype_local1_test.Boz$ = dart.generic(T => {
    const Boz = dart.typedef('Boz', () => dart.functionType(core.int, [T]));
    return Boz;
  });
  function_subtype_local1_test.Boz = Boz();
  function_subtype_local1_test.main = function() {
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
    expect$.Expect.isTrue(FooOfbool().is(foo), 'foo is Foo<bool>');
    expect$.Expect.isTrue(FooOfbool().is(foo), 'foo is Bar<bool>');
    expect$.Expect.isFalse(BazOfbool().is(foo), 'foo is Baz<bool>');
    expect$.Expect.isTrue(BozOfbool().is(foo), 'foo is Boz<bool>');
    expect$.Expect.isFalse(FooOfint().is(foo), 'foo is Foo<int>');
    expect$.Expect.isFalse(FooOfint().is(foo), 'foo is Bar<int>');
    expect$.Expect.isFalse(BazOfint().is(foo), 'foo is Baz<int>');
    expect$.Expect.isFalse(BozOfint().is(foo), 'foo is Boz<int>');
    expect$.Expect.isTrue(function_subtype_local1_test.Foo.is(foo), 'foo is Foo');
    expect$.Expect.isTrue(function_subtype_local1_test.Bar.is(foo), 'foo is Bar');
    expect$.Expect.isFalse(function_subtype_local1_test.Baz.is(foo), 'foo is Baz');
    expect$.Expect.isTrue(function_subtype_local1_test.Boz.is(foo), 'foo is Boz');
    expect$.Expect.isFalse(FooOfbool().is(baz), 'baz is Foo<bool>');
    expect$.Expect.isFalse(FooOfbool().is(baz), 'baz is Bar<bool>');
    expect$.Expect.isTrue(BazOfbool().is(baz), 'baz is Baz<bool>');
    expect$.Expect.isTrue(BozOfbool().is(baz), 'baz is Boz<bool>');
    expect$.Expect.isFalse(FooOfint().is(baz), 'baz is Foo<int>');
    expect$.Expect.isFalse(FooOfint().is(baz), 'baz is Bar<int>');
    expect$.Expect.isFalse(BazOfint().is(baz), 'baz is Baz<int>');
    expect$.Expect.isFalse(BozOfint().is(baz), 'baz is Boz<int>');
    expect$.Expect.isFalse(function_subtype_local1_test.Foo.is(baz), 'baz is Foo');
    expect$.Expect.isFalse(function_subtype_local1_test.Bar.is(baz), 'baz is Bar');
    expect$.Expect.isTrue(function_subtype_local1_test.Baz.is(baz), 'baz is Baz');
    expect$.Expect.isTrue(function_subtype_local1_test.Boz.is(baz), 'baz is Boz');
  };
  dart.fn(function_subtype_local1_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_local1_test = function_subtype_local1_test;
});
