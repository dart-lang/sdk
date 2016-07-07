dart_library.library('lib/typed_data/typed_data_sublist_type_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__typed_data_sublist_type_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_data_sublist_type_test = Object.create(null);
  let Is = () => (Is = dart.constFn(typed_data_sublist_type_test.Is$()))();
  let IsOfFloat32List = () => (IsOfFloat32List = dart.constFn(typed_data_sublist_type_test.Is$(typed_data.Float32List)))();
  let IsOfFloat64List = () => (IsOfFloat64List = dart.constFn(typed_data_sublist_type_test.Is$(typed_data.Float64List)))();
  let IsOfInt8List = () => (IsOfInt8List = dart.constFn(typed_data_sublist_type_test.Is$(typed_data.Int8List)))();
  let IsOfInt16List = () => (IsOfInt16List = dart.constFn(typed_data_sublist_type_test.Is$(typed_data.Int16List)))();
  let IsOfInt32List = () => (IsOfInt32List = dart.constFn(typed_data_sublist_type_test.Is$(typed_data.Int32List)))();
  let IsOfUint8List = () => (IsOfUint8List = dart.constFn(typed_data_sublist_type_test.Is$(typed_data.Uint8List)))();
  let IsOfUint16List = () => (IsOfUint16List = dart.constFn(typed_data_sublist_type_test.Is$(typed_data.Uint16List)))();
  let IsOfUint32List = () => (IsOfUint32List = dart.constFn(typed_data_sublist_type_test.Is$(typed_data.Uint32List)))();
  let IsOfUint8ClampedList = () => (IsOfUint8ClampedList = dart.constFn(typed_data_sublist_type_test.Is$(typed_data.Uint8ClampedList)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let IsOfListOfint = () => (IsOfListOfint = dart.constFn(typed_data_sublist_type_test.Is$(ListOfint())))();
  let ListOfdouble = () => (ListOfdouble = dart.constFn(core.List$(core.double)))();
  let IsOfListOfdouble = () => (IsOfListOfdouble = dart.constFn(typed_data_sublist_type_test.Is$(ListOfdouble())))();
  let ListOfnum = () => (ListOfnum = dart.constFn(core.List$(core.num)))();
  let IsOfListOfnum = () => (IsOfListOfnum = dart.constFn(typed_data_sublist_type_test.Is$(ListOfnum())))();
  let IsOfList = () => (IsOfList = dart.constFn(typed_data_sublist_type_test.Is$(core.List)))();
  let JSArrayOfIsOfList = () => (JSArrayOfIsOfList = dart.constFn(_interceptors.JSArray$(IsOfList())))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTovoid = () => (dynamicAnddynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_data_sublist_type_test.inscrutable = null;
  typed_data_sublist_type_test.Is$ = dart.generic(T => {
    class Is extends core.Object {
      new(name) {
        this.name = name;
      }
      check(x) {
        return T.is(x);
      }
      expect(x, part) {
        expect$.Expect.isTrue(this.check(x), dart.str`(${part}: ${dart.runtimeType(x)}) is ${this.name}`);
      }
      expectNot(x, part) {
        expect$.Expect.isFalse(this.check(x), dart.str`(${part}: ${dart.runtimeType(x)}) is! ${this.name}`);
      }
    }
    dart.addTypeTests(Is);
    dart.setSignature(Is, {
      constructors: () => ({new: dart.definiteFunctionType(typed_data_sublist_type_test.Is$(T), [dart.dynamic])}),
      methods: () => ({
        check: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
        expect: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic]),
        expectNot: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])
      })
    });
    return Is;
  });
  typed_data_sublist_type_test.Is = Is();
  typed_data_sublist_type_test.testSublistType = function(input, positive, all) {
    let negative = dart.dsend(all, 'where', dart.fn(check => !dart.test(dart.dsend(positive, 'contains', check)), dynamicTobool()));
    input = dart.dcall(typed_data_sublist_type_test.inscrutable, input);
    for (let check of core.Iterable._check(positive))
      dart.dsend(check, 'expect', input, 'input');
    for (let check of core.Iterable._check(negative))
      dart.dsend(check, 'expectNot', input, 'input');
    let sub = dart.dcall(typed_data_sublist_type_test.inscrutable, dart.dsend(input, 'sublist', 1));
    for (let check of core.Iterable._check(positive))
      dart.dsend(check, 'expect', sub, 'sublist');
    for (let check of core.Iterable._check(negative))
      dart.dsend(check, 'expectNot', sub, 'sublist');
    let sub2 = dart.dcall(typed_data_sublist_type_test.inscrutable, dart.dsend(input, 'sublist', 10));
    expect$.Expect.equals(0, dart.dload(sub2, 'length'));
    for (let check of core.Iterable._check(positive))
      dart.dsend(check, 'expect', sub2, 'empty sublist');
    for (let check of core.Iterable._check(negative))
      dart.dsend(check, 'expectNot', sub2, 'empty sublist');
  };
  dart.fn(typed_data_sublist_type_test.testSublistType, dynamicAnddynamicAnddynamicTovoid());
  typed_data_sublist_type_test.testTypes = function() {
    let isFloat32list = new (IsOfFloat32List())('Float32List');
    let isFloat64list = new (IsOfFloat64List())('Float64List');
    let isInt8List = new (IsOfInt8List())('Int8List');
    let isInt16List = new (IsOfInt16List())('Int16List');
    let isInt32List = new (IsOfInt32List())('Int32List');
    let isUint8List = new (IsOfUint8List())('Uint8List');
    let isUint16List = new (IsOfUint16List())('Uint16List');
    let isUint32List = new (IsOfUint32List())('Uint32List');
    let isUint8ClampedList = new (IsOfUint8ClampedList())('Uint8ClampedList');
    let isIntList = new (IsOfListOfint())('List<int>');
    let isDoubleList = new (IsOfListOfdouble())('List<double>');
    let isNumList = new (IsOfListOfnum())('List<num>');
    let allChecks = JSArrayOfIsOfList().of([isFloat32list, isFloat64list, isInt8List, isInt16List, isInt32List, isUint8List, isUint16List, isUint32List, isUint8ClampedList]);
    function testInt(list, check) {
      typed_data_sublist_type_test.testSublistType(list, JSArrayOfIsOfList().of([IsOfList()._check(check), isIntList, isNumList]), allChecks);
    }
    dart.fn(testInt, dynamicAnddynamicTodynamic());
    function testDouble(list, check) {
      typed_data_sublist_type_test.testSublistType(list, JSArrayOfIsOfList().of([IsOfList()._check(check), isDoubleList, isNumList]), allChecks);
    }
    dart.fn(testDouble, dynamicAnddynamicTodynamic());
    testDouble(typed_data.Float32List.new(10), isFloat32list);
    testDouble(typed_data.Float64List.new(10), isFloat64list);
    testInt(typed_data.Int8List.new(10), isInt8List);
    testInt(typed_data.Int16List.new(10), isInt16List);
    testInt(typed_data.Int32List.new(10), isInt32List);
    testInt(typed_data.Uint8List.new(10), isUint8List);
    testInt(typed_data.Uint16List.new(10), isUint16List);
    testInt(typed_data.Uint32List.new(10), isUint32List);
    testInt(typed_data.Uint8ClampedList.new(10), isUint8ClampedList);
  };
  dart.fn(typed_data_sublist_type_test.testTypes, VoidTovoid());
  typed_data_sublist_type_test.main = function() {
    typed_data_sublist_type_test.inscrutable = dart.fn(x => x, dynamicTodynamic());
    typed_data_sublist_type_test.testTypes();
  };
  dart.fn(typed_data_sublist_type_test.main, VoidTodynamic());
  // Exports:
  exports.typed_data_sublist_type_test = typed_data_sublist_type_test;
});
