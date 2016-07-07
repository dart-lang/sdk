dart_library.library('language/constructor12_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor12_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor12_test = Object.create(null);
  let A = () => (A = dart.constFn(constructor12_test.A$()))();
  let AOfint = () => (AOfint = dart.constFn(constructor12_test.A$(core.int)))();
  let AOfString = () => (AOfString = dart.constFn(constructor12_test.A$(core.String)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  constructor12_test.B = class B extends core.Object {
    new(z) {
      this.z = z;
    }
    foo() {
      return this.z;
    }
  };
  dart.setSignature(constructor12_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(constructor12_test.B, [dart.dynamic])}),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  constructor12_test.A$ = dart.generic(T => {
    let JSArrayOfT = () => (JSArrayOfT = dart.constFn(_interceptors.JSArray$(T)))();
    class A extends constructor12_test.B {
      new(p) {
        this.captured = dart.fn(() => p, VoidTodynamic());
        this.captured2 = null;
        this.typedList = null;
        super.new((() => {
          let x = p;
          p = dart.dsend(x, '+', 1);
          return x;
        })());
        try {
        } catch (e) {
        }

        this.captured2 = dart.fn(() => (() => {
          let x = p;
          p = dart.dsend(x, '+', 1);
          return x;
        })(), VoidTodynamic());
        this.typedList = JSArrayOfT().of([]);
      }
      foo() {
        return dart.dcall(this.captured);
      }
      bar() {
        return dart.dcall(this.captured2);
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(constructor12_test.A$(T), [dart.dynamic])}),
      methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return A;
  });
  constructor12_test.A = A();
  constructor12_test.confuse = function(x) {
    return x;
  };
  dart.fn(constructor12_test.confuse, dynamicTodynamic());
  constructor12_test.main = function() {
    let a = constructor12_test.confuse(new (AOfint())(1));
    let a2 = constructor12_test.confuse(new constructor12_test.A(2));
    let b = constructor12_test.confuse(new constructor12_test.B(3));
    expect$.Expect.equals(2, dart.dsend(a, 'foo'));
    expect$.Expect.equals(3, dart.dsend(a2, 'foo'));
    expect$.Expect.equals(3, dart.dsend(b, 'foo'));
    expect$.Expect.equals(1, dart.dload(a, 'z'));
    expect$.Expect.equals(2, dart.dload(a2, 'z'));
    expect$.Expect.equals(3, dart.dload(b, 'z'));
    expect$.Expect.isTrue(AOfint().is(a));
    expect$.Expect.isFalse(AOfString().is(a));
    expect$.Expect.isTrue(AOfint().is(a2));
    expect$.Expect.isTrue(AOfString().is(a2));
    expect$.Expect.equals(2, dart.dsend(a, 'bar'));
    expect$.Expect.equals(3, dart.dsend(a2, 'bar'));
    expect$.Expect.equals(3, dart.dsend(a, 'foo'));
    expect$.Expect.equals(4, dart.dsend(a2, 'foo'));
    expect$.Expect.equals(0, dart.dload(dart.dload(a, 'typedList'), 'length'));
    expect$.Expect.equals(0, dart.dload(dart.dload(a2, 'typedList'), 'length'));
    dart.dsend(dart.dload(a, 'typedList'), 'add', 499);
    expect$.Expect.equals(1, dart.dload(dart.dload(a, 'typedList'), 'length'));
    expect$.Expect.equals(0, dart.dload(dart.dload(a2, 'typedList'), 'length'));
    expect$.Expect.isTrue(ListOfint().is(dart.dload(a, 'typedList')));
    expect$.Expect.isTrue(ListOfint().is(dart.dload(a2, 'typedList')));
    expect$.Expect.isFalse(ListOfString().is(dart.dload(a, 'typedList')));
    expect$.Expect.isTrue(ListOfString().is(dart.dload(a2, 'typedList')));
  };
  dart.fn(constructor12_test.main, VoidTodynamic());
  // Exports:
  exports.constructor12_test = constructor12_test;
});
