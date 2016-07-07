dart_library.library('language/function_subtype_call2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype_call2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype_call2_test = Object.create(null);
  let C1 = () => (C1 = dart.constFn(function_subtype_call2_test.C1$()))();
  let D1 = () => (D1 = dart.constFn(function_subtype_call2_test.D1$()))();
  let C2 = () => (C2 = dart.constFn(function_subtype_call2_test.C2$()))();
  let D2 = () => (D2 = dart.constFn(function_subtype_call2_test.D2$()))();
  let D1OfString$bool = () => (D1OfString$bool = dart.constFn(function_subtype_call2_test.D1$(core.String, core.bool)))();
  let D1Ofbool$int = () => (D1Ofbool$int = dart.constFn(function_subtype_call2_test.D1$(core.bool, core.int)))();
  let D2OfString$bool = () => (D2OfString$bool = dart.constFn(function_subtype_call2_test.D2$(core.String, core.bool)))();
  let D2Ofbool$int = () => (D2Ofbool$int = dart.constFn(function_subtype_call2_test.D2$(core.bool, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype_call2_test.Foo = dart.typedef('Foo', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_call2_test.Bar = dart.typedef('Bar', () => dart.functionType(dart.void, [core.bool], [core.String]));
  function_subtype_call2_test.Baz = dart.typedef('Baz', () => dart.functionType(dart.void, [core.bool], {b: core.String}));
  function_subtype_call2_test.Boz = dart.typedef('Boz', () => dart.functionType(dart.void, [core.bool]));
  function_subtype_call2_test.C1$ = dart.generic(T => {
    const C1 = dart.callableClass(function C1(...args) {
      const self = this;
      function call(...args) {
        return self.call.apply(self, args);
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
  function_subtype_call2_test.C1 = C1();
  function_subtype_call2_test.D1$ = dart.generic((S, T) => {
    class D1 extends function_subtype_call2_test.C1$(T) {}
    return D1;
  });
  function_subtype_call2_test.D1 = D1();
  function_subtype_call2_test.C2$ = dart.generic(T => {
    const C2 = dart.callableClass(function C2(...args) {
      const self = this;
      function call(...args) {
        return self.call.apply(self, args);
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
  function_subtype_call2_test.C2 = C2();
  function_subtype_call2_test.D2$ = dart.generic((S, T) => {
    class D2 extends function_subtype_call2_test.C2$(T) {}
    return D2;
  });
  function_subtype_call2_test.D2 = D2();
  function_subtype_call2_test.main = function() {
    expect$.Expect.isTrue(function_subtype_call2_test.Foo.is(new (D1OfString$bool())()), 'new D1<String, bool>() is Foo');
    expect$.Expect.isTrue(function_subtype_call2_test.Bar.is(new (D1OfString$bool())()), 'new D1<String, bool>() is Bar');
    expect$.Expect.isFalse(function_subtype_call2_test.Baz.is(new (D1OfString$bool())()), 'new D1<String, bool>() is Baz');
    expect$.Expect.isTrue(function_subtype_call2_test.Boz.is(new (D1OfString$bool())()), 'new D1<String, bool>() is Boz');
    expect$.Expect.isFalse(function_subtype_call2_test.Foo.is(new (D1Ofbool$int())()), 'new D1<bool, int>() is Foo');
    expect$.Expect.isFalse(function_subtype_call2_test.Bar.is(new (D1Ofbool$int())()), 'new D1<bool, int>() is Bar');
    expect$.Expect.isFalse(function_subtype_call2_test.Baz.is(new (D1Ofbool$int())()), 'new D1<bool, int>() is Baz');
    expect$.Expect.isFalse(function_subtype_call2_test.Boz.is(new (D1Ofbool$int())()), 'new D1<bool, int>() is Boz');
    expect$.Expect.isTrue(function_subtype_call2_test.Foo.is(new function_subtype_call2_test.D1()), 'new D1() is Foo');
    expect$.Expect.isTrue(function_subtype_call2_test.Bar.is(new function_subtype_call2_test.D1()), 'new D1() is Bar');
    expect$.Expect.isFalse(function_subtype_call2_test.Baz.is(new function_subtype_call2_test.D1()), 'new D1() is Baz');
    expect$.Expect.isTrue(function_subtype_call2_test.Boz.is(new function_subtype_call2_test.D1()), 'new D1() is Boz');
    expect$.Expect.isFalse(function_subtype_call2_test.Foo.is(new (D2OfString$bool())()), 'new D2<String, bool>() is Foo');
    expect$.Expect.isFalse(function_subtype_call2_test.Bar.is(new (D2OfString$bool())()), 'new D2<String, bool>() is Bar');
    expect$.Expect.isTrue(function_subtype_call2_test.Baz.is(new (D2OfString$bool())()), 'new D2<String, bool>() is Baz');
    expect$.Expect.isTrue(function_subtype_call2_test.Boz.is(new (D2OfString$bool())()), 'new D2<String, bool>() is Boz');
    expect$.Expect.isFalse(function_subtype_call2_test.Foo.is(new (D2Ofbool$int())()), 'new D2<bool, int>() is Foo');
    expect$.Expect.isFalse(function_subtype_call2_test.Bar.is(new (D2Ofbool$int())()), 'new D2<bool, int>() is Bar');
    expect$.Expect.isFalse(function_subtype_call2_test.Baz.is(new (D2Ofbool$int())()), 'new D2<bool, int>() is Baz');
    expect$.Expect.isFalse(function_subtype_call2_test.Boz.is(new (D2Ofbool$int())()), 'new D2<bool, int>() is Boz');
    expect$.Expect.isFalse(function_subtype_call2_test.Foo.is(new function_subtype_call2_test.D2()), 'new D2() is Foo');
    expect$.Expect.isFalse(function_subtype_call2_test.Bar.is(new function_subtype_call2_test.D2()), 'new D2() is Bar');
    expect$.Expect.isTrue(function_subtype_call2_test.Baz.is(new function_subtype_call2_test.D2()), 'new D2() is Baz');
    expect$.Expect.isTrue(function_subtype_call2_test.Boz.is(new function_subtype_call2_test.D2()), 'new D2() is Boz');
  };
  dart.fn(function_subtype_call2_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype_call2_test = function_subtype_call2_test;
});
