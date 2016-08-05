dart_library.library('corelib/set_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__set_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const set_test = Object.create(null);
  let VoidToSet = () => (VoidToSet = dart.constFn(dart.functionType(core.Set, [])))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let JSArrayOfCE = () => (JSArrayOfCE = dart.constFn(_interceptors.JSArray$(set_test.CE)))();
  let SetOfObject = () => (SetOfObject = dart.constFn(core.Set$(core.Object)))();
  let __ToSet = () => (__ToSet = dart.constFn(dart.functionType(core.Set, [], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let __Todynamic = () => (__Todynamic = dart.constFn(dart.functionType(dart.dynamic, [], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let ComparableOfCE = () => (ComparableOfCE = dart.constFn(core.Comparable$(set_test.CE)))();
  let JSArrayOfnum = () => (JSArrayOfnum = dart.constFn(_interceptors.JSArray$(core.num)))();
  let SetOfCE = () => (SetOfCE = dart.constFn(core.Set$(set_test.CE)))();
  let IterableOfCE = () => (IterableOfCE = dart.constFn(core.Iterable$(set_test.CE)))();
  let JSArrayOfB = () => (JSArrayOfB = dart.constFn(_interceptors.JSArray$(set_test.B)))();
  let SetOfA = () => (SetOfA = dart.constFn(core.Set$(set_test.A)))();
  let HashSetOfint = () => (HashSetOfint = dart.constFn(collection.HashSet$(core.int)))();
  let LinkedHashSetOfint = () => (LinkedHashSetOfint = dart.constFn(collection.LinkedHashSet$(core.int)))();
  let SplayTreeSetOfint = () => (SplayTreeSetOfint = dart.constFn(collection.SplayTreeSet$(core.int)))();
  let dynamicAnddynamicTobool = () => (dynamicAnddynamicTobool = dart.constFn(dart.functionType(core.bool, [dart.dynamic, dart.dynamic])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.functionType(core.int, [dart.dynamic])))();
  let ObjectTobool = () => (ObjectTobool = dart.constFn(dart.functionType(core.bool, [core.Object])))();
  let dynamicAnddynamicToint = () => (dynamicAnddynamicToint = dart.constFn(dart.functionType(core.int, [dart.dynamic, dart.dynamic])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.functionType(core.bool, [dart.dynamic])))();
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let HashSetOfCE = () => (HashSetOfCE = dart.constFn(collection.HashSet$(set_test.CE)))();
  let LinkedHashSetOfCE = () => (LinkedHashSetOfCE = dart.constFn(collection.LinkedHashSet$(set_test.CE)))();
  let SplayTreeSetOfCE = () => (SplayTreeSetOfCE = dart.constFn(collection.SplayTreeSet$(set_test.CE)))();
  let CEAndCEToint = () => (CEAndCEToint = dart.constFn(dart.functionType(core.int, [set_test.CE, set_test.CE])))();
  let IterableOfA = () => (IterableOfA = dart.constFn(core.Iterable$(set_test.A)))();
  let HashSetOfA = () => (HashSetOfA = dart.constFn(collection.HashSet$(set_test.A)))();
  let LinkedHashSetOfA = () => (LinkedHashSetOfA = dart.constFn(collection.LinkedHashSet$(set_test.A)))();
  let SplayTreeSetOfA = () => (SplayTreeSetOfA = dart.constFn(collection.SplayTreeSet$(set_test.A)))();
  let VoidToSet$ = () => (VoidToSet$ = dart.constFn(dart.definiteFunctionType(core.Set, [])))();
  let FnTovoid = () => (FnTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [VoidToSet()])))();
  let intTodynamic = () => (intTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  let intAndSetTovoid = () => (intAndSetTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.Set])))();
  let StringTobool = () => (StringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String])))();
  let dynamicTobool$ = () => (dynamicTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let SetOfintTovoid = () => (SetOfintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [SetOfint()])))();
  let FnTovoid$ = () => (FnTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [__ToSet()])))();
  let FnTovoid$0 = () => (FnTovoid$0 = dart.constFn(dart.definiteFunctionType(dart.void, [__Todynamic()])))();
  let CEAndCETobool = () => (CEAndCETobool = dart.constFn(dart.definiteFunctionType(core.bool, [set_test.CE, set_test.CE])))();
  let intToFunction = () => (intToFunction = dart.constFn(dart.definiteFunctionType(core.Function, [core.int])))();
  let CEToint = () => (CEToint = dart.constFn(dart.definiteFunctionType(core.int, [set_test.CE])))();
  let CEAndCEToint$ = () => (CEAndCEToint$ = dart.constFn(dart.definiteFunctionType(core.int, [set_test.CE, set_test.CE])))();
  let ObjectTobool$ = () => (ObjectTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [core.Object])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicAnddynamicToint$ = () => (dynamicAnddynamicToint$ = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic, dart.dynamic])))();
  let numTobool = () => (numTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.num])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidToHashSet = () => (VoidToHashSet = dart.constFn(dart.definiteFunctionType(collection.HashSet, [])))();
  let VoidToLinkedHashSet = () => (VoidToLinkedHashSet = dart.constFn(dart.definiteFunctionType(collection.LinkedHashSet, [])))();
  let dynamicAnddynamicTobool$ = () => (dynamicAnddynamicTobool$ = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic])))();
  let dynamicToint$ = () => (dynamicToint$ = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidToSplayTreeSet = () => (VoidToSplayTreeSet = dart.constFn(dart.definiteFunctionType(collection.SplayTreeSet, [])))();
  let intAndintTobool = () => (intAndintTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int, core.int])))();
  let __ToHashSet = () => (__ToHashSet = dart.constFn(dart.definiteFunctionType(collection.HashSet, [], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let __ToLinkedHashSet = () => (__ToLinkedHashSet = dart.constFn(dart.definiteFunctionType(collection.LinkedHashSet, [], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let __ToSplayTreeSet = () => (__ToSplayTreeSet = dart.constFn(dart.definiteFunctionType(collection.SplayTreeSet, [], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicToSetOfint = () => (dynamicToSetOfint = dart.constFn(dart.definiteFunctionType(SetOfint(), [dart.dynamic])))();
  let dynamicToHashSetOfint = () => (dynamicToHashSetOfint = dart.constFn(dart.definiteFunctionType(HashSetOfint(), [dart.dynamic])))();
  let dynamicToLinkedHashSetOfint = () => (dynamicToLinkedHashSetOfint = dart.constFn(dart.definiteFunctionType(LinkedHashSetOfint(), [dart.dynamic])))();
  let dynamicToSplayTreeSetOfint = () => (dynamicToSplayTreeSetOfint = dart.constFn(dart.definiteFunctionType(SplayTreeSetOfint(), [dart.dynamic])))();
  let dynamicToSetOfCE = () => (dynamicToSetOfCE = dart.constFn(dart.definiteFunctionType(SetOfCE(), [dart.dynamic])))();
  let dynamicToHashSetOfCE = () => (dynamicToHashSetOfCE = dart.constFn(dart.definiteFunctionType(HashSetOfCE(), [dart.dynamic])))();
  let dynamicToLinkedHashSetOfCE = () => (dynamicToLinkedHashSetOfCE = dart.constFn(dart.definiteFunctionType(LinkedHashSetOfCE(), [dart.dynamic])))();
  let dynamicToSplayTreeSetOfCE = () => (dynamicToSplayTreeSetOfCE = dart.constFn(dart.definiteFunctionType(SplayTreeSetOfCE(), [dart.dynamic])))();
  let dynamicToSetOfA = () => (dynamicToSetOfA = dart.constFn(dart.definiteFunctionType(SetOfA(), [dart.dynamic])))();
  let dynamicToHashSetOfA = () => (dynamicToHashSetOfA = dart.constFn(dart.definiteFunctionType(HashSetOfA(), [dart.dynamic])))();
  let dynamicToLinkedHashSetOfA = () => (dynamicToLinkedHashSetOfA = dart.constFn(dart.definiteFunctionType(LinkedHashSetOfA(), [dart.dynamic])))();
  let dynamicToSplayTreeSetOfA = () => (dynamicToSplayTreeSetOfA = dart.constFn(dart.definiteFunctionType(SplayTreeSetOfA(), [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  set_test.testMain = function(create) {
    set_test.testInts(create);
    set_test.testStrings(create);
    set_test.testInts(dart.fn(() => create().toSet(), VoidToSet$()));
    set_test.testStrings(dart.fn(() => create().toSet(), VoidToSet$()));
  };
  dart.fn(set_test.testMain, FnTovoid());
  set_test.testInts = function(create) {
    let set = create();
    set_test.testLength(0, set);
    expect$.Expect.isTrue(set.add(1));
    set_test.testLength(1, set);
    expect$.Expect.isTrue(set.contains(1));
    expect$.Expect.isFalse(set.add(1));
    set_test.testLength(1, set);
    expect$.Expect.isTrue(set.contains(1));
    expect$.Expect.isTrue(set.remove(1));
    set_test.testLength(0, set);
    expect$.Expect.isFalse(set.contains(1));
    expect$.Expect.isFalse(set.remove(1));
    set_test.testLength(0, set);
    expect$.Expect.isFalse(set.contains(1));
    for (let i = 0; i < 10; i++) {
      set.add(i);
    }
    set_test.testLength(10, set);
    for (let i = 0; i < 10; i++) {
      expect$.Expect.isTrue(set.contains(i));
    }
    set_test.testLength(10, set);
    for (let i = 10; i < 20; i++) {
      expect$.Expect.isFalse(set.contains(i));
    }
    let sum = 0;
    function testForEach(val) {
      sum = sum + (dart.notNull(val) + 1);
    }
    dart.fn(testForEach, intTodynamic());
    set.forEach(testForEach);
    expect$.Expect.equals(10 + 9 + 8 + 7 + 6 + 5 + 4 + 3 + 2 + 1, sum);
    expect$.Expect.isTrue(set.containsAll(set));
    function testMap(val) {
      return dart.notNull(val) * dart.notNull(val);
    }
    dart.fn(testMap, intToint());
    let mapped = set.map(core.int)(testMap)[dartx.toSet]();
    expect$.Expect.equals(10, mapped.length);
    expect$.Expect.isTrue(mapped.contains(0));
    expect$.Expect.isTrue(mapped.contains(1));
    expect$.Expect.isTrue(mapped.contains(4));
    expect$.Expect.isTrue(mapped.contains(9));
    expect$.Expect.isTrue(mapped.contains(16));
    expect$.Expect.isTrue(mapped.contains(25));
    expect$.Expect.isTrue(mapped.contains(36));
    expect$.Expect.isTrue(mapped.contains(49));
    expect$.Expect.isTrue(mapped.contains(64));
    expect$.Expect.isTrue(mapped.contains(81));
    sum = 0;
    set.forEach(testForEach);
    expect$.Expect.equals(10 + 9 + 8 + 7 + 6 + 5 + 4 + 3 + 2 + 1, sum);
    sum = 0;
    mapped.forEach(testForEach);
    expect$.Expect.equals(1 + 2 + 5 + 10 + 17 + 26 + 37 + 50 + 65 + 82, sum);
    function testFilter(val) {
      return val[dartx.isEven];
    }
    dart.fn(testFilter, intTobool());
    let filtered = set.where(testFilter)[dartx.toSet]();
    expect$.Expect.equals(5, filtered.length);
    expect$.Expect.isTrue(filtered.contains(0));
    expect$.Expect.isTrue(filtered.contains(2));
    expect$.Expect.isTrue(filtered.contains(4));
    expect$.Expect.isTrue(filtered.contains(6));
    expect$.Expect.isTrue(filtered.contains(8));
    sum = 0;
    filtered.forEach(testForEach);
    expect$.Expect.equals(1 + 3 + 5 + 7 + 9, sum);
    expect$.Expect.isTrue(set.containsAll(filtered));
    function testEvery(val) {
      return dart.notNull(val) < 10;
    }
    dart.fn(testEvery, intTobool());
    expect$.Expect.isTrue(set.every(testEvery));
    expect$.Expect.isTrue(filtered.every(testEvery));
    filtered.add(10);
    expect$.Expect.isFalse(filtered.every(testEvery));
    function testSome(val) {
      return val == 4;
    }
    dart.fn(testSome, intTobool());
    expect$.Expect.isTrue(set.any(testSome));
    expect$.Expect.isTrue(filtered.any(testSome));
    filtered.remove(4);
    expect$.Expect.isFalse(filtered.any(testSome));
    let intersection = set.intersection(filtered);
    expect$.Expect.isTrue(set.contains(0));
    expect$.Expect.isTrue(set.contains(2));
    expect$.Expect.isTrue(set.contains(6));
    expect$.Expect.isTrue(set.contains(8));
    expect$.Expect.isFalse(intersection.contains(1));
    expect$.Expect.isFalse(intersection.contains(3));
    expect$.Expect.isFalse(intersection.contains(4));
    expect$.Expect.isFalse(intersection.contains(5));
    expect$.Expect.isFalse(intersection.contains(7));
    expect$.Expect.isFalse(intersection.contains(9));
    expect$.Expect.isFalse(intersection.contains(10));
    expect$.Expect.equals(4, intersection.length);
    expect$.Expect.isTrue(set.containsAll(intersection));
    expect$.Expect.isTrue(filtered.containsAll(intersection));
    let twice = create();
    twice.addAll(JSArrayOfint().of([0, 2, 4, 6, 8, 10, 12, 14]));
    let thrice = create();
    thrice.addAll(JSArrayOfint().of([0, 3, 6, 9, 12, 15]));
    let union = twice.union(thrice);
    expect$.Expect.equals(11, union.length);
    for (let i = 0; i < 16; i++) {
      expect$.Expect.equals(dart.test(i[dartx.isEven]) || i[dartx['%']](3) == 0, union.contains(i));
    }
    let difference = twice.difference(thrice);
    expect$.Expect.equals(5, difference.length);
    for (let i = 0; i < 16; i++) {
      expect$.Expect.equals(dart.test(i[dartx.isEven]) && i[dartx['%']](3) != 0, difference.contains(i));
    }
    expect$.Expect.isTrue(twice.difference(thrice).difference(twice).isEmpty);
    let list = core.List.new(10);
    for (let i = 0; i < 10; i++) {
      list[dartx.set](i, i + 10);
    }
    set.addAll(list);
    set_test.testLength(20, set);
    for (let i = 0; i < 20; i++) {
      expect$.Expect.isTrue(set.contains(i));
    }
    set.removeAll(list);
    set_test.testLength(10, set);
    for (let i = 0; i < 10; i++) {
      expect$.Expect.isTrue(set.contains(i));
    }
    for (let i = 10; i < 20; i++) {
      expect$.Expect.isFalse(set.contains(i));
    }
    set.clear();
    set_test.testLength(0, set);
    expect$.Expect.isTrue(set.add(11));
    set_test.testLength(1, set);
    set.add(1);
    set.add(21);
    set_test.testLength(3, set);
    let set2 = set.toSet();
    set_test.testLength(3, set2);
    expect$.Expect.listEquals(set.toList(), set2.toList());
    set.add(31);
    set_test.testLength(4, set);
    set_test.testLength(3, set2);
    set2 = set.toSet();
    set2.clear();
    set_test.testLength(0, set2);
    expect$.Expect.isTrue(set2.add(11));
    expect$.Expect.isTrue(set2.add(1));
    expect$.Expect.isTrue(set2.add(21));
    expect$.Expect.isTrue(set2.add(31));
    set_test.testLength(4, set2);
    expect$.Expect.listEquals(set.toList(), set2.toList());
    set2 = (() => {
      let _ = set.toSet();
      _.clear();
      return _;
    })().toSet();
    set_test.testLength(0, set2);
  };
  dart.fn(set_test.testInts, FnTovoid());
  set_test.testLength = function(length, set) {
    expect$.Expect.equals(length, set.length);
    dart.dcall(length == 0 ? expect$.Expect.isTrue : expect$.Expect.isFalse, set.isEmpty);
    dart.dcall(length != 0 ? expect$.Expect.isTrue : expect$.Expect.isFalse, set.isNotEmpty);
    if (length == 0) {
      for (let e of set) {
        expect$.Expect.fail(dart.str`contains element when iterated: ${e}`);
      }
    }
    dart.dcall(length == 0 ? expect$.Expect.isFalse : expect$.Expect.isTrue, set.iterator.moveNext());
  };
  dart.fn(set_test.testLength, intAndSetTovoid());
  set_test.testStrings = function(create) {
    let set = create();
    let strings = JSArrayOfString().of(["foo", "bar", "baz", "qux", "fisk", "hest", "svin", "pigvar"]);
    set.addAll(strings);
    set_test.testLength(8, set);
    set.removeAll(strings[dartx.where](dart.fn(x => x[dartx.length] == 3, StringTobool())));
    set_test.testLength(4, set);
    expect$.Expect.isTrue(set.add("bar"));
    expect$.Expect.isTrue(set.add("qux"));
    set_test.testLength(6, set);
    set.addAll(strings);
    set_test.testLength(8, set);
    set.removeWhere(dart.fn(x => !dart.equals(dart.dload(x, 'length'), 3), dynamicTobool$()));
    set_test.testLength(4, set);
    set.retainWhere(dart.fn(x => dart.equals(dart.dindex(x, 1), "a"), dynamicTobool$()));
    set_test.testLength(2, set);
    expect$.Expect.isTrue(set.containsAll(JSArrayOfObject().of(["baz", "bar"])));
    set = set.union(strings[dartx.where](dart.fn(x => x[dartx.length] != 3, StringTobool()))[dartx.toSet]());
    set_test.testLength(6, set);
    set = set.intersection(JSArrayOfString().of(["qux", "baz", "fisk", "egern"])[dartx.toSet]());
    set_test.testLength(2, set);
    expect$.Expect.isTrue(set.containsAll(JSArrayOfObject().of(["baz", "fisk"])));
  };
  dart.fn(set_test.testStrings, FnTovoid());
  set_test.testTypeAnnotations = function(set) {
    set.add(0);
    set.add(999);
    set.add(34359738368);
    set.add(9007199254740992);
    expect$.Expect.isFalse(set.contains("not an it"));
    expect$.Expect.isFalse(set.remove("not an it"));
    expect$.Expect.isFalse(set.containsAll(JSArrayOfObject().of(["Not an int", "Also no an int"])));
    set_test.testLength(4, set);
    set.removeAll(JSArrayOfObject().of(["Not an int", 999, "Also no an int"]));
    set_test.testLength(3, set);
    set.retainAll(JSArrayOfObject().of(["Not an int", 0, "Also no an int"]));
    set_test.testLength(1, set);
  };
  dart.fn(set_test.testTypeAnnotations, SetOfintTovoid());
  set_test.testRetainWhere = function(create) {
    let set = dart.dcall(create);
    set.addAll(JSArrayOfCE().of([new set_test.CE(0), new set_test.CE(1), new set_test.CE(2)]));
    expect$.Expect.equals(3, set.length);
    set.retainAll(JSArrayOfObject().of([new set_test.CE(0), new set_test.CE(2)]));
    expect$.Expect.equals(2, set.length);
    expect$.Expect.isTrue(set.contains(new set_test.CE(0)));
    expect$.Expect.isTrue(set.contains(new set_test.CE(2)));
    let elems = JSArrayOfCE().of([new set_test.CE(0), new set_test.CE(1), new set_test.CE(2), new set_test.CE(0)]);
    set = dart.dcall(create, core.identical, null, null, set_test.identityCompare);
    set.addAll(elems);
    expect$.Expect.equals(4, set.length);
    set.retainAll(JSArrayOfObject().of([elems[dartx.get](0), elems[dartx.get](2), elems[dartx.get](3)]));
    expect$.Expect.equals(3, set.length);
    expect$.Expect.isTrue(set.contains(elems[dartx.get](0)));
    expect$.Expect.isTrue(set.contains(elems[dartx.get](2)));
    expect$.Expect.isTrue(set.contains(elems[dartx.get](3)));
    set = dart.dcall(create, set_test.customEq(3), set_test.customHash(3), set_test.validKey, set_test.customCompare(3));
    set.addAll(JSArrayOfCE().of([new set_test.CE(0), new set_test.CE(1), new set_test.CE(2)]));
    expect$.Expect.equals(3, set.length);
    set.retainAll(JSArrayOfObject().of([new set_test.CE(3), new set_test.CE(5)]));
    expect$.Expect.equals(2, set.length);
    expect$.Expect.isTrue(set.contains(new set_test.CE(6)));
    expect$.Expect.isTrue(set.contains(new set_test.CE(8)));
    set.clear();
    set.addAll(JSArrayOfCE().of([new set_test.CE(0), new set_test.CE(1), new set_test.CE(2)]));
    expect$.Expect.equals(3, set.length);
    set.retainAll(SetOfObject().from(JSArrayOfObject().of([new set_test.CE(3), new set_test.CE(5)])));
    expect$.Expect.equals(2, set.length);
    expect$.Expect.isTrue(set.contains(new set_test.CE(6)));
    expect$.Expect.isTrue(set.contains(new set_test.CE(8)));
  };
  dart.fn(set_test.testRetainWhere, FnTovoid$());
  set_test.testDifferenceIntersection = function(create) {
    let ce1a = new set_test.CE(1);
    let ce1b = new set_test.CE(1);
    let ce2 = new set_test.CE(2);
    let ce3 = new set_test.CE(3);
    expect$.Expect.equals(ce1a, ce1b);
    let set1 = dart.dcall(create);
    let set2 = dart.dcall(create);
    dart.dsend(set1, 'add', ce1a);
    dart.dsend(set1, 'add', ce2);
    dart.dsend(set2, 'add', ce1b);
    dart.dsend(set2, 'add', ce3);
    let difference = dart.dsend(set1, 'difference', set2);
    set_test.testLength(1, core.Set._check(difference));
    expect$.Expect.identical(ce2, dart.dsend(difference, 'lookup', ce2));
    difference = dart.dsend(set2, 'difference', set1);
    set_test.testLength(1, core.Set._check(difference));
    expect$.Expect.identical(ce3, dart.dsend(difference, 'lookup', ce3));
    let set3 = dart.dcall(create, core.identical, core.identityHashCode, null, set_test.identityCompare);
    dart.dsend(set3, 'add', ce1b);
    difference = dart.dsend(set1, 'difference', set3);
    set_test.testLength(2, core.Set._check(difference));
    expect$.Expect.identical(ce1a, dart.dsend(difference, 'lookup', ce1a));
    expect$.Expect.identical(ce2, dart.dsend(difference, 'lookup', ce2));
    let intersection = dart.dsend(set1, 'intersection', set2);
    set_test.testLength(1, core.Set._check(intersection));
    expect$.Expect.identical(ce1a, dart.dsend(intersection, 'lookup', ce1a));
    intersection = dart.dsend(set1, 'intersection', set3);
    set_test.testLength(0, core.Set._check(intersection));
  };
  dart.fn(set_test.testDifferenceIntersection, FnTovoid$0());
  set_test.CE = class CE extends core.Object {
    new(id) {
      this.id = id;
    }
    get hashCode() {
      return this.id;
    }
    ['=='](other) {
      return set_test.CE.is(other) && this.id == other.id;
    }
    compareTo(other) {
      return dart.notNull(this.id) - dart.notNull(other.id);
    }
    toString() {
      return dart.str`CE(${this.id})`;
    }
  };
  set_test.CE[dart.implements] = () => [ComparableOfCE()];
  dart.setSignature(set_test.CE, {
    constructors: () => ({new: dart.definiteFunctionType(set_test.CE, [core.int])}),
    methods: () => ({
      '==': dart.definiteFunctionType(core.bool, [core.Object]),
      compareTo: dart.definiteFunctionType(core.int, [set_test.CE])
    })
  });
  dart.defineExtensionMembers(set_test.CE, ['compareTo']);
  set_test.customEq = function(mod) {
    return dart.fn((e1, e2) => (dart.notNull(e1.id) - dart.notNull(e2.id))[dartx['%']](mod) == 0, CEAndCETobool());
  };
  dart.fn(set_test.customEq, intToFunction());
  set_test.customHash = function(mod) {
    return dart.fn(e => e.id[dartx['%']](mod), CEToint());
  };
  dart.fn(set_test.customHash, intToFunction());
  set_test.customCompare = function(mod) {
    return dart.fn((e1, e2) => e1.id[dartx['%']](mod) - e2.id[dartx['%']](mod), CEAndCEToint$());
  };
  dart.fn(set_test.customCompare, intToFunction());
  set_test.validKey = function(o) {
    return set_test.CE.is(o);
  };
  dart.fn(set_test.validKey, ObjectTobool$());
  dart.defineLazy(set_test, {
    get customId() {
      return core.Map.identity();
    }
  });
  set_test.counter = 0;
  set_test.identityCompare = function(e1, e2) {
    if (core.identical(e1, e2)) return 0;
    let i1 = core.int._check(set_test.customId[dartx.putIfAbsent](e1, dart.fn(() => (set_test.counter = dart.notNull(set_test.counter) + 1), VoidToint())));
    let i2 = core.int._check(set_test.customId[dartx.putIfAbsent](e2, dart.fn(() => (set_test.counter = dart.notNull(set_test.counter) + 1), VoidToint())));
    return dart.notNull(i1) - dart.notNull(i2);
  };
  dart.fn(set_test.identityCompare, dynamicAnddynamicToint$());
  set_test.testIdentity = function(create) {
    let set = create();
    let e1 = new set_test.CE(0);
    let e2 = new set_test.CE(0);
    expect$.Expect.equals(e1, e2);
    expect$.Expect.isFalse(core.identical(e1, e2));
    set_test.testLength(0, set);
    set.add(e1);
    set_test.testLength(1, set);
    expect$.Expect.isTrue(set.contains(e1));
    expect$.Expect.isFalse(set.contains(e2));
    set.add(e2);
    set_test.testLength(2, set);
    expect$.Expect.isTrue(set.contains(e1));
    expect$.Expect.isTrue(set.contains(e2));
    let set2 = set.toSet();
    set_test.testLength(2, set2);
    expect$.Expect.isTrue(set2.contains(e1));
    expect$.Expect.isTrue(set2.contains(e2));
  };
  dart.fn(set_test.testIdentity, FnTovoid());
  set_test.testIntSetFrom = function(setFrom) {
    let numList = JSArrayOfnum().of([2, 3, 5, 7, 11, 13]);
    let set1 = SetOfint()._check(dart.dcall(setFrom, numList));
    expect$.Expect.listEquals(numList, (() => {
      let _ = set1.toList();
      _[dartx.sort]();
      return _;
    })());
    let numSet = numList[dartx.toSet]();
    let set2 = SetOfint()._check(dart.dcall(setFrom, numSet));
    expect$.Expect.listEquals(numList, (() => {
      let _ = set2.toList();
      _[dartx.sort]();
      return _;
    })());
    let numIter = numList[dartx.where](dart.fn(x => true, numTobool()));
    let set3 = SetOfint()._check(dart.dcall(setFrom, numIter));
    expect$.Expect.listEquals(numList, (() => {
      let _ = set3.toList();
      _[dartx.sort]();
      return _;
    })());
    let set4 = SetOfint()._check(dart.dcall(setFrom, core.Iterable.generate(0)));
    expect$.Expect.isTrue(set4.isEmpty);
  };
  dart.fn(set_test.testIntSetFrom, dynamicTovoid());
  set_test.testCESetFrom = function(setFrom) {
    let ceList = JSArrayOfObject().of([new set_test.CE(2), new set_test.CE(3), new set_test.CE(5), new set_test.CE(7), new set_test.CE(11), new set_test.CE(13)]);
    let set1 = SetOfCE()._check(dart.dcall(setFrom, ceList));
    expect$.Expect.listEquals(ceList, (() => {
      let _ = set1.toList();
      _[dartx.sort]();
      return _;
    })());
    let ceSet = SetOfCE()._check(ceList[dartx.toSet]());
    let set2 = SetOfCE()._check(dart.dcall(setFrom, ceSet));
    expect$.Expect.listEquals(ceList, (() => {
      let _ = set2.toList();
      _[dartx.sort]();
      return _;
    })());
    let ceIter = IterableOfCE()._check(ceList[dartx.where](dart.fn(x => true, ObjectTobool$())));
    let set3 = SetOfCE()._check(dart.dcall(setFrom, ceIter));
    expect$.Expect.listEquals(ceList, (() => {
      let _ = set3.toList();
      _[dartx.sort]();
      return _;
    })());
    let set4 = SetOfCE()._check(dart.dcall(setFrom, core.Iterable.generate(0)));
    expect$.Expect.isTrue(set4.isEmpty);
  };
  dart.fn(set_test.testCESetFrom, dynamicTovoid());
  set_test.A = class A extends core.Object {};
  set_test.B = class B extends core.Object {};
  set_test.C = class C extends core.Object {};
  set_test.C[dart.implements] = () => [set_test.A, set_test.B];
  set_test.testASetFrom = function(setFrom) {
    let bList = JSArrayOfB().of([new set_test.C()]);
    let aSet = SetOfA()._check(dart.dcall(setFrom, bList));
    expect$.Expect.isTrue(aSet.length == 1);
  };
  dart.fn(set_test.testASetFrom, dynamicTovoid());
  set_test.main = function() {
    set_test.testMain(dart.fn(() => collection.HashSet.new(), VoidToHashSet()));
    set_test.testMain(dart.fn(() => collection.LinkedHashSet.new(), VoidToLinkedHashSet()));
    set_test.testMain(dart.fn(() => collection.HashSet.identity(), VoidToHashSet()));
    set_test.testMain(dart.fn(() => collection.LinkedHashSet.identity(), VoidToLinkedHashSet()));
    set_test.testMain(dart.fn(() => collection.HashSet.new({equals: core.identical}), VoidToHashSet()));
    set_test.testMain(dart.fn(() => collection.LinkedHashSet.new({equals: core.identical}), VoidToLinkedHashSet()));
    set_test.testMain(dart.fn(() => collection.HashSet.new({equals: dart.fn((a, b) => dart.equals(a, b), dynamicAnddynamicTobool$()), hashCode: dart.fn(a => -dart.notNull(dart.hashCode(a)), dynamicToint$()), isValidKey: dart.fn(a => true, ObjectTobool$())}), VoidToHashSet()));
    set_test.testMain(dart.fn(() => collection.LinkedHashSet.new({equals: dart.fn((a, b) => dart.equals(a, b), dynamicAnddynamicTobool$()), hashCode: dart.fn(a => -dart.notNull(dart.hashCode(a)), dynamicToint$()), isValidKey: dart.fn(a => true, ObjectTobool$())}), VoidToLinkedHashSet()));
    set_test.testMain(dart.fn(() => new collection.SplayTreeSet(), VoidToSplayTreeSet()));
    set_test.testIdentity(dart.fn(() => collection.HashSet.identity(), VoidToHashSet()));
    set_test.testIdentity(dart.fn(() => collection.LinkedHashSet.identity(), VoidToLinkedHashSet()));
    set_test.testIdentity(dart.fn(() => collection.HashSet.new({equals: core.identical}), VoidToHashSet()));
    set_test.testIdentity(dart.fn(() => collection.LinkedHashSet.new({equals: core.identical}), VoidToLinkedHashSet()));
    set_test.testIdentity(dart.fn(() => new collection.SplayTreeSet(set_test.identityCompare), VoidToSplayTreeSet()));
    set_test.testTypeAnnotations(HashSetOfint().new());
    set_test.testTypeAnnotations(LinkedHashSetOfint().new());
    set_test.testTypeAnnotations(HashSetOfint().new({equals: core.identical}));
    set_test.testTypeAnnotations(LinkedHashSetOfint().new({equals: core.identical}));
    set_test.testTypeAnnotations(HashSetOfint().new({equals: dart.fn((a, b) => a == b, intAndintTobool()), hashCode: dart.fn(a => dart.hashCode(a), intToint()), isValidKey: dart.fn(a => typeof a == 'number', ObjectTobool$())}));
    set_test.testTypeAnnotations(LinkedHashSetOfint().new({equals: dart.fn((a, b) => a == b, intAndintTobool()), hashCode: dart.fn(a => dart.hashCode(a), intToint()), isValidKey: dart.fn(a => typeof a == 'number', ObjectTobool$())}));
    set_test.testTypeAnnotations(new (SplayTreeSetOfint())());
    set_test.testRetainWhere(dart.fn((equals, hashCode, validKey, comparator) => {
      if (equals === void 0) equals = null;
      if (hashCode === void 0) hashCode = null;
      if (validKey === void 0) validKey = null;
      if (comparator === void 0) comparator = null;
      return collection.HashSet.new({equals: dynamicAnddynamicTobool()._check(equals), hashCode: dynamicToint()._check(hashCode), isValidKey: ObjectTobool()._check(validKey)});
    }, __ToHashSet()));
    set_test.testRetainWhere(dart.fn((equals, hashCode, validKey, comparator) => {
      if (equals === void 0) equals = null;
      if (hashCode === void 0) hashCode = null;
      if (validKey === void 0) validKey = null;
      if (comparator === void 0) comparator = null;
      return collection.LinkedHashSet.new({equals: dynamicAnddynamicTobool()._check(equals), hashCode: dynamicToint()._check(hashCode), isValidKey: ObjectTobool()._check(validKey)});
    }, __ToLinkedHashSet()));
    set_test.testRetainWhere(dart.fn((equals, hashCode, validKey, comparator) => {
      if (equals === void 0) equals = null;
      if (hashCode === void 0) hashCode = null;
      if (validKey === void 0) validKey = null;
      if (comparator === void 0) comparator = null;
      return new collection.SplayTreeSet(dynamicAnddynamicToint()._check(comparator), dynamicTobool()._check(validKey));
    }, __ToSplayTreeSet()));
    set_test.testDifferenceIntersection(dart.fn((equals, hashCode, validKey, comparator) => {
      if (equals === void 0) equals = null;
      if (hashCode === void 0) hashCode = null;
      if (validKey === void 0) validKey = null;
      if (comparator === void 0) comparator = null;
      return collection.HashSet.new({equals: dynamicAnddynamicTobool()._check(equals), hashCode: dynamicToint()._check(hashCode), isValidKey: ObjectTobool()._check(validKey)});
    }, __ToHashSet()));
    set_test.testDifferenceIntersection(dart.fn((equals, hashCode, validKey, comparator) => {
      if (equals === void 0) equals = null;
      if (hashCode === void 0) hashCode = null;
      if (validKey === void 0) validKey = null;
      if (comparator === void 0) comparator = null;
      return collection.LinkedHashSet.new({equals: dynamicAnddynamicTobool()._check(equals), hashCode: dynamicToint()._check(hashCode), isValidKey: ObjectTobool()._check(validKey)});
    }, __ToLinkedHashSet()));
    set_test.testDifferenceIntersection(dart.fn((equals, hashCode, validKey, comparator) => {
      if (equals === void 0) equals = null;
      if (hashCode === void 0) hashCode = null;
      if (validKey === void 0) validKey = null;
      if (comparator === void 0) comparator = null;
      return new collection.SplayTreeSet(dynamicAnddynamicToint()._check(comparator), dynamicTobool()._check(validKey));
    }, __ToSplayTreeSet()));
    set_test.testIntSetFrom(dart.fn(x => SetOfint().from(IterableOfint()._check(x)), dynamicToSetOfint()));
    set_test.testIntSetFrom(dart.fn(x => HashSetOfint().from(core.Iterable._check(x)), dynamicToHashSetOfint()));
    set_test.testIntSetFrom(dart.fn(x => LinkedHashSetOfint().from(core.Iterable._check(x)), dynamicToLinkedHashSetOfint()));
    set_test.testIntSetFrom(dart.fn(x => SplayTreeSetOfint().from(core.Iterable._check(x)), dynamicToSplayTreeSetOfint()));
    set_test.testCESetFrom(dart.fn(x => SetOfCE().from(IterableOfCE()._check(x)), dynamicToSetOfCE()));
    set_test.testCESetFrom(dart.fn(x => HashSetOfCE().from(core.Iterable._check(x)), dynamicToHashSetOfCE()));
    set_test.testCESetFrom(dart.fn(x => LinkedHashSetOfCE().from(core.Iterable._check(x)), dynamicToLinkedHashSetOfCE()));
    set_test.testCESetFrom(dart.fn(x => SplayTreeSetOfCE().from(core.Iterable._check(x)), dynamicToSplayTreeSetOfCE()));
    set_test.testCESetFrom(dart.fn(x => SplayTreeSetOfCE().from(core.Iterable._check(x), CEAndCEToint()._check(set_test.customCompare(20)), set_test.validKey), dynamicToSplayTreeSetOfCE()));
    set_test.testCESetFrom(dart.fn(x => SplayTreeSetOfCE().from(core.Iterable._check(x), set_test.identityCompare), dynamicToSplayTreeSetOfCE()));
    set_test.testASetFrom(dart.fn(x => SetOfA().from(IterableOfA()._check(x)), dynamicToSetOfA()));
    set_test.testASetFrom(dart.fn(x => HashSetOfA().from(core.Iterable._check(x)), dynamicToHashSetOfA()));
    set_test.testASetFrom(dart.fn(x => LinkedHashSetOfA().from(core.Iterable._check(x)), dynamicToLinkedHashSetOfA()));
    set_test.testASetFrom(dart.fn(x => SplayTreeSetOfA().from(core.Iterable._check(x), set_test.identityCompare), dynamicToSplayTreeSetOfA()));
  };
  dart.fn(set_test.main, VoidTodynamic());
  // Exports:
  exports.set_test = set_test;
});
