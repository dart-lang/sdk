dart_library.library('lib/typed_data/typed_list_iterable_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__typed_list_iterable_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_list_iterable_test = Object.create(null);
  let JSArrayOfdouble = () => (JSArrayOfdouble = dart.constFn(_interceptors.JSArray$(core.double)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicToList = () => (dynamicToList = dart.constFn(dart.definiteFunctionType(core.List, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicToint = () => (dynamicAnddynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTovoid = () => (dynamicAnddynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_list_iterable_test.testIterableFunctions = function(list, first, last) {
    dart.assert(dart.dsend(dart.dload(list, 'length'), '>', 0));
    expect$.Expect.equals(first, dart.dload(list, 'first'));
    expect$.Expect.equals(last, dart.dload(list, 'last'));
    expect$.Expect.equals(first, dart.dsend(list, 'firstWhere', dart.fn(x => dart.equals(x, first), dynamicTobool())));
    expect$.Expect.equals(last, dart.dsend(list, 'lastWhere', dart.fn(x => dart.equals(x, last), dynamicTobool())));
    if (dart.equals(dart.dload(list, 'length'), 1)) {
      expect$.Expect.equals(first, dart.dload(list, 'single'));
      expect$.Expect.equals(first, dart.dsend(list, 'singleWhere', dart.fn(x => dart.equals(x, last), dynamicTobool())));
    } else {
      expect$.Expect.throws(dart.fn(() => dart.dload(list, 'single'), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
      let isFirst = true;
      expect$.Expect.equals(first, dart.dsend(list, 'singleWhere', dart.fn(x => {
        if (isFirst) {
          isFirst = false;
          return true;
        }
        return false;
      }, dynamicTobool())));
    }
    expect$.Expect.isFalse(dart.dload(list, 'isEmpty'));
    let i = 0;
    for (let x of core.Iterable._check(list)) {
      expect$.Expect.equals(dart.dindex(list, i++), x);
    }
    expect$.Expect.isTrue(dart.dsend(list, 'any', dart.fn(x => dart.equals(x, last), dynamicTobool())));
    expect$.Expect.isFalse(dart.dsend(list, 'any', dart.fn(x => false, dynamicTobool())));
    expect$.Expect.isTrue(dart.dsend(list, 'contains', last));
    expect$.Expect.equals(first, dart.dsend(list, 'elementAt', 0));
    expect$.Expect.isTrue(dart.dsend(list, 'every', dart.fn(x => true, dynamicTobool())));
    expect$.Expect.isFalse(dart.dsend(list, 'every', dart.fn(x => !dart.equals(x, last), dynamicTobool())));
    expect$.Expect.listEquals([], core.List._check(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => [], dynamicToList())), 'toList')));
    let expand2 = dart.dsend(list, 'expand', dart.fn(x => [x, x], dynamicToList()));
    i = 0;
    for (let x of core.Iterable._check(expand2)) {
      expect$.Expect.equals(dart.dindex(list, (i / 2)[dartx.truncate]()), x);
      i++;
    }
    expect$.Expect.equals(2 * dart.notNull(core.num._check(dart.dload(list, 'length'))), i);
    expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(list, 'fold', [], dart.fn((result, x) => ((() => {
      dart.dsend(result, 'add', x);
      return result;
    })()), dynamicAnddynamicTodynamic()))));
    i = 0;
    dart.dsend(list, 'forEach', dart.fn(x => {
      expect$.Expect.equals(dart.dindex(list, i++), x);
    }, dynamicTodynamic()));
    expect$.Expect.equals(dart.dsend(dart.dsend(list, 'toList'), 'join', "*"), dart.dsend(list, 'join', "*"));
    expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'map', dart.fn(x => x, dynamicTodynamic())), 'toList')));
    let mapCount = 0;
    let mappedList = dart.dsend(list, 'map', dart.fn(x => {
      mapCount++;
      return x;
    }, dynamicTodynamic()));
    expect$.Expect.equals(0, mapCount);
    expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(mappedList, 'length'));
    expect$.Expect.equals(0, mapCount);
    dart.dsend(mappedList, 'join');
    expect$.Expect.equals(dart.dload(list, 'length'), mapCount);
    expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'where', dart.fn(x => true, dynamicTobool())), 'toList')));
    let whereCount = 0;
    let whereList = dart.dsend(list, 'where', dart.fn(x => {
      whereCount++;
      return true;
    }, dynamicTobool()));
    expect$.Expect.equals(0, whereCount);
    expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(whereList, 'length'));
    expect$.Expect.equals(dart.dload(list, 'length'), whereCount);
    if (dart.test(dart.dsend(dart.dload(list, 'length'), '>', 1))) {
      let reduceResult = 1;
      expect$.Expect.equals(dart.dload(list, 'length'), dart.dsend(list, 'reduce', dart.fn((x, y) => ++reduceResult, dynamicAnddynamicToint())));
    } else {
      expect$.Expect.equals(first, dart.dsend(list, 'reduce', dart.fn((x, y) => {
        dart.throw("should not be called");
      }, dynamicAnddynamicTodynamic())));
    }
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skip', dart.dload(list, 'length')), 'isEmpty'));
    expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'skip', 0), 'toList')));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skipWhile', dart.fn(x => true, dynamicTobool())), 'isEmpty'));
    expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'skipWhile', dart.fn(x => false, dynamicTobool())), 'toList')));
    expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'take', dart.dload(list, 'length')), 'toList')));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'take', 0), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'takeWhile', dart.fn(x => false, dynamicTobool())), 'isEmpty'));
    expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'takeWhile', dart.fn(x => true, dynamicTobool())), 'toList')));
    expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'toList'), 'toList')));
    let l2 = dart.dsend(list, 'toList');
    dart.dsend(l2, 'add', first);
    expect$.Expect.equals(first, dart.dload(l2, 'last'));
    let l3 = dart.dsend(list, 'toList', {growable: false});
    expect$.Expect.throws(dart.fn(() => dart.dsend(l3, 'add', last), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(typed_list_iterable_test.testIterableFunctions, dynamicAnddynamicAnddynamicTovoid());
  typed_list_iterable_test.emptyChecks = function(list) {
    dart.assert(dart.equals(dart.dload(list, 'length'), 0));
    expect$.Expect.isTrue(dart.dload(list, 'isEmpty'));
    expect$.Expect.throws(dart.fn(() => dart.dload(list, 'first'), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => dart.dload(list, 'last'), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => dart.dload(list, 'single'), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'firstWhere', dart.fn(x => true, dynamicTobool())), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'lastWhere', dart.fn(x => true, dynamicTobool())), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'singleWhere', dart.fn(x => true, dynamicTobool())), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.isFalse(dart.dsend(list, 'any', dart.fn(x => true, dynamicTobool())));
    expect$.Expect.isFalse(dart.dsend(list, 'contains', null));
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'elementAt', 0), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    expect$.Expect.isTrue(dart.dsend(list, 'every', dart.fn(x => false, dynamicTobool())));
    expect$.Expect.listEquals([], core.List._check(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => [], dynamicToList())), 'toList')));
    expect$.Expect.listEquals([], core.List._check(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => [x, x], dynamicToList())), 'toList')));
    expect$.Expect.listEquals([], core.List._check(dart.dsend(dart.dsend(list, 'expand', dart.fn(x => {
      dart.throw("should not be reached");
    }, dynamicTodynamic())), 'toList')));
    expect$.Expect.listEquals([], core.List._check(dart.dsend(list, 'fold', [], dart.fn((result, x) => ((() => {
      dart.dsend(result, 'add', x);
      return result;
    })()), dynamicAnddynamicTodynamic()))));
    expect$.Expect.equals(dart.dsend(dart.dsend(list, 'toList'), 'join', "*"), dart.dsend(list, 'join', "*"));
    expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'map', dart.fn(x => x, dynamicTodynamic())), 'toList')));
    let mapCount = 0;
    let mappedList = dart.dsend(list, 'map', dart.fn(x => {
      mapCount++;
      return x;
    }, dynamicTodynamic()));
    expect$.Expect.equals(0, mapCount);
    expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(mappedList, 'length'));
    expect$.Expect.equals(0, mapCount);
    dart.dsend(mappedList, 'join');
    expect$.Expect.equals(dart.dload(list, 'length'), mapCount);
    expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'where', dart.fn(x => true, dynamicTobool())), 'toList')));
    let whereCount = 0;
    let whereList = dart.dsend(list, 'where', dart.fn(x => {
      whereCount++;
      return true;
    }, dynamicTobool()));
    expect$.Expect.equals(0, whereCount);
    expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(whereList, 'length'));
    expect$.Expect.equals(dart.dload(list, 'length'), whereCount);
    expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'reduce', dart.fn((x, y) => x, dynamicAnddynamicTodynamic())), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skip', dart.dload(list, 'length')), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skip', 0), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skipWhile', dart.fn(x => true, dynamicTobool())), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'skipWhile', dart.fn(x => false, dynamicTobool())), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'take', dart.dload(list, 'length')), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'take', 0), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'takeWhile', dart.fn(x => false, dynamicTobool())), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'takeWhile', dart.fn(x => true, dynamicTobool())), 'isEmpty'));
    expect$.Expect.isTrue(dart.dload(dart.dsend(list, 'toList'), 'isEmpty'));
    let l2 = dart.dsend(list, 'toList');
    dart.dsend(l2, 'add', 0);
    expect$.Expect.equals(0, dart.dload(l2, 'last'));
    let l3 = dart.dsend(list, 'toList', {growable: false});
    expect$.Expect.throws(dart.fn(() => dart.dsend(l3, 'add', 0), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(typed_list_iterable_test.emptyChecks, dynamicTovoid());
  typed_list_iterable_test.main = function() {
    typed_list_iterable_test.testIterableFunctions(typed_data.Float32List.fromList(JSArrayOfdouble().of([1.5, 9.5])), 1.5, 9.5);
    typed_list_iterable_test.testIterableFunctions(typed_data.Float64List.fromList(JSArrayOfdouble().of([1.5, 9.5])), 1.5, 9.5);
    typed_list_iterable_test.testIterableFunctions(typed_data.Int8List.fromList(JSArrayOfint().of([3, 9])), 3, 9);
    typed_list_iterable_test.testIterableFunctions(typed_data.Int16List.fromList(JSArrayOfint().of([3, 9])), 3, 9);
    typed_list_iterable_test.testIterableFunctions(typed_data.Int32List.fromList(JSArrayOfint().of([3, 9])), 3, 9);
    typed_list_iterable_test.testIterableFunctions(typed_data.Uint8List.fromList(JSArrayOfint().of([3, 9])), 3, 9);
    typed_list_iterable_test.testIterableFunctions(typed_data.Uint16List.fromList(JSArrayOfint().of([3, 9])), 3, 9);
    typed_list_iterable_test.testIterableFunctions(typed_data.Uint32List.fromList(JSArrayOfint().of([3, 9])), 3, 9);
    typed_list_iterable_test.emptyChecks(typed_data.Float32List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Float64List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Int8List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Int16List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Int32List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Uint8List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Uint16List.new(0));
    typed_list_iterable_test.emptyChecks(typed_data.Uint32List.new(0));
  };
  dart.fn(typed_list_iterable_test.main, VoidTodynamic());
  // Exports:
  exports.typed_list_iterable_test = typed_list_iterable_test;
});
