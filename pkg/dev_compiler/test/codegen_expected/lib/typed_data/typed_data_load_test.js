dart_library.library('lib/typed_data/typed_data_load_test', null, /* Imports */[
  'dart_sdk'
], function load__typed_data_load_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const typed_data_load_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_data_load_test.main = function() {
    let list = typed_data.Int8List.new(1);
    list[dartx.set](0, 300);
    if (list[dartx.get](0) != 44) {
      dart.throw('Test failed');
    }
    let a = list[dartx.get](0);
    list[dartx.set](0, 0);
    if (list[dartx.get](0) != 0) {
      dart.throw('Test failed');
    }
  };
  dart.fn(typed_data_load_test.main, VoidTodynamic());
  // Exports:
  exports.typed_data_load_test = typed_data_load_test;
});
