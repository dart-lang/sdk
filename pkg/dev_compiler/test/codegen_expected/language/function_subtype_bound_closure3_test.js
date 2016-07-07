dart_library.library('language/function_subtype_bound_closure3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_bound_closure3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_bound_closure3_test = Object.create(null);
  let C = () => (C = dart.constFn(function_subtype_bound_closure3_test.C$()))();
  let COfbool = () => (COfbool = dart.constFn(function_subtype_bound_closure3_test.C$(core.bool)))();
  let COfint = () => (COfint = dart.constFn(function_subtype_bound_closure3_test.C$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_bound_closure3_test.Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_bound_closure3_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_bound_closure3_test.Baz = dart.typedef('Baz', () => dart.functionType(dart.void, [core.bool], {b: core.String}));
  function_subtype_bound_closure3_test.Boz = dart.typedef('Boz', () => dart.functionType(core.int, [core.bool]));
  function_subtype_bound_closure3_test.C$ = dart.generic(T => {
    class C extends core.Object {
      foo(a, b) {
        T._check(a);
        if (b === void 0) b = null;
      }
      baz(a, opts) {
        T._check(a);
        let b = opts && 'b' in opts ? opts.b : null;
      }
      test(nameOfT, expectedResult) {
        expect$.Expect.equals(expectedResult, function_subtype_bound_closure3_test.Foo.is(dart.bind(this, 'foo')), dart.str`C<${nameOfT}>.foo is Foo`);
        expect$.Expect.equals(expectedResult, function_subtype_bound_closure3_test.Bar.is(dart.bind(this, 'foo')), dart.str`C<${nameOfT}>.foo is Bar`);
        expect$.Expect.isFalse(function_subtype_bound_closure3_test.Baz.is(dart.bind(this, 'foo')), dart.str`C<${nameOfT}>.foo is Baz`);
        expect$.Expect.isFalse(function_subtype_bound_closure3_test.Boz.is(dart.bind(this, 'foo')), dart.str`C<${nameOfT}>.foo is Boz`);
        expect$.Expect.isFalse(function_subtype_bound_closure3_test.Foo.is(dart.bind(this, 'baz')), dart.str`C<${nameOfT}>.baz is Foo`);
        expect$.Expect.isFalse(function_subtype_bound_closure3_test.Bar.is(dart.bind(this, 'baz')), dart.str`C<${nameOfT}>.baz is Bar`);
        expect$.Expect.equals(expectedResult, function_subtype_bound_closure3_test.Baz.is(dart.bind(this, 'baz')), dart.str`C<${nameOfT}>.baz is Baz`);
        expect$.Expect.isFalse(function_subtype_bound_closure3_test.Boz.is(dart.bind(this, 'baz')), dart.str`C<${nameOfT}>.baz is Boz`);
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({
        foo: dart.definiteFunctionType(dart.void, [T], [core.String]),
        baz: dart.definiteFunctionType(dart.void, [T], {b: core.String}),
        test: dart.definiteFunctionType(dart.void, [core.String, core.bool])
      })
    });
    return C;
  });
  function_subtype_bound_closure3_test.C = C();
  function_subtype_bound_closure3_test.main = function() {
    new (COfbool())().test('bool', true);
    new (COfint())().test('int', false);
    new function_subtype_bound_closure3_test.C().test('dynamic', true);
  };
  dart.fn(function_subtype_bound_closure3_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_bound_closure3_test = function_subtype_bound_closure3_test;
});
