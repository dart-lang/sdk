dart_library.library('language/regress_22700_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_22700_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_22700_test = Object.create(null);
  let WrapT = () => (WrapT = dart.constFn(regress_22700_test.WrapT$()))();
  let MyClass = () => (MyClass = dart.constFn(regress_22700_test.MyClass$()))();
  let MyClassOfString = () => (MyClassOfString = dart.constFn(regress_22700_test.MyClass$(core.String)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_22700_test.WrapT$ = dart.generic(T => {
    class WrapT extends core.Object {
      get type() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(WrapT);
    return WrapT;
  });
  regress_22700_test.WrapT = WrapT();
  regress_22700_test.printAndCheck = function(t) {
    core.print(t);
    expect$.Expect.equals(dart.wrapType(core.String), t);
  };
  dart.fn(regress_22700_test.printAndCheck, dynamicTodynamic());
  regress_22700_test.MyClass$ = dart.generic(T => {
    let WrapTOfT = () => (WrapTOfT = dart.constFn(regress_22700_test.WrapT$(T)))();
    class MyClass extends core.Object {
      static works() {
        let t = new (WrapTOfT())().type;
        regress_22700_test.printAndCheck(t);
      }
      static works2() {
        regress_22700_test.printAndCheck(dart.wrapType(T));
      }
    }
    dart.addTypeTests(MyClass);
    dart.setSignature(MyClass, {
      constructors: () => ({
        works: dart.definiteFunctionType(regress_22700_test.MyClass$(T), []),
        works2: dart.definiteFunctionType(regress_22700_test.MyClass$(T), [])
      })
    });
    return MyClass;
  });
  regress_22700_test.MyClass = MyClass();
  regress_22700_test.main = function() {
    MyClassOfString().works();
    MyClassOfString().works2();
  };
  dart.fn(regress_22700_test.main, VoidTodynamic());
  // Exports:
  exports.regress_22700_test = regress_22700_test;
});
