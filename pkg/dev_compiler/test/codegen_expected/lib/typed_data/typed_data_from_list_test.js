dart_library.library('lib/typed_data/typed_data_from_list_test', null, /* Imports */[
  'dart_sdk'
], function load__typed_data_from_list_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const typed_data_from_list_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_data_from_list_test.main = function() {
    let list = new collection.UnmodifiableListView(JSArrayOfint().of([1, 2]));
    let typed = typed_data.Uint8List.fromList(ListOfint()._check(list));
    if (typed[dartx.get](0) != 1 || typed[dartx.get](1) != 2 || typed[dartx.length] != 2) {
      dart.throw('Test failed');
    }
  };
  dart.fn(typed_data_from_list_test.main, VoidTodynamic());
  // Exports:
  exports.typed_data_from_list_test = typed_data_from_list_test;
});
