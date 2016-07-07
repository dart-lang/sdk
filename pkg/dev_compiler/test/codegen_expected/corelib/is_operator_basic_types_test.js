dart_library.library('corelib/is_operator_basic_types_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__is_operator_basic_types_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const is_operator_basic_types_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  is_operator_basic_types_test.check = function(args) {
    let list = dart.dindex(args, 0);
    let string = dart.dindex(args, 1);
    let nullObject = dart.dindex(args, 2);
    expect$.Expect.isTrue(core.Object.is(list));
    expect$.Expect.isTrue(core.List.is(list));
    expect$.Expect.isTrue(core.Iterable.is(list));
    expect$.Expect.isFalse(core.Comparable.is(list));
    expect$.Expect.isFalse(core.Pattern.is(list));
    expect$.Expect.isFalse(typeof list == 'string');
    expect$.Expect.isFalse(!core.List.is(list));
    expect$.Expect.isFalse(!core.Iterable.is(list));
    expect$.Expect.isTrue(!core.Comparable.is(list));
    expect$.Expect.isTrue(!core.Pattern.is(list));
    expect$.Expect.isTrue(!(typeof list == 'string'));
    expect$.Expect.isTrue(core.Object.is(string));
    expect$.Expect.isFalse(core.List.is(string));
    expect$.Expect.isFalse(core.Iterable.is(string));
    expect$.Expect.isTrue(core.Comparable.is(string));
    expect$.Expect.isTrue(core.Pattern.is(string));
    expect$.Expect.isTrue(typeof string == 'string');
    expect$.Expect.isTrue(!core.List.is(string));
    expect$.Expect.isTrue(!core.Iterable.is(string));
    expect$.Expect.isFalse(!core.Comparable.is(string));
    expect$.Expect.isFalse(!core.Pattern.is(string));
    expect$.Expect.isFalse(!(typeof string == 'string'));
    expect$.Expect.isTrue(core.Object.is(nullObject));
    expect$.Expect.isFalse(core.List.is(nullObject));
    expect$.Expect.isFalse(core.Iterable.is(nullObject));
    expect$.Expect.isFalse(core.Comparable.is(nullObject));
    expect$.Expect.isFalse(core.Pattern.is(nullObject));
    expect$.Expect.isFalse(typeof nullObject == 'string');
    expect$.Expect.isTrue(!core.List.is(nullObject));
    expect$.Expect.isTrue(!core.Iterable.is(nullObject));
    expect$.Expect.isTrue(!core.Comparable.is(nullObject));
    expect$.Expect.isTrue(!core.Pattern.is(nullObject));
    expect$.Expect.isTrue(!(typeof nullObject == 'string'));
  };
  dart.fn(is_operator_basic_types_test.check, dynamicTodynamic());
  is_operator_basic_types_test.main = function() {
    is_operator_basic_types_test.check(JSArrayOfObject().of([[], 'string', null]));
    let string = core.String.fromCharCodes(JSArrayOfint().of([new core.DateTime.now().year[dartx['%']](100) + 1]));
    is_operator_basic_types_test.check(JSArrayOfObject().of([string[dartx.codeUnits], string, null]));
  };
  dart.fn(is_operator_basic_types_test.main, VoidTodynamic());
  // Exports:
  exports.is_operator_basic_types_test = is_operator_basic_types_test;
});
