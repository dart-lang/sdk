dart_library.library('corelib/range_error_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__range_error_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const range_error_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfArgumentError = () => (JSArrayOfArgumentError = dart.constFn(_interceptors.JSArray$(core.ArgumentError)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  range_error_test.main = function() {
    range_error_test.testRead();
    range_error_test.testWrite();
    range_error_test.testToString();
  };
  dart.fn(range_error_test.main, VoidTovoid());
  range_error_test.testRead = function() {
    range_error_test.testListRead([], 0);
    range_error_test.testListRead([], -1);
    range_error_test.testListRead([], 1);
    let list = JSArrayOfint().of([1]);
    range_error_test.testListRead(list, -1);
    range_error_test.testListRead(list, 1);
    list = ListOfint().new(1);
    range_error_test.testListRead(list, -1);
    range_error_test.testListRead(list, 1);
    list = ListOfint().new();
    range_error_test.testListRead(list, -1);
    range_error_test.testListRead(list, 0);
    range_error_test.testListRead(list, 1);
  };
  dart.fn(range_error_test.testRead, VoidTovoid());
  range_error_test.testWrite = function() {
    range_error_test.testListWrite([], 0);
    range_error_test.testListWrite([], -1);
    range_error_test.testListWrite([], 1);
    let list = JSArrayOfint().of([1]);
    range_error_test.testListWrite(list, -1);
    range_error_test.testListWrite(list, 1);
    list = ListOfint().new(1);
    range_error_test.testListWrite(list, -1);
    range_error_test.testListWrite(list, 1);
    list = ListOfint().new();
    range_error_test.testListWrite(list, -1);
    range_error_test.testListWrite(list, 0);
    range_error_test.testListWrite(list, 1);
  };
  dart.fn(range_error_test.testWrite, VoidTovoid());
  range_error_test.testToString = function() {
    for (let name of JSArrayOfString().of([null, "THENAME"])) {
      for (let message of JSArrayOfString().of([null, "THEMESSAGE"])) {
        let value = 37;
        for (let re of JSArrayOfArgumentError().of([new core.ArgumentError.value(value, name, message), new core.RangeError.value(value, name, message), core.RangeError.index(value, [], name, message), new core.RangeError.range(value, 0, 24, name, message)])) {
          let str = dart.toString(re);
          if (name != null) expect$.Expect.isTrue(str[dartx.contains](name), dart.str`${name} in ${str}`);
          if (message != null) expect$.Expect.isTrue(str[dartx.contains](message), dart.str`${message} in ${str}`);
          expect$.Expect.isTrue(str[dartx.contains](dart.str`${value}`), dart.str`${value} in ${str}`);
          expect$.Expect.isFalse(str[dartx.contains](core.RegExp.new(":s*:")));
        }
      }
    }
  };
  dart.fn(range_error_test.testToString, VoidTovoid());
  range_error_test.testListRead = function(list, index) {
    let exception = null;
    try {
      let e = dart.dindex(list, index);
    } catch (e) {
      if (core.RangeError.is(e)) {
        exception = e;
      } else
        throw e;
    }

    expect$.Expect.equals(true, exception != null);
  };
  dart.fn(range_error_test.testListRead, dynamicAnddynamicTovoid());
  range_error_test.testListWrite = function(list, index) {
    let exception = null;
    try {
      dart.dsetindex(list, index, null);
    } catch (e) {
      if (core.RangeError.is(e)) {
        exception = e;
      } else
        throw e;
    }

    expect$.Expect.equals(true, exception != null);
  };
  dart.fn(range_error_test.testListWrite, dynamicAnddynamicTovoid());
  // Exports:
  exports.range_error_test = range_error_test;
});
