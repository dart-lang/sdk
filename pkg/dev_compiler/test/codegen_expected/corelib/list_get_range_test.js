dart_library.library('corelib/list_get_range_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_get_range_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_get_range_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, core.bool])))();
  let VoidToIterableOfint = () => (VoidToIterableOfint = dart.constFn(dart.definiteFunctionType(IterableOfint(), [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let FunctionTovoid = () => (FunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Function])))();
  list_get_range_test.testGetRange = function(list, start, end, isModifiable) {
    list_get_range_test.expectRE(dart.fn(() => {
      dart.dsend(list, 'getRange', -1, 0);
    }, VoidTodynamic()));
    list_get_range_test.expectRE(dart.fn(() => {
      dart.dsend(list, 'getRange', 0, -1);
    }, VoidTodynamic()));
    list_get_range_test.expectRE(dart.fn(() => {
      dart.dsend(list, 'getRange', 1, 0);
    }, VoidTodynamic()));
    list_get_range_test.expectRE(dart.fn(() => {
      dart.dsend(list, 'getRange', 0, dart.dsend(dart.dload(list, 'length'), '+', 1));
    }, VoidTodynamic()));
    list_get_range_test.expectRE(dart.fn(() => {
      dart.dsend(list, 'getRange', dart.dsend(dart.dload(list, 'length'), '+', 1), dart.dsend(dart.dload(list, 'length'), '+', 1));
    }, VoidTodynamic()));
    let iterable = core.Iterable._check(dart.dsend(list, 'getRange', start, end));
    expect$.Expect.isFalse(core.List.is(iterable));
    if (dart.equals(start, end)) {
      expect$.Expect.isTrue(iterable[dartx.isEmpty]);
      return;
    }
    let iterator = iterable[dartx.iterator];
    for (let i = core.int._check(start); dart.notNull(i) < dart.notNull(core.num._check(end)); i = dart.notNull(i) + 1) {
      expect$.Expect.isTrue(iterator.moveNext());
      expect$.Expect.equals(iterator.current, dart.dindex(list, i));
    }
    expect$.Expect.isFalse(iterator.moveNext());
    if (dart.test(isModifiable)) {
      for (let i = 0; i < dart.notNull(core.num._check(dart.dload(list, 'length'))); i++) {
        dart.dsetindex(list, i, dart.dsend(dart.dindex(list, i), '+', 1));
      }
      iterator = iterable[dartx.iterator];
      for (let i = core.int._check(start); dart.notNull(i) < dart.notNull(core.num._check(end)); i = dart.notNull(i) + 1) {
        expect$.Expect.isTrue(iterator.moveNext());
        expect$.Expect.equals(iterator.current, dart.dindex(list, i));
      }
    }
  };
  dart.fn(list_get_range_test.testGetRange, dynamicAnddynamicAnddynamic__Todynamic());
  let const$;
  let const$0;
  let const$1;
  let const$2;
  list_get_range_test.main = function() {
    list_get_range_test.testGetRange(JSArrayOfint().of([1, 2]), 0, 1, true);
    list_get_range_test.testGetRange([], 0, 0, true);
    list_get_range_test.testGetRange(JSArrayOfint().of([1, 2, 3]), 0, 0, true);
    list_get_range_test.testGetRange(JSArrayOfint().of([1, 2, 3]), 1, 3, true);
    list_get_range_test.testGetRange(const$ || (const$ = dart.constList([1, 2], core.int)), 0, 1, false);
    list_get_range_test.testGetRange(const$0 || (const$0 = dart.constList([], dart.dynamic)), 0, 0, false);
    list_get_range_test.testGetRange(const$1 || (const$1 = dart.constList([1, 2, 3], core.int)), 0, 0, false);
    list_get_range_test.testGetRange(const$2 || (const$2 = dart.constList([1, 2, 3], core.int)), 1, 3, false);
    list_get_range_test.testGetRange("abcd"[dartx.codeUnits], 0, 1, false);
    list_get_range_test.testGetRange("abcd"[dartx.codeUnits], 0, 0, false);
    list_get_range_test.testGetRange("abcd"[dartx.codeUnits], 1, 3, false);
    list_get_range_test.expectRE(dart.fn(() => JSArrayOfint().of([1])[dartx.getRange](-1, 1), VoidToIterableOfint()));
    list_get_range_test.expectRE(dart.fn(() => JSArrayOfint().of([3])[dartx.getRange](0, -1), VoidToIterableOfint()));
    list_get_range_test.expectRE(dart.fn(() => JSArrayOfint().of([4])[dartx.getRange](1, 0), VoidToIterableOfint()));
    let list = JSArrayOfint().of([1, 2, 3, 4]);
    let iterable = list[dartx.getRange](1, 3);
    expect$.Expect.equals(2, iterable[dartx.first]);
    expect$.Expect.equals(3, iterable[dartx.last]);
    list[dartx.length] = 1;
    expect$.Expect.isTrue(iterable[dartx.isEmpty]);
    list[dartx.add](99);
    expect$.Expect.equals(99, iterable[dartx.single]);
    list[dartx.add](499);
    expect$.Expect.equals(499, iterable[dartx.last]);
    expect$.Expect.equals(2, iterable[dartx.length]);
  };
  dart.fn(list_get_range_test.main, VoidTodynamic());
  list_get_range_test.expectRE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(list_get_range_test.expectRE, FunctionTovoid());
  // Exports:
  exports.list_get_range_test = list_get_range_test;
});
