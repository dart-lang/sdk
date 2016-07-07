dart_library.library('language/type_variable_typedef_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_variable_typedef_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_variable_typedef_test = Object.create(null);
  let Foo = () => (Foo = dart.constFn(type_variable_typedef_test.Foo$()))();
  let A = () => (A = dart.constFn(type_variable_typedef_test.A$()))();
  let B = () => (B = dart.constFn(type_variable_typedef_test.B$()))();
  let AOfint = () => (AOfint = dart.constFn(type_variable_typedef_test.A$(core.int)))();
  let AOfString = () => (AOfString = dart.constFn(type_variable_typedef_test.A$(core.String)))();
  let AOfdouble = () => (AOfdouble = dart.constFn(type_variable_typedef_test.A$(core.double)))();
  let intTodynamic = () => (intTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int])))();
  let StringTodynamic = () => (StringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  type_variable_typedef_test.Foo$ = dart.generic(T => {
    const Foo = dart.typedef('Foo', () => dart.functionType(dart.dynamic, [T]));
    return Foo;
  });
  type_variable_typedef_test.Foo = Foo();
  type_variable_typedef_test.A$ = dart.generic(T => {
    let FooOfT = () => (FooOfT = dart.constFn(type_variable_typedef_test.Foo$(T)))();
    let BOfFooOfT = () => (BOfFooOfT = dart.constFn(type_variable_typedef_test.B$(FooOfT())))();
    class A extends core.Object {
      m() {
        return new (BOfFooOfT())();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return A;
  });
  type_variable_typedef_test.A = A();
  type_variable_typedef_test.B$ = dart.generic(T => {
    class B extends core.Object {
      m(o) {
        return T.is(o);
      }
    }
    dart.addTypeTests(B);
    dart.setSignature(B, {
      methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
    });
    return B;
  });
  type_variable_typedef_test.B = B();
  type_variable_typedef_test.foo = function(i) {
  };
  dart.fn(type_variable_typedef_test.foo, intTodynamic());
  type_variable_typedef_test.bar = function(s) {
  };
  dart.fn(type_variable_typedef_test.bar, StringTodynamic());
  type_variable_typedef_test.main = function() {
    expect$.Expect.isTrue(dart.dsend(new (AOfint())().m(), 'm', type_variable_typedef_test.foo));
    expect$.Expect.isFalse(dart.dsend(new (AOfint())().m(), 'm', type_variable_typedef_test.bar));
    expect$.Expect.isFalse(dart.dsend(new (AOfString())().m(), 'm', type_variable_typedef_test.foo));
    expect$.Expect.isTrue(dart.dsend(new (AOfString())().m(), 'm', type_variable_typedef_test.bar));
    expect$.Expect.isFalse(dart.dsend(new (AOfdouble())().m(), 'm', type_variable_typedef_test.foo));
    expect$.Expect.isFalse(dart.dsend(new (AOfdouble())().m(), 'm', type_variable_typedef_test.bar));
  };
  dart.fn(type_variable_typedef_test.main, VoidTovoid());
  // Exports:
  exports.type_variable_typedef_test = type_variable_typedef_test;
});
