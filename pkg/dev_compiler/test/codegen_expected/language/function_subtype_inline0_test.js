dart_library.library('language/function_subtype_inline0_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_inline0_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_inline0_test = Object.create(null);
  let C = () => (C = dart.constFn(function_subtype_inline0_test.C$()))();
  let COfbool = () => (COfbool = dart.constFn(function_subtype_inline0_test.C$(core.bool)))();
  let COfint = () => (COfint = dart.constFn(function_subtype_inline0_test.C$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_inline0_test.Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_inline0_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_inline0_test.Baz = dart.typedef('Baz', () => dart.functionType(dart.void, [core.bool], {b: core.String}));
  function_subtype_inline0_test.Boz = dart.typedef('Boz', () => dart.functionType(core.int, [core.bool]));
  function_subtype_inline0_test.C$ = dart.generic(T => {
    let T__Todynamic = () => (T__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [T], [core.String])))();
    let T__Todynamic$ = () => (T__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [T], {b: core.String})))();
    class C extends core.Object {
      test(nameOfT, expectedResult) {
        expect$.Expect.equals(expectedResult, function_subtype_inline0_test.Foo.is(dart.fn((a, b) => {
          if (b === void 0) b = null;
        }, T__Todynamic())), dart.str`(${nameOfT},[String])->void is Foo`);
        expect$.Expect.equals(expectedResult, function_subtype_inline0_test.Bar.is(dart.fn((a, b) => {
          if (b === void 0) b = null;
        }, T__Todynamic())), dart.str`(${nameOfT},[String])->void is Bar`);
        expect$.Expect.isFalse(function_subtype_inline0_test.Baz.is(dart.fn((a, b) => {
          if (b === void 0) b = null;
        }, T__Todynamic())), dart.str`(${nameOfT},[String])->void is Baz`);
        expect$.Expect.equals(expectedResult, function_subtype_inline0_test.Boz.is(dart.fn((a, b) => {
          if (b === void 0) b = null;
        }, T__Todynamic())), dart.str`(${nameOfT},[String])->void is Boz`);
        expect$.Expect.isFalse(function_subtype_inline0_test.Foo.is(dart.fn((a, opts) => {
          let b = opts && 'b' in opts ? opts.b : null;
        }, T__Todynamic$())), dart.str`(${nameOfT},{b:String})->void is Foo`);
        expect$.Expect.isFalse(function_subtype_inline0_test.Bar.is(dart.fn((a, opts) => {
          let b = opts && 'b' in opts ? opts.b : null;
        }, T__Todynamic$())), dart.str`(${nameOfT},{b:String})->void is Bar`);
        expect$.Expect.equals(expectedResult, function_subtype_inline0_test.Baz.is(dart.fn((a, opts) => {
          let b = opts && 'b' in opts ? opts.b : null;
        }, T__Todynamic$())), dart.str`(${nameOfT},{b:String})->void is Baz`);
        expect$.Expect.equals(expectedResult, function_subtype_inline0_test.Boz.is(dart.fn((a, opts) => {
          let b = opts && 'b' in opts ? opts.b : null;
        }, T__Todynamic$())), dart.str`(${nameOfT},{b:String})->void is Boz`);
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({test: dart.definiteFunctionType(dart.void, [core.String, core.bool])})
    });
    return C;
  });
  function_subtype_inline0_test.C = C();
  function_subtype_inline0_test.main = function() {
    new (COfbool())().test('bool', true);
    new (COfint())().test('int', false);
    new function_subtype_inline0_test.C().test('dynamic', true);
  };
  dart.fn(function_subtype_inline0_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_inline0_test = function_subtype_inline0_test;
});
