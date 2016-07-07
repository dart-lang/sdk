dart_library.library('corelib/iterable_generate_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_generate_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_generate_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let IteratorOfint = () => (IteratorOfint = dart.constFn(core.Iterator$(core.int)))();
  let IterableOfString = () => (IterableOfString = dart.constFn(core.Iterable$(core.String)))();
  let IteratorOfString = () => (IteratorOfString = dart.constFn(core.Iterator$(core.String)))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let intToString = () => (intToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int])))();
  let VoidToIterableOfString = () => (VoidToIterableOfString = dart.constFn(dart.definiteFunctionType(IterableOfString(), [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  iterable_generate_test.main = function() {
    let checkedMode = false;
    dart.assert(checkedMode = true);
    function test(expectedList, generatedIterable) {
      expect$.Expect.equals(dart.dload(expectedList, 'length'), dart.dload(generatedIterable, 'length'));
      expect$.Expect.listEquals(core.List._check(expectedList), core.List._check(dart.dsend(generatedIterable, 'toList')));
    }
    dart.fn(test, dynamicAnddynamicTovoid());
    test([], core.Iterable.generate(0));
    test(JSArrayOfint().of([0]), core.Iterable.generate(1));
    test(JSArrayOfint().of([0, 1, 2, 3, 4]), core.Iterable.generate(5));
    test(JSArrayOfString().of(["0", "1", "2", "3", "4"]), core.Iterable.generate(5, dart.fn(x => dart.str`${x}`, intToString())));
    test(JSArrayOfint().of([2, 3, 4, 5, 6]), core.Iterable.generate(7)[dartx.skip](2));
    test(JSArrayOfint().of([0, 1, 2, 3, 4]), core.Iterable.generate(7)[dartx.take](5));
    test([], core.Iterable.generate(5)[dartx.skip](6));
    test([], core.Iterable.generate(5)[dartx.take](0));
    test([], core.Iterable.generate(5)[dartx.take](3)[dartx.skip](3));
    test([], core.Iterable.generate(5)[dartx.skip](6)[dartx.take](0));
    let it = IterableOfint().generate(5);
    expect$.Expect.isTrue(IterableOfint().is(it));
    expect$.Expect.isTrue(IteratorOfint().is(it[dartx.iterator]));
    expect$.Expect.isTrue(!IterableOfString().is(it));
    expect$.Expect.isTrue(!IteratorOfString().is(it[dartx.iterator]));
    test(JSArrayOfint().of([0, 1, 2, 3, 4]), it);
    let st = IterableOfString().generate(5, dart.fn(x => dart.str`${x}`, intToString()));
    expect$.Expect.isTrue(IterableOfString().is(st));
    expect$.Expect.isTrue(IteratorOfString().is(st[dartx.iterator]));
    expect$.Expect.isFalse(IterableOfint().is(st));
    expect$.Expect.isFalse(IteratorOfint().is(st[dartx.iterator]));
    test(JSArrayOfString().of(["0", "1", "2", "3", "4"]), st);
    if (checkedMode) {
      expect$.Expect.throws(dart.fn(() => IterableOfString().generate(5), VoidToIterableOfString()));
    }
  };
  dart.fn(iterable_generate_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_generate_test = iterable_generate_test;
});
