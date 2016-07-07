dart_library.library('language/function_subtype_bound_closure0_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_bound_closure0_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_bound_closure0_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_bound_closure0_test.Foo = dart.typedef('Foo', () => dart.functionType(core.int, [core.bool], [core.String]));
  function_subtype_bound_closure0_test.Bar = dart.typedef('Bar', () => dart.functionType(core.int, [core.bool], [core.String]));
  function_subtype_bound_closure0_test.Baz = dart.typedef('Baz', () => dart.functionType(core.int, [core.bool], {b: core.String}));
  function_subtype_bound_closure0_test.Boz = dart.typedef('Boz', () => dart.functionType(core.int, [core.bool]));
  function_subtype_bound_closure0_test.C = class C extends core.Object {
    foo(a, b) {
      if (b === void 0) b = null;
      return null;
    }
    baz(a, opts) {
      let b = opts && 'b' in opts ? opts.b : null;
      return null;
    }
    boz(a, opts) {
      let b = opts && 'b' in opts ? opts.b : null;
      return null;
    }
  };
  dart.setSignature(function_subtype_bound_closure0_test.C, {
    methods: () => ({
      foo: dart.definiteFunctionType(core.int, [core.bool], [core.String]),
      baz: dart.definiteFunctionType(core.int, [core.bool], {b: core.String}),
      boz: dart.definiteFunctionType(core.int, [core.bool], {b: core.int})
    })
  });
  function_subtype_bound_closure0_test.main = function() {
    let c = new function_subtype_bound_closure0_test.C();
    let foo = dart.bind(c, 'foo');
    expect$.Expect.isTrue(function_subtype_bound_closure0_test.Foo.is(foo), 'foo is Foo');
    expect$.Expect.isTrue(function_subtype_bound_closure0_test.Bar.is(foo), 'foo is Bar');
    expect$.Expect.isFalse(function_subtype_bound_closure0_test.Baz.is(foo), 'foo is Baz');
    expect$.Expect.isTrue(function_subtype_bound_closure0_test.Boz.is(foo), 'foo is Boz');
    let baz = dart.bind(c, 'baz');
    expect$.Expect.isFalse(function_subtype_bound_closure0_test.Foo.is(baz), 'baz is Foo');
    expect$.Expect.isFalse(function_subtype_bound_closure0_test.Bar.is(baz), 'baz is Bar');
    expect$.Expect.isTrue(function_subtype_bound_closure0_test.Baz.is(baz), 'baz is Baz');
    expect$.Expect.isTrue(function_subtype_bound_closure0_test.Boz.is(baz), 'baz is Boz');
    let boz = dart.bind(c, 'boz');
    expect$.Expect.isFalse(function_subtype_bound_closure0_test.Foo.is(boz), 'boz is Foo');
    expect$.Expect.isFalse(function_subtype_bound_closure0_test.Bar.is(boz), 'boz is Bar');
    expect$.Expect.isFalse(function_subtype_bound_closure0_test.Baz.is(boz), 'boz is Baz');
    expect$.Expect.isTrue(function_subtype_bound_closure0_test.Boz.is(boz), 'boz is Boz');
  };
  dart.fn(function_subtype_bound_closure0_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_bound_closure0_test = function_subtype_bound_closure0_test;
});
