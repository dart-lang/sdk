dart_library.library('corelib/iterable_contains_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_contains_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_contains_test = Object.create(null);
  let JSArrayOfC = () => (JSArrayOfC = dart.constFn(_interceptors.JSArray$(iterable_contains_test.C)))();
  let JSArrayOfNiet = () => (JSArrayOfNiet = dart.constFn(_interceptors.JSArray$(iterable_contains_test.Niet)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  iterable_contains_test.test = function(list, notInList) {
    function testList(list) {
      for (let i = 0; i < dart.notNull(core.num._check(dart.dload(list, 'length'))); i++) {
        let elem = dart.dindex(list, i);
        expect$.Expect.isTrue(dart.dsend(list, 'contains', dart.dindex(list, i)), dart.str`${list}.contains(${elem})`);
      }
      expect$.Expect.isFalse(dart.dsend(list, 'contains', notInList), dart.str`!${list}.contains(${notInList})`);
    }
    dart.fn(testList, dynamicTodynamic());
    let fixedList = core.List.new(core.int._check(dart.dload(list, 'length')));
    let growList = core.List.new();
    for (let i = 0; i < dart.notNull(core.num._check(dart.dload(list, 'length'))); i++) {
      fixedList[dartx.set](i, dart.dindex(list, i));
      growList[dartx.add](dart.dindex(list, i));
    }
    testList(list);
    testList(fixedList);
    testList(growList);
  };
  dart.fn(iterable_contains_test.test, dynamicAnddynamicTodynamic());
  iterable_contains_test.C = class C extends core.Object {
    new() {
    }
  };
  dart.setSignature(iterable_contains_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(iterable_contains_test.C, [])})
  });
  iterable_contains_test.Niet = class Niet extends core.Object {
    ['=='](other) {
      return false;
    }
  };
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  let const$4;
  let const$5;
  let const$6;
  let const$7;
  iterable_contains_test.main = function() {
    iterable_contains_test.test(const$ || (const$ = dart.constList(["a", "b", "c", null], core.String)), "d");
    iterable_contains_test.test(const$0 || (const$0 = dart.constList([1, 2, 3, null], core.int)), 0);
    iterable_contains_test.test(const$1 || (const$1 = dart.constList([true, false], core.bool)), null);
    iterable_contains_test.test(const$4 || (const$4 = dart.constList([const$2 || (const$2 = dart.const(new iterable_contains_test.C())), const$3 || (const$3 = dart.const(new iterable_contains_test.C())), null], iterable_contains_test.C)), new iterable_contains_test.C());
    iterable_contains_test.test(JSArrayOfC().of([new iterable_contains_test.C(), new iterable_contains_test.C(), new iterable_contains_test.C(), null]), new iterable_contains_test.C());
    iterable_contains_test.test(const$5 || (const$5 = dart.constList([0.0, 1.0, 5e-324, 1e+308, core.double.INFINITY], core.double)), 2.0);
    expect$.Expect.isTrue((const$6 || (const$6 = dart.constList([-0.0], core.double)))[dartx.contains](0.0));
    expect$.Expect.isFalse((const$7 || (const$7 = dart.constList([core.double.NAN], core.double)))[dartx.contains](core.double.NAN));
    let niet = new iterable_contains_test.Niet();
    expect$.Expect.isFalse(JSArrayOfNiet().of([niet])[dartx.contains](niet));
  };
  dart.fn(iterable_contains_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_contains_test = iterable_contains_test;
});
