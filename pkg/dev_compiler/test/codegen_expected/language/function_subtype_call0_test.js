dart_library.library('language/function_subtype_call0_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_call0_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_call0_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_call0_test.Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_call0_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_call0_test.Baz = dart.typedef('Baz', () => dart.functionType(dart.void, [core.bool], {b: core.String}));
  function_subtype_call0_test.Boz = dart.typedef('Boz', () => dart.functionType(dart.void, [core.bool]));
  function_subtype_call0_test.C1 = dart.callableClass(function C1(...args) {
    function call(...args) {
      return call.call.apply(call, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class C1 extends core.Object {
    call(a, b) {
      if (b === void 0) b = null;
    }
  });
  dart.setSignature(function_subtype_call0_test.C1, {
    methods: () => ({call: dart.definiteFunctionType(dart.void, [core.bool], [core.String])})
  });
  function_subtype_call0_test.C2 = dart.callableClass(function C2(...args) {
    function call(...args) {
      return call.call.apply(call, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class C2 extends core.Object {
    call(a, opts) {
      let b = opts && 'b' in opts ? opts.b : null;
    }
  });
  dart.setSignature(function_subtype_call0_test.C2, {
    methods: () => ({call: dart.definiteFunctionType(dart.void, [core.bool], {b: core.String})})
  });
  function_subtype_call0_test.C3 = dart.callableClass(function C3(...args) {
    function call(...args) {
      return call.call.apply(call, args);
    }
    call.__proto__ = this.__proto__;
    call.new.apply(call, args);
    return call;
  }, class C3 extends core.Object {
    call(a, opts) {
      let b = opts && 'b' in opts ? opts.b : null;
    }
  });
  dart.setSignature(function_subtype_call0_test.C3, {
    methods: () => ({call: dart.definiteFunctionType(dart.void, [core.bool], {b: core.int})})
  });
  function_subtype_call0_test.main = function() {
    expect$.Expect.isTrue(function_subtype_call0_test.Foo.is(new function_subtype_call0_test.C1()), 'new C1() is Foo');
    expect$.Expect.isTrue(function_subtype_call0_test.Bar.is(new function_subtype_call0_test.C1()), 'new C1() is Bar');
    expect$.Expect.isFalse(function_subtype_call0_test.Baz.is(new function_subtype_call0_test.C1()), 'new C1() is Baz');
    expect$.Expect.isTrue(function_subtype_call0_test.Boz.is(new function_subtype_call0_test.C1()), 'new C1() is Boz');
    expect$.Expect.isFalse(function_subtype_call0_test.Foo.is(new function_subtype_call0_test.C2()), 'new C2() is Foo');
    expect$.Expect.isFalse(function_subtype_call0_test.Bar.is(new function_subtype_call0_test.C2()), 'new C2() is Bar');
    expect$.Expect.isTrue(function_subtype_call0_test.Baz.is(new function_subtype_call0_test.C2()), 'new C2() is Baz');
    expect$.Expect.isTrue(function_subtype_call0_test.Boz.is(new function_subtype_call0_test.C2()), 'new C2() is Boz');
    expect$.Expect.isFalse(function_subtype_call0_test.Foo.is(new function_subtype_call0_test.C3()), 'new C3() is Foo');
    expect$.Expect.isFalse(function_subtype_call0_test.Bar.is(new function_subtype_call0_test.C3()), 'new C3() is Bar');
    expect$.Expect.isFalse(function_subtype_call0_test.Baz.is(new function_subtype_call0_test.C3()), 'new C3() is Baz');
    expect$.Expect.isTrue(function_subtype_call0_test.Boz.is(new function_subtype_call0_test.C3()), 'new C3() is Boz');
  };
  dart.fn(function_subtype_call0_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_call0_test = function_subtype_call0_test;
});
