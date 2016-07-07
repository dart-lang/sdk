dart_library.library('lib/typed_data/typed_data_hierarchy_int64_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__typed_data_hierarchy_int64_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_data_hierarchy_int64_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_data_hierarchy_int64_test.inscrutable = null;
  typed_data_hierarchy_int64_test.implementsTypedData = function() {
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_int64_test.inscrutable, typed_data.Int64List.new(1))));
    expect$.Expect.isTrue(typed_data.TypedData.is(dart.dcall(typed_data_hierarchy_int64_test.inscrutable, typed_data.Uint64List.new(1))));
  };
  dart.fn(typed_data_hierarchy_int64_test.implementsTypedData, VoidTovoid());
  typed_data_hierarchy_int64_test.implementsList = function() {
    expect$.Expect.isTrue(ListOfint().is(dart.dcall(typed_data_hierarchy_int64_test.inscrutable, typed_data.Int64List.new(1))));
    expect$.Expect.isTrue(ListOfint().is(dart.dcall(typed_data_hierarchy_int64_test.inscrutable, typed_data.Uint64List.new(1))));
  };
  dart.fn(typed_data_hierarchy_int64_test.implementsList, VoidTovoid());
  typed_data_hierarchy_int64_test.main = function() {
    typed_data_hierarchy_int64_test.inscrutable = dart.fn(x => x, dynamicTodynamic());
    typed_data_hierarchy_int64_test.implementsTypedData();
    typed_data_hierarchy_int64_test.implementsList();
  };
  dart.fn(typed_data_hierarchy_int64_test.main, VoidTodynamic());
  // Exports:
  exports.typed_data_hierarchy_int64_test = typed_data_hierarchy_int64_test;
});
