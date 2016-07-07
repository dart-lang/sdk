dart_library.library('language/type_variable_closure2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_variable_closure2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_variable_closure2_test = Object.create(null);
  let A = () => (A = dart.constFn(type_variable_closure2_test.A$()))();
  let C = () => (C = dart.constFn(type_variable_closure2_test.C$()))();
  let COfint = () => (COfint = dart.constFn(type_variable_closure2_test.C$(core.int)))();
  let AOfint = () => (AOfint = dart.constFn(type_variable_closure2_test.A$(core.int)))();
  let AOfString = () => (AOfString = dart.constFn(type_variable_closure2_test.A$(core.String)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let MapOfint$int = () => (MapOfint$int = dart.constFn(core.Map$(core.int, core.int)))();
  let MapOfString$int = () => (MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))();
  let MapOfint$String = () => (MapOfint$String = dart.constFn(core.Map$(core.int, core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_variable_closure2_test.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  type_variable_closure2_test.A = A();
  type_variable_closure2_test.C$ = dart.generic(T => {
    let AOfT = () => (AOfT = dart.constFn(type_variable_closure2_test.A$(T)))();
    let JSArrayOfT = () => (JSArrayOfT = dart.constFn(_interceptors.JSArray$(T)))();
    let ListOfT = () => (ListOfT = dart.constFn(core.List$(T)))();
    let MapOfT$T = () => (MapOfT$T = dart.constFn(core.Map$(T, T)))();
    let VoidToAOfT = () => (VoidToAOfT = dart.constFn(dart.definiteFunctionType(AOfT(), [])))();
    let VoidToListOfT = () => (VoidToListOfT = dart.constFn(dart.definiteFunctionType(ListOfT(), [])))();
    let VoidToMapOfT$T = () => (VoidToMapOfT$T = dart.constFn(dart.definiteFunctionType(MapOfT$T(), [])))();
    class C extends core.Object {
      a() {
        return dart.fn(() => new (AOfT())(), VoidToAOfT());
      }
      list() {
        return dart.fn(() => JSArrayOfT().of([]), VoidToListOfT());
      }
      map() {
        return dart.fn(() => dart.map({}, T, T), VoidToMapOfT$T());
      }
    }
    dart.addTypeTests(C);
    dart.setSignature(C, {
      methods: () => ({
        a: dart.definiteFunctionType(dart.dynamic, []),
        list: dart.definiteFunctionType(dart.dynamic, []),
        map: dart.definiteFunctionType(dart.dynamic, [])
      })
    });
    return C;
  });
  type_variable_closure2_test.C = C();
  type_variable_closure2_test.main = function() {
    expect$.Expect.isTrue(AOfint().is(dart.dcall(new (COfint())().a())));
    expect$.Expect.isFalse(AOfString().is(dart.dcall(new (COfint())().a())));
    expect$.Expect.isTrue(ListOfint().is(dart.dcall(new (COfint())().list())));
    expect$.Expect.isFalse(ListOfString().is(dart.dcall(new (COfint())().list())));
    expect$.Expect.isTrue(MapOfint$int().is(dart.dcall(new (COfint())().map())));
    expect$.Expect.isFalse(MapOfString$int().is(dart.dcall(new (COfint())().map())));
    expect$.Expect.isFalse(MapOfint$String().is(dart.dcall(new (COfint())().map())));
  };
  dart.fn(type_variable_closure2_test.main, VoidTodynamic());
  // Exports:
  exports.type_variable_closure2_test = type_variable_closure2_test;
});
