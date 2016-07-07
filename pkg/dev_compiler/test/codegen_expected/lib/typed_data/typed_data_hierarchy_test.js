dart_library.library('lib/typed_data/typed_data_hierarchy_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__typed_data_hierarchy_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_data_hierarchy_test = Object.create(null);
  let ListOfdouble = () => (ListOfdouble = dart.constFn(core.List$(core.double)))();
  let ListOfFloat32x4 = () => (ListOfFloat32x4 = dart.constFn(core.List$(typed_data.Float32x4)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_data_hierarchy_test.inscrutable = null;
  typed_data_hierarchy_test.testClampedList = function() {
    expect$.Expect.isTrue(typed_data.Uint8List.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8List.new(1))));
    expect$.Expect.isFalse(typed_data.Uint8List.is(typed_data.Uint8ClampedList.new(1)), 'Uint8ClampedList should not be a subtype of Uint8List ' + 'in optimizable test');
    expect$.Expect.isFalse(typed_data.Uint8List.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8ClampedList.new(1))), 'Uint8ClampedList should not be a subtype of Uint8List in dynamic test');
  };
  dart.fn(typed_data_hierarchy_test.testClampedList, VoidTovoid());
  typed_data_hierarchy_test.implementsTypedData = function() {
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.ByteData.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float32List.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float32x4List.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float64List.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int8List.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int16List.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int32List.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8List.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8ClampedList.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint16List.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint32List.new(1))));
  };
  dart.fn(typed_data_hierarchy_test.implementsTypedData, VoidTovoid());
  typed_data_hierarchy_test.implementsList = function() {
    expect$.Expect.isTrue(ListOfdouble().is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float32List.new(1))));
    expect$.Expect.isTrue(ListOfFloat32x4().is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float32x4List.new(1))));
    expect$.Expect.isTrue(ListOfdouble().is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Float64List.new(1))));
    expect$.Expect.isTrue(ListOfint().is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int8List.new(1))));
    expect$.Expect.isTrue(ListOfint().is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int16List.new(1))));
    expect$.Expect.isTrue(ListOfint().is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Int32List.new(1))));
    expect$.Expect.isTrue(ListOfint().is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8List.new(1))));
    expect$.Expect.isTrue(ListOfint().is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint8ClampedList.new(1))));
    expect$.Expect.isTrue(ListOfint().is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint16List.new(1))));
    expect$.Expect.isTrue(ListOfint().is(dart.dcall(typed_data_hierarchy_test.inscrutable, typed_data.Uint32List.new(1))));
  };
  dart.fn(typed_data_hierarchy_test.implementsList, VoidTovoid());
  typed_data_hierarchy_test.main = function() {
    typed_data_hierarchy_test.inscrutable = dart.fn(x => x, dynamicTodynamic());
    typed_data_hierarchy_test.testClampedList();
    typed_data_hierarchy_test.implementsTypedData();
    typed_data_hierarchy_test.implementsList();
  };
  dart.fn(typed_data_hierarchy_test.main, VoidTodynamic());
  // Exports:
  exports.typed_data_hierarchy_test = typed_data_hierarchy_test;
});
