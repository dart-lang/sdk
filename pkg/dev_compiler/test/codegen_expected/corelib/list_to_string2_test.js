dart_library.library('corelib/list_to_string2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_to_string2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_to_string2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_to_string2_test.main = function() {
    let list = JSArrayOfint().of([1, 2]);
    list[dartx.add](list);
    let list2 = core.List.new(4);
    list2[dartx.set](0, 1);
    list2[dartx.set](1, 2);
    list2[dartx.set](2, list2);
    list2[dartx.set](3, list);
    expect$.Expect.equals("[1, 2, [...]]", dart.toString(list));
    expect$.Expect.equals("[1, 2, [...], [1, 2, [...]]]", dart.toString(list2));
    let list3 = JSArrayOfObject().of([1, 2, new list_to_string2_test.ThrowOnToString(), 4]);
    expect$.Expect.throws(dart.bind(list3, 'toString', dart.toString), dart.fn(e => dart.equals(e, "Bad!"), dynamicTobool()));
    list3[dartx.set](2, 3);
    expect$.Expect.equals("[1, 2, 3, 4]", dart.toString(list3));
  };
  dart.fn(list_to_string2_test.main, VoidTodynamic());
  list_to_string2_test.ThrowOnToString = class ThrowOnToString extends core.Object {
    toString() {
      dart.throw("Bad!");
    }
  };
  // Exports:
  exports.list_to_string2_test = list_to_string2_test;
});
