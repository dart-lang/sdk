dart_library.library('language/list_is_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_is_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_is_test = Object.create(null);
  let A = () => (A = dart.constFn(list_is_test.A$()))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let AOfdouble = () => (AOfdouble = dart.constFn(list_is_test.A$(core.double)))();
  let ListOfdouble = () => (ListOfdouble = dart.constFn(core.List$(core.double)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  list_is_test.A$ = dart.generic(T => {
    let ListOfT = () => (ListOfT = dart.constFn(core.List$(T)))();
    class A extends core.Object {
      bar() {
        return ListOfT().new();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return A;
  });
  list_is_test.A = A();
  list_is_test.main = function() {
    list_is_test.check(core.List.new(), true, true, true);
    list_is_test.check(ListOfint().new(), true, true, false);
    list_is_test.check(new list_is_test.A().bar(), true, true, true);
    list_is_test.check(new (AOfdouble())().bar(), true, false, true);
    list_is_test.check(new core.Object(), false, false, false);
  };
  dart.fn(list_is_test.main, VoidTodynamic());
  list_is_test.check = function(val, expectList, expectListInt, expectListDouble) {
    expect$.Expect.equals(expectList, core.List.is(val));
    expect$.Expect.equals(expectListInt, ListOfint().is(val));
    expect$.Expect.equals(expectListDouble, ListOfdouble().is(val));
  };
  dart.fn(list_is_test.check, dynamicAnddynamicAnddynamic__Todynamic());
  // Exports:
  exports.list_is_test = list_is_test;
});
