dart_library.library('language/function_subtype_call1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_call1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_call1_test = Object.create(null);
  let C1 = () => (C1 = dart.constFn(function_subtype_call1_test.C1$()))();
  let C2 = () => (C2 = dart.constFn(function_subtype_call1_test.C2$()))();
  let C1Ofbool = () => (C1Ofbool = dart.constFn(function_subtype_call1_test.C1$(core.bool)))();
  let C1Ofint = () => (C1Ofint = dart.constFn(function_subtype_call1_test.C1$(core.int)))();
  let C2Ofbool = () => (C2Ofbool = dart.constFn(function_subtype_call1_test.C2$(core.bool)))();
  let C2Ofint = () => (C2Ofint = dart.constFn(function_subtype_call1_test.C2$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_call1_test.Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_call1_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_call1_test.Baz = dart.typedef('Baz', () => dart.functionType(dart.void, [core.bool], {b: core.String}));
  function_subtype_call1_test.Boz = dart.typedef('Boz', () => dart.functionType(dart.void, [core.bool]));
  function_subtype_call1_test.C1$ = dart.generic(T => {
    const C1 = dart.callableClass(function C1(...args) {
      function call(...args) {
        return call.call.apply(call, args);
      }
      call.__proto__ = this.__proto__;
      call.new.apply(call, args);
      return call;
    }, class C1 extends core.Object {
      call(a, b) {
        T._check(a);
        if (b === void 0) b = null;
      }
    });
    dart.addTypeTests(C1);
    dart.setSignature(C1, {
      methods: () => ({call: dart.definiteFunctionType(dart.void, [T], [core.String])})
    });
    return C1;
  });
  function_subtype_call1_test.C1 = C1();
  function_subtype_call1_test.C2$ = dart.generic(T => {
    const C2 = dart.callableClass(function C2(...args) {
      function call(...args) {
        return call.call.apply(call, args);
      }
      call.__proto__ = this.__proto__;
      call.new.apply(call, args);
      return call;
    }, class C2 extends core.Object {
      call(a, opts) {
        T._check(a);
        let b = opts && 'b' in opts ? opts.b : null;
      }
    });
    dart.addTypeTests(C2);
    dart.setSignature(C2, {
      methods: () => ({call: dart.definiteFunctionType(dart.void, [T], {b: core.String})})
    });
    return C2;
  });
  function_subtype_call1_test.C2 = C2();
  function_subtype_call1_test.main = function() {
    expect$.Expect.isTrue(function_subtype_call1_test.Foo.is(new (C1Ofbool())()), 'new C1<bool>() is Foo');
    expect$.Expect.isTrue(function_subtype_call1_test.Bar.is(new (C1Ofbool())()), 'new C1<bool>() is Bar');
    expect$.Expect.isFalse(function_subtype_call1_test.Baz.is(new (C1Ofbool())()), 'new C1<bool>() is Baz');
    expect$.Expect.isTrue(function_subtype_call1_test.Boz.is(new (C1Ofbool())()), 'new C1<bool>() is Boz');
    expect$.Expect.isFalse(function_subtype_call1_test.Foo.is(new (C1Ofint())()), 'new C1<int>() is Foo');
    expect$.Expect.isFalse(function_subtype_call1_test.Bar.is(new (C1Ofint())()), 'new C1<int>() is Bar');
    expect$.Expect.isFalse(function_subtype_call1_test.Baz.is(new (C1Ofint())()), 'new C1<int>() is Baz');
    expect$.Expect.isFalse(function_subtype_call1_test.Boz.is(new (C1Ofint())()), 'new C1<int>() is Boz');
    expect$.Expect.isTrue(function_subtype_call1_test.Foo.is(new function_subtype_call1_test.C1()), 'new C1() is Foo');
    expect$.Expect.isTrue(function_subtype_call1_test.Bar.is(new function_subtype_call1_test.C1()), 'new C1() is Bar');
    expect$.Expect.isFalse(function_subtype_call1_test.Baz.is(new function_subtype_call1_test.C1()), 'new C1() is Baz');
    expect$.Expect.isTrue(function_subtype_call1_test.Boz.is(new function_subtype_call1_test.C1()), 'new C1() is Boz');
    expect$.Expect.isFalse(function_subtype_call1_test.Foo.is(new (C2Ofbool())()), 'new C2<bool>() is Foo');
    expect$.Expect.isFalse(function_subtype_call1_test.Bar.is(new (C2Ofbool())()), 'new C2<bool>() is Bar');
    expect$.Expect.isTrue(function_subtype_call1_test.Baz.is(new (C2Ofbool())()), 'new C2<bool>() is Baz');
    expect$.Expect.isTrue(function_subtype_call1_test.Boz.is(new (C2Ofbool())()), 'new C2<bool>() is Boz');
    expect$.Expect.isFalse(function_subtype_call1_test.Foo.is(new (C2Ofint())()), 'new C2<int>() is Foo');
    expect$.Expect.isFalse(function_subtype_call1_test.Bar.is(new (C2Ofint())()), 'new C2<int>() is Bar');
    expect$.Expect.isFalse(function_subtype_call1_test.Baz.is(new (C2Ofint())()), 'new C2<int>() is Baz');
    expect$.Expect.isFalse(function_subtype_call1_test.Boz.is(new (C2Ofint())()), 'new C2<int>() is Boz');
    expect$.Expect.isFalse(function_subtype_call1_test.Foo.is(new function_subtype_call1_test.C2()), 'new C2() is Foo');
    expect$.Expect.isFalse(function_subtype_call1_test.Bar.is(new function_subtype_call1_test.C2()), 'new C2() is Bar');
    expect$.Expect.isTrue(function_subtype_call1_test.Baz.is(new function_subtype_call1_test.C2()), 'new C2() is Baz');
    expect$.Expect.isTrue(function_subtype_call1_test.Boz.is(new function_subtype_call1_test.C2()), 'new C2() is Boz');
  };
  dart.fn(function_subtype_call1_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_call1_test = function_subtype_call1_test;
});
