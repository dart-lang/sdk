dart_library.library('corelib/iterable_first_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_first_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_first_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  iterable_first_test.main = function() {
    let list1 = JSArrayOfint().of([1, 2, 3]);
    let list2 = const$ || (const$ = dart.constList([4, 5], core.int));
    let list3 = JSArrayOfString().of([]);
    let set1 = SetOfint().new();
    set1.add(11);
    set1.add(12);
    set1.add(13);
    let set2 = core.Set.new();
    expect$.Expect.equals(1, list1[dartx.first]);
    expect$.Expect.equals(4, list2[dartx.first]);
    expect$.Expect.throws(dart.fn(() => list3[dartx.first], VoidToString()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.isTrue(set1.contains(set1.first));
    expect$.Expect.throws(dart.fn(() => set2.first, VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
  };
  dart.fn(iterable_first_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_first_test = iterable_first_test;
});
