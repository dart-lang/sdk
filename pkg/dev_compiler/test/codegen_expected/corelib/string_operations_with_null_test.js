dart_library.library('corelib/string_operations_with_null_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_operations_with_null_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_operations_with_null_test = Object.create(null);
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidToListOfString = () => (VoidToListOfString = dart.constFn(dart.definiteFunctionType(ListOfString(), [])))();
  string_operations_with_null_test.returnStringOrNull = function() {
    return new core.DateTime.now().millisecondsSinceEpoch == 0 ? 'foo' : null;
  };
  dart.fn(string_operations_with_null_test.returnStringOrNull, VoidTodynamic());
  string_operations_with_null_test.main = function() {
    expect$.Expect.throws(dart.fn(() => 'foo' + dart.notNull(core.String._check(string_operations_with_null_test.returnStringOrNull())), VoidToString()), dart.fn(e => core.ArgumentError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => 'foo'[dartx.split](core.Pattern._check(string_operations_with_null_test.returnStringOrNull())), VoidToListOfString()), dart.fn(e => core.ArgumentError.is(e) || core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(string_operations_with_null_test.main, VoidTodynamic());
  // Exports:
  exports.string_operations_with_null_test = string_operations_with_null_test;
});
