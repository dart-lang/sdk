dart_library.library('corelib/errors_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__errors_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const errors_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  errors_test.main = function() {
    expect$.Expect.equals("Invalid argument(s)", new core.ArgumentError().toString());
    expect$.Expect.equals("Invalid argument(s): message", new core.ArgumentError("message").toString());
    expect$.Expect.equals("Invalid argument: null", new core.ArgumentError.value(null).toString());
    expect$.Expect.equals("Invalid argument: 42", new core.ArgumentError.value(42).toString());
    expect$.Expect.equals("Invalid argument: \"bad\"", new core.ArgumentError.value("bad").toString());
    expect$.Expect.equals("Invalid argument (foo): null", new core.ArgumentError.value(null, "foo").toString());
    expect$.Expect.equals("Invalid argument (foo): 42", new core.ArgumentError.value(42, "foo").toString());
    expect$.Expect.equals("Invalid argument (foo): message: 42", new core.ArgumentError.value(42, "foo", "message").toString());
    expect$.Expect.equals("Invalid argument: message: 42", new core.ArgumentError.value(42, null, "message").toString());
    expect$.Expect.equals("Invalid argument(s): Must not be null", new core.ArgumentError.notNull().toString());
    expect$.Expect.equals("Invalid argument(s) (foo): Must not be null", new core.ArgumentError.notNull("foo").toString());
    expect$.Expect.equals("RangeError", new core.RangeError(null).toString());
    expect$.Expect.equals("RangeError: message", new core.RangeError("message").toString());
    expect$.Expect.equals("RangeError: Value not in range: 42", new core.RangeError.value(42).toString());
    expect$.Expect.equals("RangeError (foo): Value not in range: 42", new core.RangeError.value(42, "foo").toString());
    expect$.Expect.equals("RangeError (foo): message: 42", new core.RangeError.value(42, "foo", "message").toString());
    expect$.Expect.equals("RangeError: message: 42", new core.RangeError.value(42, null, "message").toString());
    expect$.Expect.equals("RangeError: Invalid value: Not in range 2..9, inclusive: 42", new core.RangeError.range(42, 2, 9).toString());
    expect$.Expect.equals("RangeError (foo): Invalid value: Not in range 2..9, " + "inclusive: 42", new core.RangeError.range(42, 2, 9, "foo").toString());
    expect$.Expect.equals("RangeError (foo): message: Not in range 2..9, inclusive: 42", new core.RangeError.range(42, 2, 9, "foo", "message").toString());
    expect$.Expect.equals("RangeError: message: Not in range 2..9, inclusive: 42", new core.RangeError.range(42, 2, 9, null, "message").toString());
    expect$.Expect.equals("RangeError: Index out of range: " + "index should be less than 3: 42", core.RangeError.index(42, JSArrayOfint().of([1, 2, 3])).toString());
    expect$.Expect.equals("RangeError (foo): Index out of range: " + "index should be less than 3: 42", core.RangeError.index(42, JSArrayOfint().of([1, 2, 3]), "foo").toString());
    expect$.Expect.equals("RangeError (foo): message: " + "index should be less than 3: 42", core.RangeError.index(42, JSArrayOfint().of([1, 2, 3]), "foo", "message").toString());
    expect$.Expect.equals("RangeError: message: " + "index should be less than 3: 42", core.RangeError.index(42, JSArrayOfint().of([1, 2, 3]), null, "message").toString());
    expect$.Expect.equals("RangeError (foo): message: " + "index should be less than 2: 42", core.RangeError.index(42, JSArrayOfint().of([1, 2, 3]), "foo", "message", 2).toString());
    expect$.Expect.equals("RangeError: Index out of range: " + "index must not be negative: -5", core.RangeError.index(-5, JSArrayOfint().of([1, 2, 3])).toString());
  };
  dart.fn(errors_test.main, VoidTodynamic());
  // Exports:
  exports.errors_test = errors_test;
});
