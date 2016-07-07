dart_library.library('language/type_literal_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_literal_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_literal_test = Object.create(null);
  let Box = () => (Box = dart.constFn(type_literal_test.Box$()))();
  let GenericFunc = () => (GenericFunc = dart.constFn(type_literal_test.GenericFunc$()))();
  let BoxOfFoo = () => (BoxOfFoo = dart.constFn(type_literal_test.Box$(type_literal_test.Foo)))();
  let BoxOfBoxOfFoo = () => (BoxOfBoxOfFoo = dart.constFn(type_literal_test.Box$(BoxOfFoo())))();
  let GenericFuncOfint = () => (GenericFuncOfint = dart.constFn(type_literal_test.GenericFunc$(core.int)))();
  let BoxOfGenericFuncOfint = () => (BoxOfGenericFuncOfint = dart.constFn(type_literal_test.Box$(GenericFuncOfint())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let TypeAndStringTovoid = () => (TypeAndStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Type, core.String])))();
  type_literal_test.Foo = class Foo extends core.Object {
    static method() {
      return "result";
    }
  };
  dart.setSignature(type_literal_test.Foo, {
    statics: () => ({method: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['method']
  });
  type_literal_test.Foo.property = null;
  type_literal_test.Box$ = dart.generic(T => {
    class Box extends core.Object {
      get typeArg() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(Box);
    return Box;
  });
  type_literal_test.Box = Box();
  type_literal_test.Func = dart.typedef('Func', () => dart.functionType(core.int, [core.bool]));
  type_literal_test.GenericFunc$ = dart.generic(T => {
    const GenericFunc = dart.typedef('GenericFunc', () => dart.functionType(core.int, [T]));
    return GenericFunc;
  });
  type_literal_test.GenericFunc = GenericFunc();
  type_literal_test.main = function() {
    type_literal_test.testType(dart.wrapType(core.Object), "Object");
    type_literal_test.testType(dart.wrapType(core.Null), "Null");
    type_literal_test.testType(dart.wrapType(core.bool), "bool");
    type_literal_test.testType(dart.wrapType(core.double), "double");
    type_literal_test.testType(dart.wrapType(core.int), "int");
    type_literal_test.testType(dart.wrapType(core.num), "num");
    type_literal_test.testType(dart.wrapType(core.String), "String");
    type_literal_test.testType(dart.wrapType(type_literal_test.Foo), "Foo");
    type_literal_test.testType(dart.wrapType(type_literal_test.Box), "Box");
    type_literal_test.testType(new (BoxOfFoo())().typeArg, "Foo");
    type_literal_test.testType(new type_literal_test.Box().typeArg, "dynamic");
    type_literal_test.testType(new (BoxOfBoxOfFoo())().typeArg, "Box<Foo>");
    type_literal_test.testType(dart.wrapType(type_literal_test.Func), "Func((bool) -> int)");
    type_literal_test.testType(dart.wrapType(type_literal_test.GenericFunc), "GenericFunc((bottom) -> int)");
    type_literal_test.testType(new (BoxOfGenericFuncOfint())().typeArg, "GenericFunc((int) -> int)");
    expect$.Expect.identical(dart.wrapType(type_literal_test.Foo), dart.wrapType(type_literal_test.Foo));
    expect$.Expect.identical(dart.wrapType(type_literal_test.Box), dart.wrapType(type_literal_test.Box));
    expect$.Expect.identical(new (BoxOfFoo())().typeArg, new (BoxOfFoo())().typeArg);
    expect$.Expect.identical(dart.wrapType(type_literal_test.Func), dart.wrapType(type_literal_test.Func));
    type_literal_test.Foo.property = "value";
    expect$.Expect.equals("value", type_literal_test.Foo.property);
    expect$.Expect.equals("result", type_literal_test.Foo.method());
    type_literal_test.testType(dart.wrapType(type_literal_test.Foo), "Foo");
    type_literal_test.Foo.property = "value2";
    expect$.Expect.equals("value2", type_literal_test.Foo.property);
    expect$.Expect.equals("result", type_literal_test.Foo.method());
  };
  dart.fn(type_literal_test.main, VoidTodynamic());
  type_literal_test.testType = function(type, string) {
    expect$.Expect.equals(string, dart.toString(type));
    expect$.Expect.isTrue(core.Type.is(type));
  };
  dart.fn(type_literal_test.testType, TypeAndStringTovoid());
  // Exports:
  exports.type_literal_test = type_literal_test;
});
