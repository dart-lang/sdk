dart_library.library('language/function_subtype3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__function_subtype3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const function_subtype3_test = Object.create(null);
  let FunctionLike = () => (FunctionLike = dart.constFn(function_subtype3_test.FunctionLike$()))();
  let FunctionLikeOfString = () => (FunctionLikeOfString = dart.constFn(function_subtype3_test.FunctionLike$(core.String)))();
  let FunctionLikeOfint = () => (FunctionLikeOfint = dart.constFn(function_subtype3_test.FunctionLike$(core.int)))();
  let Foo = () => (Foo = dart.constFn(function_subtype3_test.Foo$()))();
  let FooOfTakeString = () => (FooOfTakeString = dart.constFn(function_subtype3_test.Foo$(function_subtype3_test.TakeString)))();
  let FooOfTakeInt = () => (FooOfTakeInt = dart.constFn(function_subtype3_test.Foo$(function_subtype3_test.TakeInt)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  function_subtype3_test.FunctionLike$ = dart.generic(T => {
    const FunctionLike = dart.callableClass(function FunctionLike(...args) {
      const self = this;
      function call(...args) {
        return self.call.apply(self, args);
      }
      call.__proto__ = this.__proto__;
      call.new.apply(call, args);
      return call;
    }, class FunctionLike extends core.Object {
      call(arg) {
        T._check(arg);
        return arg;
      }
    });
    dart.addTypeTests(FunctionLike);
    dart.setSignature(FunctionLike, {
      methods: () => ({call: dart.definiteFunctionType(dart.dynamic, [T])})
    });
    return FunctionLike;
  });
  function_subtype3_test.FunctionLike = FunctionLike();
  function_subtype3_test.Foo$ = dart.generic(T => {
    class Foo extends core.Object {
      testString() {
        return T.is(new (FunctionLikeOfString())());
      }
      testInt() {
        return T.is(new (FunctionLikeOfint())());
      }
    }
    dart.addTypeTests(Foo);
    dart.setSignature(Foo, {
      methods: () => ({
        testString: dart.definiteFunctionType(dart.dynamic, []),
        testInt: dart.definiteFunctionType(dart.dynamic, [])
      })
    });
    return Foo;
  });
  function_subtype3_test.Foo = Foo();
  function_subtype3_test.TakeString = dart.typedef('TakeString', () => dart.functionType(dart.dynamic, [core.String]));
  function_subtype3_test.TakeInt = dart.typedef('TakeInt', () => dart.functionType(dart.dynamic, [core.int]));
  function_subtype3_test.main = function() {
    let stringFoo = new (FooOfTakeString())();
    let intFoo = new (FooOfTakeInt())();
    expect$.Expect.isTrue(stringFoo.testString());
    expect$.Expect.isFalse(stringFoo.testInt());
    expect$.Expect.isFalse(intFoo.testString());
    expect$.Expect.isTrue(intFoo.testInt());
  };
  dart.fn(function_subtype3_test.main, VoidTodynamic());
  // Exports:
  exports.function_subtype3_test = function_subtype3_test;
});
