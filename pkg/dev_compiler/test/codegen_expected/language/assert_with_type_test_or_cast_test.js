dart_library.library('language/assert_with_type_test_or_cast_test', null, /* Imports */[
  'dart_sdk'
], function load__assert_with_type_test_or_cast_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const assert_with_type_test_or_cast_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  assert_with_type_test_or_cast_test.main = function() {
    let names = ListOfint().new();
    dart.assert(ListOfint().is(names));
    dart.assert(!ListOfString().is(names));
    dart.assert(names[dartx.length] == 0);
    dart.assert(ListOfint().is(names));
  };
  dart.fn(assert_with_type_test_or_cast_test.main, VoidTodynamic());
  // Exports:
  exports.assert_with_type_test_or_cast_test = assert_with_type_test_or_cast_test;
});
