dart_library.library('corelib/list_map_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_map_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_map_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let IterableTodynamic = () => (IterableTodynamic = dart.constFn(dart.functionType(dart.dynamic, [core.Iterable])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTovoid = () => (dynamicAnddynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let FnAnddynamicTovoid = () => (FnAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [IterableTodynamic(), dart.dynamic])))();
  let IterableTodynamic$ = () => (IterableTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.Iterable])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let IterableTobool = () => (IterableTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.Iterable])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let IterableToString = () => (IterableToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Iterable])))();
  let IterableToIterable = () => (IterableToIterable = dart.constFn(dart.definiteFunctionType(core.Iterable, [core.Iterable])))();
  let dynamicToList = () => (dynamicToList = dart.constFn(dart.definiteFunctionType(core.List, [dart.dynamic])))();
  let ListTovoid = () => (ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  list_map_test.main = function() {
    list_map_test.testOperations();
  };
  dart.fn(list_map_test.main, VoidTodynamic());
  list_map_test.ThrowMarker = class ThrowMarker extends core.Object {
    new() {
    }
    toString() {
      return "<<THROWS>>";
    }
  };
  dart.setSignature(list_map_test.ThrowMarker, {
    constructors: () => ({new: dart.definiteFunctionType(list_map_test.ThrowMarker, [])})
  });
  let const$;
  let const$0;
  let const$1;
  list_map_test.testOperations = function() {
    let l = const$ || (const$ = dart.constList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], core.int));
    let r = const$0 || (const$0 = dart.constList([10, 9, 8, 7, 6, 5, 4, 3, 2, 1], core.int));
    function rev(x) {
      return dart.asInt(11 - dart.notNull(core.num._check(x)));
    }
    dart.fn(rev, dynamicToint());
    let base = l[dartx.map](dart.dynamic)(dart.fn(x => x, dynamicTodynamic()))[dartx.toList]();
    let reversed = l[dartx.map](core.int)(rev);
    expect$.Expect.listEquals(r, l[dartx.map](core.int)(rev)[dartx.toList]());
    expect$.Expect.listEquals(l, l[dartx.map](core.int)(rev)[dartx.map](core.int)(rev)[dartx.toList]());
    for (let i = 0; i < dart.notNull(r[dartx.length]); i++) {
      expect$.Expect.equals(r[dartx.get](i), reversed[dartx.elementAt](i));
    }
    expect$.Expect.equals(4, base[dartx.indexOf](5));
    expect$.Expect.equals(5, reversed[dartx.toList]()[dartx.indexOf](5));
    let subr = JSArrayOfint().of([8, 7, 6, 5, 4, 3]);
    expect$.Expect.listEquals(subr, reversed[dartx.skip](2)[dartx.take](6)[dartx.toList]());
    expect$.Expect.listEquals(subr, reversed[dartx.take](8)[dartx.skip](2)[dartx.toList]());
    expect$.Expect.listEquals(subr, reversed[dartx.toList]()[dartx.reversed][dartx.skip](2)[dartx.take](6)[dartx.toList]()[dartx.reversed][dartx.toList]());
    expect$.Expect.listEquals(subr, reversed[dartx.toList]()[dartx.reversed][dartx.take](8)[dartx.skip](2)[dartx.toList]()[dartx.reversed][dartx.toList]());
    expect$.Expect.listEquals(subr, reversed[dartx.take](8)[dartx.toList]()[dartx.reversed][dartx.take](6)[dartx.toList]()[dartx.reversed][dartx.toList]());
    expect$.Expect.listEquals(subr, reversed[dartx.toList]()[dartx.reversed][dartx.take](8)[dartx.toList]()[dartx.reversed][dartx.take](6)[dartx.toList]());
    expect$.Expect.listEquals(subr, reversed[dartx.toList]()[dartx.reversed][dartx.skip](2)[dartx.toList]()[dartx.reversed][dartx.skip](2)[dartx.toList]());
    expect$.Expect.listEquals(subr, reversed[dartx.skip](2)[dartx.toList]()[dartx.reversed][dartx.skip](2)[dartx.toList]()[dartx.reversed][dartx.toList]());
    function testList(list) {
      let throws = const$1 || (const$1 = dart.const(new list_map_test.ThrowMarker()));
      let mappedList = core.List.new(list[dartx.length]);
      for (let i = 0; i < dart.notNull(list[dartx.length]); i++) {
        mappedList[dartx.set](i, rev(list[dartx.get](i)));
      }
      let reversed = list[dartx.map](core.int)(rev);
      function testEquals(v1, v2, path) {
        if (core.Iterable.is(v1)) {
          let i1 = v1[dartx.iterator];
          let i2 = core.Iterator._check(dart.dload(v2, 'iterator'));
          let index = 0;
          while (dart.test(i1.moveNext())) {
            expect$.Expect.isTrue(i2.moveNext(), dart.str`Too few actual values. Expected[${index}] == ${i1.current}`);
            testEquals(i1.current, i2.current, dart.str`${path}[${index}]`);
            index++;
          }
          if (dart.test(i2.moveNext())) {
            expect$.Expect.fail(dart.str`Too many actual values. Actual[${index}] == ${i2.current}`);
          }
        } else {
          expect$.Expect.equals(v1, v2, core.String._check(path));
        }
      }
      dart.fn(testEquals, dynamicAnddynamicAnddynamicTovoid());
      function testOp(operation, name) {
        let expect = null;
        try {
          expect = operation(mappedList);
        } catch (e) {
          expect = throws;
        }

        let actual = null;
        try {
          actual = operation(reversed);
        } catch (e) {
          actual = throws;
        }

        testEquals(expect, actual, dart.str`${name}: ${list}`);
      }
      dart.fn(testOp, FnAnddynamicTovoid());
      testOp(dart.fn(i => i[dartx.first], IterableTodynamic$()), "first");
      testOp(dart.fn(i => i[dartx.last], IterableTodynamic$()), "last");
      testOp(dart.fn(i => i[dartx.single], IterableTodynamic$()), "single");
      testOp(dart.fn(i => i[dartx.firstWhere](dart.fn(n => false, dynamicTobool())), IterableTodynamic$()), "firstWhere<false");
      testOp(dart.fn(i => i[dartx.firstWhere](dart.fn(n => core.bool._check(dart.dsend(n, '<', 10)), dynamicTobool())), IterableTodynamic$()), "firstWhere<10");
      testOp(dart.fn(i => i[dartx.firstWhere](dart.fn(n => core.bool._check(dart.dsend(n, '<', 5)), dynamicTobool())), IterableTodynamic$()), "firstWhere<5");
      testOp(dart.fn(i => i[dartx.firstWhere](dart.fn(n => true, dynamicTobool())), IterableTodynamic$()), "firstWhere<true");
      testOp(dart.fn(i => i[dartx.lastWhere](dart.fn(n => false, dynamicTobool())), IterableTodynamic$()), "lastWhere<false");
      testOp(dart.fn(i => i[dartx.lastWhere](dart.fn(n => core.bool._check(dart.dsend(n, '<', 5)), dynamicTobool())), IterableTodynamic$()), "lastWhere<5");
      testOp(dart.fn(i => i[dartx.lastWhere](dart.fn(n => core.bool._check(dart.dsend(n, '<', 10)), dynamicTobool())), IterableTodynamic$()), "lastWhere<10");
      testOp(dart.fn(i => i[dartx.lastWhere](dart.fn(n => true, dynamicTobool())), IterableTodynamic$()), "lastWhere<true");
      testOp(dart.fn(i => i[dartx.singleWhere](dart.fn(n => false, dynamicTobool())), IterableTodynamic$()), "singleWhere<false");
      testOp(dart.fn(i => i[dartx.singleWhere](dart.fn(n => core.bool._check(dart.dsend(n, '<', 5)), dynamicTobool())), IterableTodynamic$()), "singelWhere<5");
      testOp(dart.fn(i => i[dartx.singleWhere](dart.fn(n => core.bool._check(dart.dsend(n, '<', 10)), dynamicTobool())), IterableTodynamic$()), "singelWhere<10");
      testOp(dart.fn(i => i[dartx.singleWhere](dart.fn(n => true, dynamicTobool())), IterableTodynamic$()), "singleWhere<true");
      testOp(dart.fn(i => i[dartx.contains](5), IterableTobool()), "contains(5)");
      testOp(dart.fn(i => i[dartx.contains](10), IterableTobool()), "contains(10)");
      testOp(dart.fn(i => i[dartx.any](dart.fn(n => core.bool._check(dart.dsend(n, '<', 5)), dynamicTobool())), IterableTobool()), "any<5");
      testOp(dart.fn(i => i[dartx.any](dart.fn(n => core.bool._check(dart.dsend(n, '<', 10)), dynamicTobool())), IterableTobool()), "any<10");
      testOp(dart.fn(i => i[dartx.every](dart.fn(n => core.bool._check(dart.dsend(n, '<', 5)), dynamicTobool())), IterableTobool()), "every<5");
      testOp(dart.fn(i => i[dartx.every](dart.fn(n => core.bool._check(dart.dsend(n, '<', 10)), dynamicTobool())), IterableTobool()), "every<10");
      testOp(dart.fn(i => i[dartx.reduce](dart.fn((a, b) => dart.dsend(a, '+', b), dynamicAnddynamicTodynamic())), IterableTodynamic$()), "reduce-sum");
      testOp(dart.fn(i => i[dartx.fold](dart.dynamic)(0, dart.fn((a, b) => dart.dsend(a, '+', b), dynamicAnddynamicTodynamic())), IterableTodynamic$()), "fold-sum");
      testOp(dart.fn(i => i[dartx.join]("-"), IterableToString()), "join-");
      testOp(dart.fn(i => i[dartx.join](""), IterableToString()), "join");
      testOp(dart.fn(i => i[dartx.join](), IterableToString()), "join-null");
      testOp(dart.fn(i => i[dartx.map](dart.dynamic)(dart.fn(n => dart.dsend(n, '*', 2), dynamicTodynamic())), IterableToIterable()), "map*2");
      testOp(dart.fn(i => i[dartx.where](dart.fn(n => core.bool._check(dart.dsend(n, '<', 5)), dynamicTobool())), IterableToIterable()), "where<5");
      testOp(dart.fn(i => i[dartx.where](dart.fn(n => core.bool._check(dart.dsend(n, '<', 10)), dynamicTobool())), IterableToIterable()), "where<10");
      testOp(dart.fn(i => i[dartx.expand](dart.dynamic)(dart.fn(n => [], dynamicToList())), IterableToIterable()), "expand[]");
      testOp(dart.fn(i => i[dartx.expand](dart.dynamic)(dart.fn(n => [n], dynamicToList())), IterableToIterable()), "expand[n]");
      testOp(dart.fn(i => i[dartx.expand](dart.dynamic)(dart.fn(n => [n, n], dynamicToList())), IterableToIterable()), "expand[n, n]");
      testOp(dart.fn(i => i[dartx.take](0), IterableToIterable()), "take(0)");
      testOp(dart.fn(i => i[dartx.take](5), IterableToIterable()), "take(5)");
      testOp(dart.fn(i => i[dartx.take](10), IterableToIterable()), "take(10)");
      testOp(dart.fn(i => i[dartx.take](15), IterableToIterable()), "take(15)");
      testOp(dart.fn(i => i[dartx.skip](0), IterableToIterable()), "skip(0)");
      testOp(dart.fn(i => i[dartx.skip](5), IterableToIterable()), "skip(5)");
      testOp(dart.fn(i => i[dartx.skip](10), IterableToIterable()), "skip(10)");
      testOp(dart.fn(i => i[dartx.skip](15), IterableToIterable()), "skip(15)");
      testOp(dart.fn(i => i[dartx.takeWhile](dart.fn(n => false, dynamicTobool())), IterableToIterable()), "takeWhile(t)");
      testOp(dart.fn(i => i[dartx.takeWhile](dart.fn(n => core.bool._check(dart.dsend(n, '<', 5)), dynamicTobool())), IterableToIterable()), "takeWhile(n<5)");
      testOp(dart.fn(i => i[dartx.takeWhile](dart.fn(n => core.bool._check(dart.dsend(n, '>', 5)), dynamicTobool())), IterableToIterable()), "takeWhile(n>5)");
      testOp(dart.fn(i => i[dartx.takeWhile](dart.fn(n => true, dynamicTobool())), IterableToIterable()), "takeWhile(f)");
      testOp(dart.fn(i => i[dartx.skipWhile](dart.fn(n => false, dynamicTobool())), IterableToIterable()), "skipWhile(t)");
      testOp(dart.fn(i => i[dartx.skipWhile](dart.fn(n => core.bool._check(dart.dsend(n, '<', 5)), dynamicTobool())), IterableToIterable()), "skipWhile(n<5)");
      testOp(dart.fn(i => i[dartx.skipWhile](dart.fn(n => core.bool._check(dart.dsend(n, '>', 5)), dynamicTobool())), IterableToIterable()), "skipWhile(n>5)");
      testOp(dart.fn(i => i[dartx.skipWhile](dart.fn(n => true, dynamicTobool())), IterableToIterable()), "skipWhile(f)");
    }
    dart.fn(testList, ListTovoid());
    testList([]);
    testList(JSArrayOfint().of([0]));
    testList(JSArrayOfint().of([10]));
    testList(JSArrayOfint().of([0, 1]));
    testList(JSArrayOfint().of([0, 10]));
    testList(JSArrayOfint().of([10, 11]));
    testList(JSArrayOfint().of([0, 5, 10]));
    testList(JSArrayOfint().of([10, 5, 0]));
    testList(JSArrayOfint().of([0, 1, 2, 3]));
    testList(JSArrayOfint().of([3, 4, 5, 6]));
    testList(JSArrayOfint().of([10, 11, 12, 13]));
    testList(l);
    testList(r);
    testList(base);
    expect$.Expect.listEquals(r, l[dartx.map](core.int)(rev)[dartx.toList]());
  };
  dart.fn(list_map_test.testOperations, VoidTovoid());
  // Exports:
  exports.list_map_test = list_map_test;
});
