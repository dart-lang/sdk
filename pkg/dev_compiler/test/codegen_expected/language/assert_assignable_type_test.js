dart_library.library('language/assert_assignable_type_test', null, /* Imports */[
  'dart_sdk'
], function load__assert_assignable_type_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const assert_assignable_type_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  assert_assignable_type_test.main = function() {
    let y = -2147483648;
    assert_assignable_type_test.testInt64List();
  };
  dart.fn(assert_assignable_type_test.main, VoidTodynamic());
  assert_assignable_type_test.testInt64List = function() {
    let array = core.List.new(10);
    assert_assignable_type_test.testInt64ListImpl(array);
  };
  dart.fn(assert_assignable_type_test.testInt64List, VoidTodynamic());
  assert_assignable_type_test.testInt64ListImpl = function(array) {
    for (let i = 0; i < 10; ++i) {
    }
    let sum = 0;
    for (let i = 0; i < 10; ++i) {
      dart.dsetindex(array, i, -36028797018963968 + i);
    }
  };
  dart.fn(assert_assignable_type_test.testInt64ListImpl, dynamicTodynamic());
  // Exports:
  exports.assert_assignable_type_test = assert_assignable_type_test;
});
