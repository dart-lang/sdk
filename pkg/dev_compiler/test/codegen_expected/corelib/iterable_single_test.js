dart_library.library('corelib/iterable_single_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_single_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_single_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  let const$1;
  iterable_single_test.main = function() {
    let list1a = JSArrayOfint().of([1]);
    let list1b = JSArrayOfint().of([1, 2, 3]);
    let list1c = JSArrayOfint().of([]);
    let list2a = const$ || (const$ = dart.constList([5], core.int));
    let list2b = const$0 || (const$0 = dart.constList([4, 5], core.int));
    let list2c = const$1 || (const$1 = dart.constList([], core.int));
    let set1 = SetOfint().new();
    set1.add(22);
    let set2 = core.Set.new();
    set2.add(11);
    set2.add(12);
    set2.add(13);
    let set3 = core.Set.new();
    expect$.Expect.equals(1, list1a[dartx.single]);
    expect$.Expect.throws(dart.fn(() => list1b[dartx.single], VoidToint()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => list1c[dartx.single], VoidToint()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.equals(5, list2a[dartx.single]);
    expect$.Expect.throws(dart.fn(() => list2b[dartx.single], VoidToint()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => list2c[dartx.single], VoidToint()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.equals(22, set1.single);
    expect$.Expect.throws(dart.fn(() => set2.single, VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => set3.single, VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
  };
  dart.fn(iterable_single_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_single_test = iterable_single_test;
});
