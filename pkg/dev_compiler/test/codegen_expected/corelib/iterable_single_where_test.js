dart_library.library('corelib/iterable_single_where_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_single_where_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_single_where_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let StringTobool = () => (StringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  iterable_single_where_test.main = function() {
    let list1 = JSArrayOfint().of([1, 2, 3]);
    let list2 = const$ || (const$ = dart.constList([4, 5, 6], core.int));
    let list3 = JSArrayOfString().of([]);
    let set1 = SetOfint().new();
    set1.add(11);
    set1.add(12);
    set1.add(13);
    let set2 = core.Set.new();
    expect$.Expect.equals(2, list1[dartx.singleWhere](dart.fn(x => x[dartx.isEven], intTobool())));
    expect$.Expect.equals(3, list1[dartx.singleWhere](dart.fn(x => x == 3, intTobool())));
    expect$.Expect.throws(dart.fn(() => list1[dartx.singleWhere](dart.fn(x => x[dartx.isOdd], intTobool())), VoidToint()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.equals(6, list2[dartx.singleWhere](dart.fn(x => x == 6, intTobool())));
    expect$.Expect.equals(5, list2[dartx.singleWhere](dart.fn(x => x[dartx.isOdd], intTobool())));
    expect$.Expect.throws(dart.fn(() => list2[dartx.singleWhere](dart.fn(x => x[dartx.isEven], intTobool())), VoidToint()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => list3[dartx.singleWhere](dart.fn(x => dart.equals(x, 0), StringTobool())), VoidToString()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.equals(12, set1.singleWhere(dart.fn(x => x[dartx.isEven], intTobool())));
    expect$.Expect.equals(11, set1.singleWhere(dart.fn(x => x == 11, intTobool())));
    expect$.Expect.throws(dart.fn(() => set1.singleWhere(dart.fn(x => x[dartx.isOdd], intTobool())), VoidToint()));
    expect$.Expect.throws(dart.fn(() => set2.singleWhere(dart.fn(x => true, dynamicTobool())), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
  };
  dart.fn(iterable_single_where_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_single_where_test = iterable_single_where_test;
});
