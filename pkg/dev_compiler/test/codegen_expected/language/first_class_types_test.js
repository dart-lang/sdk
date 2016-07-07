dart_library.library('language/first_class_types_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__first_class_types_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const first_class_types_test = Object.create(null);
  let C = () => (C = dart.constFn(first_class_types_test.C$()))();
  let COfint = () => (COfint = dart.constFn(first_class_types_test.C$(core.int)))();
  let COfnum = () => (COfnum = dart.constFn(first_class_types_test.C$(core.num)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let ListOfnum = () => (ListOfnum = dart.constFn(core.List$(core.num)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  first_class_types_test.C$ = dart.generic(T => {
    class C extends core.Object {}
    dart.addTypeTests(C);
    return C;
  });
  first_class_types_test.C = C();
  first_class_types_test.sameType = function(a, b) {
    expect$.Expect.equals(dart.runtimeType(a), dart.runtimeType(b));
  };
  dart.fn(first_class_types_test.sameType, dynamicAnddynamicTodynamic());
  first_class_types_test.differentType = function(a, b) {
    expect$.Expect.isFalse(dart.equals(dart.runtimeType(a), dart.runtimeType(b)));
  };
  dart.fn(first_class_types_test.differentType, dynamicAnddynamicTodynamic());
  first_class_types_test.main = function() {
    let v1 = new (COfint())();
    let v2 = new (COfint())();
    first_class_types_test.sameType(v1, v2);
    let v3 = new (COfnum())();
    first_class_types_test.differentType(v1, v3);
    let i = 1;
    let s = 'string';
    let d = 3.14;
    let b = true;
    first_class_types_test.sameType(2, i);
    first_class_types_test.sameType('hest', s);
    first_class_types_test.sameType(1.2, d);
    first_class_types_test.sameType(false, b);
    let l = JSArrayOfint().of([1, 2, 3]);
    let m = dart.map({a: 1, b: 2});
    first_class_types_test.sameType([], l);
    first_class_types_test.sameType(dart.map(), m);
    first_class_types_test.sameType(ListOfint().new(), ListOfint().new());
    first_class_types_test.differentType(ListOfint().new(), ListOfnum().new());
    first_class_types_test.differentType(ListOfint().new(), core.List.new());
  };
  dart.fn(first_class_types_test.main, VoidTodynamic());
  // Exports:
  exports.first_class_types_test = first_class_types_test;
});
