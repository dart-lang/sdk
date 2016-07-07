dart_library.library('lib/typed_data/typed_data_list_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__typed_data_list_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_data_list_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfdouble = () => (JSArrayOfdouble = dart.constFn(_interceptors.JSArray$(core.double)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamic__Tovoid = () => (dynamicAnddynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(T => [dart.void, [dart.dynamic, dart.dynamic, dart.dynamic, dart.functionType(T, [dart.dynamic])]])))();
  let dynamicAndFnTovoid = () => (dynamicAndFnTovoid = dart.constFn(dart.definiteFunctionType(T => [dart.void, [dart.dynamic, dart.functionType(T, [dart.dynamic])]])))();
  let dynamicTodouble = () => (dynamicTodouble = dart.constFn(dart.definiteFunctionType(core.double, [dart.dynamic])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_data_list_test.confuse = function(x) {
    return x;
  };
  dart.fn(typed_data_list_test.confuse, dynamicTodynamic());
  typed_data_list_test.testListFunctions = function(T) {
    return (list, first, last, toElementType) => {
      dart.assert(dart.dsend(dart.dload(list, 'length'), '>', 0));
      let reversed = dart.dload(list, 'reversed');
      expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dload(dart.dsend(reversed, 'toList'), 'reversed'), 'toList')));
      let index = core.int._check(dart.dsend(dart.dload(list, 'length'), '-', 1));
      for (let x of core.Iterable._check(reversed)) {
        expect$.Expect.equals(dart.dindex(list, index), x);
        index = dart.notNull(index) - 1;
      }
      let zero = dart.dcall(toElementType, 0);
      let one = dart.dcall(toElementType, 1);
      let two = dart.dcall(toElementType, 2);
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'add', zero), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'addAll', _interceptors.JSArray$(T).of([one, two])), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'clear'), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'insert', 0, zero), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'insertAll', 0, _interceptors.JSArray$(T).of([one, two])), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'remove', zero), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeAt', 0), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeLast'), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeRange', 0, 1), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeWhere', dart.fn(x => true, dynamicTobool())), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'replaceRange', 0, 1, []), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'retainWhere', dart.fn(x => true, dynamicTobool())), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      let map = dart.dsend(list, 'asMap');
      expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(map, 'length'));
      expect$.Expect.isTrue(core.Map.is(map));
      expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dload(map, 'values'), 'toList')));
      for (let i = 0; i < dart.notNull(core.num._check(dart.dload(list, 'length'))); i++) {
        expect$.Expect.equals(dart.dindex(list, i), dart.dindex(map, i));
      }
      expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'getRange', 0, dart.dload(list, 'length')), 'toList')));
      let subRange = dart.dsend(dart.dsend(list, 'getRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), 'toList');
      expect$.Expect.equals(dart.dsend(dart.dload(list, 'length'), '-', 2), dart.dload(subRange, 'length'));
      index = 1;
      for (let x of core.Iterable._check(subRange)) {
        expect$.Expect.equals(dart.dindex(list, index), x);
        index = dart.notNull(index) + 1;
      }
      expect$.Expect.equals(0, dart.dsend(list, 'lastIndexOf', first));
      expect$.Expect.equals(dart.dsend(dart.dload(list, 'length'), '-', 1), dart.dsend(list, 'lastIndexOf', last));
      expect$.Expect.equals(-1, dart.dsend(list, 'lastIndexOf', -1));
      let copy = dart.dsend(list, 'toList');
      dart.dsend(list, 'fillRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), dart.dcall(toElementType, 0));
      expect$.Expect.equals(dart.dload(copy, 'first'), dart.dload(list, 'first'));
      expect$.Expect.equals(dart.dload(copy, 'last'), dart.dload(list, 'last'));
      for (let i = 1; i < dart.notNull(core.num._check(dart.dsend(dart.dload(list, 'length'), '-', 1))); i++) {
        expect$.Expect.equals(0, dart.dindex(list, i));
      }
      dart.dsend(list, 'setAll', 1, dart.dsend(dart.dsend(list, 'getRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), 'map', dart.fn(x => dart.dcall(toElementType, 2), dart.definiteFunctionType(T, [dart.dynamic]))));
      expect$.Expect.equals(dart.dload(copy, 'first'), dart.dload(list, 'first'));
      expect$.Expect.equals(dart.dload(copy, 'last'), dart.dload(list, 'last'));
      for (let i = 1; i < dart.notNull(core.num._check(dart.dsend(dart.dload(list, 'length'), '-', 1))); i++) {
        expect$.Expect.equals(2, dart.dindex(list, i));
      }
      dart.dsend(list, 'setRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), core.Iterable.generate(core.int._check(dart.dsend(dart.dload(list, 'length'), '-', 2)), dart.fn(x => dart.dcall(toElementType, dart.notNull(x) + 5), dart.definiteFunctionType(T, [core.int]))));
      expect$.Expect.equals(first, dart.dload(list, 'first'));
      expect$.Expect.equals(last, dart.dload(list, 'last'));
      for (let i = 1; i < dart.notNull(core.num._check(dart.dsend(dart.dload(list, 'length'), '-', 1))); i++) {
        expect$.Expect.equals(4 + i, dart.dindex(list, i));
      }
      dart.dsend(list, 'setRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), core.Iterable.generate(core.int._check(dart.dsend(dart.dload(list, 'length'), '-', 1)), dart.fn(x => dart.dcall(toElementType, dart.notNull(x) + 5), dart.definiteFunctionType(T, [core.int]))), 1);
      expect$.Expect.equals(first, dart.dload(list, 'first'));
      expect$.Expect.equals(last, dart.dload(list, 'last'));
      for (let i = 1; i < dart.notNull(core.num._check(dart.dsend(dart.dload(list, 'length'), '-', 1))); i++) {
        expect$.Expect.equals(5 + i, dart.dindex(list, i));
      }
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'setRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1), []), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
      for (let i = 0; i < dart.notNull(core.num._check(dart.dload(list, 'length'))); i++) {
        dart.dsetindex(list, dart.dsend(dart.dsend(dart.dload(list, 'length'), '-', 1), '-', i), dart.dcall(toElementType, i));
      }
      dart.dsend(list, 'sort');
      for (let i = 0; i < dart.notNull(core.num._check(dart.dload(list, 'length'))); i++) {
        expect$.Expect.equals(i, dart.dindex(list, i));
      }
      expect$.Expect.listEquals(core.List._check(dart.dsend(dart.dsend(list, 'getRange', 1, dart.dsend(dart.dload(list, 'length'), '-', 1)), 'toList')), core.List._check(dart.dsend(list, 'sublist', 1, dart.dsend(dart.dload(list, 'length'), '-', 1))));
      expect$.Expect.listEquals(core.List._check(dart.dsend(dart.dsend(list, 'getRange', 1, dart.dload(list, 'length')), 'toList')), core.List._check(dart.dsend(list, 'sublist', 1)));
      expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(list, 'sublist', 0)));
      expect$.Expect.listEquals([], core.List._check(dart.dsend(list, 'sublist', 0, 0)));
      expect$.Expect.listEquals([], core.List._check(dart.dsend(list, 'sublist', dart.dload(list, 'length'))));
      expect$.Expect.listEquals([], core.List._check(dart.dsend(list, 'sublist', dart.dload(list, 'length'), dart.dload(list, 'length'))));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'sublist', dart.dsend(dart.dload(list, 'length'), '+', 1)), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'sublist', 0, dart.dsend(dart.dload(list, 'length'), '+', 1)), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'sublist', 1, 0), VoidTovoid()), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
    };
  };
  dart.fn(typed_data_list_test.testListFunctions, dynamicAnddynamicAnddynamic__Tovoid());
  typed_data_list_test.emptyChecks = function(T) {
    return (list, toElementType) => {
      dart.assert(dart.equals(dart.dload(list, 'length'), 0));
      expect$.Expect.isTrue(dart.dload(list, 'isEmpty'));
      let reversed = dart.dload(list, 'reversed');
      expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dload(dart.dsend(reversed, 'toList'), 'reversed'), 'toList')));
      let zero = dart.dcall(toElementType, 0);
      let one = dart.dcall(toElementType, 1);
      let two = dart.dcall(toElementType, 2);
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'add', zero), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'addAll', _interceptors.JSArray$(T).of([one, two])), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'clear'), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'insert', 0, zero), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'insertAll', 0, _interceptors.JSArray$(T).of([one, two])), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'remove', zero), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeAt', 0), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeLast'), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeRange', 0, 1), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'removeWhere', dart.fn(x => true, dynamicTobool())), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'replaceRange', 0, 1, []), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.throws(dart.fn(() => dart.dsend(list, 'retainWhere', dart.fn(x => true, dynamicTobool())), VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      let map = dart.dsend(list, 'asMap');
      expect$.Expect.equals(dart.dload(list, 'length'), dart.dload(map, 'length'));
      expect$.Expect.isTrue(core.Map.is(map));
      expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dload(map, 'values'), 'toList')));
      for (let i = 0; i < dart.notNull(core.num._check(dart.dload(list, 'length'))); i++) {
        expect$.Expect.equals(dart.dindex(list, i), dart.dindex(map, i));
      }
      expect$.Expect.listEquals(core.List._check(list), core.List._check(dart.dsend(dart.dsend(list, 'getRange', 0, dart.dload(list, 'length')), 'toList')));
      expect$.Expect.equals(-1, dart.dsend(list, 'lastIndexOf', -1));
      let copy = dart.dsend(list, 'toList');
      dart.dsend(list, 'fillRange', 0, 0);
      expect$.Expect.listEquals([], core.List._check(dart.dsend(dart.dsend(list, 'getRange', 0, 0), 'toList')));
      dart.dsend(list, 'setRange', 0, 0, JSArrayOfint().of([1, 2]));
      dart.dsend(list, 'sort');
      expect$.Expect.listEquals([], core.List._check(dart.dsend(list, 'sublist', 0, 0)));
    };
  };
  dart.fn(typed_data_list_test.emptyChecks, dynamicAndFnTovoid());
  typed_data_list_test.main = function() {
    function toDouble(x) {
      return core.double._check(dart.dsend(x, 'toDouble'));
    }
    dart.fn(toDouble, dynamicTodouble());
    function toInt(x) {
      return core.int._check(dart.dsend(x, 'toInt'));
    }
    dart.fn(toInt, dynamicToint());
    typed_data_list_test.testListFunctions(core.double)(typed_data.Float32List.fromList(JSArrayOfdouble().of([1.5, 6.3, 9.5])), 1.5, 9.5, toDouble);
    typed_data_list_test.testListFunctions(core.double)(typed_data.Float64List.fromList(JSArrayOfdouble().of([1.5, 6.3, 9.5])), 1.5, 9.5, toDouble);
    typed_data_list_test.testListFunctions(core.int)(typed_data.Int8List.fromList(JSArrayOfint().of([3, 5, 9])), 3, 9, toInt);
    typed_data_list_test.testListFunctions(core.int)(typed_data.Int16List.fromList(JSArrayOfint().of([3, 5, 9])), 3, 9, toInt);
    typed_data_list_test.testListFunctions(core.int)(typed_data.Int32List.fromList(JSArrayOfint().of([3, 5, 9])), 3, 9, toInt);
    typed_data_list_test.testListFunctions(core.int)(typed_data.Uint8List.fromList(JSArrayOfint().of([3, 5, 9])), 3, 9, toInt);
    typed_data_list_test.testListFunctions(core.int)(typed_data.Uint16List.fromList(JSArrayOfint().of([3, 5, 9])), 3, 9, toInt);
    typed_data_list_test.testListFunctions(core.int)(typed_data.Uint32List.fromList(JSArrayOfint().of([3, 5, 9])), 3, 9, toInt);
    typed_data_list_test.emptyChecks(core.double)(typed_data.Float32List.new(0), toDouble);
    typed_data_list_test.emptyChecks(core.double)(typed_data.Float64List.new(0), toDouble);
    typed_data_list_test.emptyChecks(core.int)(typed_data.Int8List.new(0), toInt);
    typed_data_list_test.emptyChecks(core.int)(typed_data.Int16List.new(0), toInt);
    typed_data_list_test.emptyChecks(core.int)(typed_data.Int32List.new(0), toInt);
    typed_data_list_test.emptyChecks(core.int)(typed_data.Uint8List.new(0), toInt);
    typed_data_list_test.emptyChecks(core.int)(typed_data.Uint16List.new(0), toInt);
    typed_data_list_test.emptyChecks(core.int)(typed_data.Uint32List.new(0), toInt);
  };
  dart.fn(typed_data_list_test.main, VoidTodynamic());
  // Exports:
  exports.typed_data_list_test = typed_data_list_test;
});
