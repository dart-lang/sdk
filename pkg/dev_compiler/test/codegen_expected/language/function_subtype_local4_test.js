dart_library.library('language/function_subtype_local4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_local4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_local4_test = Object.create(null);
  let C = () => (C = dart.constFn(function_subtype_local4_test.C$()))();
  let D = () => (D = dart.constFn(function_subtype_local4_test.D$()))();
  let DOfString$bool = () => (DOfString$bool = dart.constFn(function_subtype_local4_test.D$(core.String, core.bool)))();
  let DOfbool$int = () => (DOfbool$int = dart.constFn(function_subtype_local4_test.D$(core.bool, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_local4_test.Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_local4_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_local4_test.Baz = dart.typedef('Baz', () => dart.functionType(dart.void, [core.bool], {b: core.String}));
  function_subtype_local4_test.Boz = dart.typedef('Boz', () => dart.functionType(core.int, [core.bool]));
  function_subtype_local4_test.C$ = dart.generic(T => {
    let T__Tovoid = () => (T__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [T], [core.String])))();
    let T__Tovoid$ = () => (T__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [T], {b: core.String})))();
    class C extends core.Object {
      test(nameOfT, expectedResult) {
        function foo(a, b) {
          if (b === void 0) b = null;
        }
        dart.fn(foo, T__Tovoid());
        function baz(a, opts) {
          let b = opts && 'b' in opts ? opts.b : null;
        }
        dart.fn(baz, T__Tovoid$());
        expect$.Expect.equals(expectedResult, function_subtype_local4_test.Foo.is(foo), dart.str`C<${nameOfT}>.foo is Foo`);
        expect$.Expect.equals(expectedResult, function_subtype_local4_test.Bar.is(foo), dart.str`C<${nameOfT}>.foo is Bar`);
        expect$.Expect.isFalse(function_subtype_local4_test.Baz.is(foo), dart.str`C<${nameOfT}>.foo is Baz`);
        expect$.Expect.isFalse(function_subtype_local4_test.Boz.is(foo), dart.str`C<${nameOfT}>.foo is Boz`);
        expect$.Expect.isFalse(function_subtype_local4_test.Foo.is(baz), dart.str`C<${nameOfT}>.baz is Foo`);
        expect$.Expect.isFalse(function_subtype_local4_test.Bar.is(baz), dart.str`C<${nameOfT}>.baz is Bar`);
        expect$.Expect.equals(expectedResult, function_subtype_local4_test.Baz.is(baz), dart.str`C<${nameOfT}>.baz is Baz`);
        expect$.Expect.isFalse(function_subtype_local4_test.Boz.is(baz), dart.str`C<${nameOfT}>.baz is Boz`);
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({test: dart.definiteFunctionType(dart.void, [core.String, core.bool])})
    });
    return C;
  });
  function_subtype_local4_test.C = C();
  function_subtype_local4_test.D$ = dart.generic((S, T) => {
    class D extends function_subtype_local4_test.C$(T) {}
    return D;
  });
  function_subtype_local4_test.D = D();
  function_subtype_local4_test.main = function() {
    new (DOfString$bool())().test('bool', true);
    new (DOfbool$int())().test('int', false);
    new function_subtype_local4_test.D().test('dynamic', true);
  };
  dart.fn(function_subtype_local4_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_local4_test = function_subtype_local4_test;
});
