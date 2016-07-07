dart_library.library('language/instanceof4_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__instanceof4_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const instanceof4_test_none_multi = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let Foo = () => (Foo = dart.constFn(instanceof4_test_none_multi.Foo$()))();
  let FooOfString = () => (FooOfString = dart.constFn(instanceof4_test_none_multi.Foo$(core.String)))();
  let FooOfint = () => (FooOfint = dart.constFn(instanceof4_test_none_multi.Foo$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  instanceof4_test_none_multi.Foo$ = dart.generic(T => {
    let ListOfT = () => (ListOfT = dart.constFn(core.List$(T)))();
    class Foo extends core.Object {
      isT() {
        return T.is("a string");
      }
      isNotT() {
        return !T.is("a string");
      }
      isListT() {
        return ListOfT().is(JSArrayOfint().of([0, 1, 2]));
      }
      isNotListT() {
        return !ListOfT().is(JSArrayOfint().of([0, 1, 2]));
      }
      isAlsoListT() {
        return ListOfT().is(JSArrayOfint().of([0, 1, 2]));
      }
      isNeitherListT() {
        return !ListOfT().is(JSArrayOfint().of([0, 1, 2]));
      }
    }
    dart.addTypeTests(Foo);
    dart.setSignature(Foo, {
      methods: () => ({
        isT: dart.definiteFunctionType(core.bool, []),
        isNotT: dart.definiteFunctionType(core.bool, []),
        isListT: dart.definiteFunctionType(core.bool, []),
        isNotListT: dart.definiteFunctionType(core.bool, []),
        isAlsoListT: dart.definiteFunctionType(core.bool, []),
        isNeitherListT: dart.definiteFunctionType(core.bool, [])
      })
    });
    return Foo;
  });
  instanceof4_test_none_multi.Foo = Foo();
  instanceof4_test_none_multi.testFooString = function() {
    let o = new (FooOfString())();
    expect$.Expect.isTrue(o.isT());
    expect$.Expect.isTrue(!dart.test(o.isNotT()));
    expect$.Expect.isTrue(o.isListT());
    expect$.Expect.isTrue(!dart.test(o.isNotListT()));
    for (let i = 0; i < 20; i++) {
      o.isT();
      o.isNotT();
      o.isListT();
      o.isNotListT();
    }
    expect$.Expect.isTrue(o.isT(), "1");
    expect$.Expect.isTrue(!dart.test(o.isNotT()), "2");
    expect$.Expect.isTrue(o.isListT(), "3");
    expect$.Expect.isTrue(!dart.test(o.isNotListT()), "4");
  };
  dart.fn(instanceof4_test_none_multi.testFooString, VoidTodynamic());
  instanceof4_test_none_multi.testFooInt = function() {
    let o = new (FooOfint())();
    expect$.Expect.isTrue(!dart.test(o.isT()));
    expect$.Expect.isTrue(o.isNotT());
    expect$.Expect.isTrue(o.isListT());
    expect$.Expect.isTrue(!dart.test(o.isNotListT()));
    expect$.Expect.isTrue(o.isAlsoListT());
    expect$.Expect.isTrue(!dart.test(o.isNeitherListT()));
    for (let i = 0; i < 20; i++) {
      o.isT();
      o.isNotT();
      o.isListT();
      o.isNotListT();
      o.isAlsoListT();
      o.isNeitherListT();
    }
    expect$.Expect.isTrue(!dart.test(o.isT()));
    expect$.Expect.isTrue(o.isNotT());
    expect$.Expect.isTrue(o.isListT());
    expect$.Expect.isTrue(!dart.test(o.isNotListT()));
    expect$.Expect.isTrue(o.isAlsoListT());
    expect$.Expect.isTrue(!dart.test(o.isNeitherListT()));
  };
  dart.fn(instanceof4_test_none_multi.testFooInt, VoidTodynamic());
  instanceof4_test_none_multi.main = function() {
    instanceof4_test_none_multi.testFooString();
    instanceof4_test_none_multi.testFooInt();
  };
  dart.fn(instanceof4_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.instanceof4_test_none_multi = instanceof4_test_none_multi;
});
