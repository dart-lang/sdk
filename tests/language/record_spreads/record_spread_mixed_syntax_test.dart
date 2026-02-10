// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=record-spreads

/// Test record spreading combined with various Dart syntax features.

import "package:expect/expect.dart";

// -- Helpers --

List<String> log = [];

T tracked<T>(String label, T value) {
  log.add(label);
  return value;
}

(int, int) makePoint(int x, int y) => (x, y);

({String color, int alpha}) makeStyle() => (color: 'red', alpha: 255);

// -- Tests --

/// Record spreads inside lists, sets, and maps.
void testCollections() {
  var pair = (1, 2);
  var spread = (...pair, 3);

  // List containing spread records.
  var list = [spread, (...pair, 4), (...pair, 5)];
  Expect.equals(3, list.length);
  Expect.equals(3, list[0].$3);
  Expect.equals(4, list[1].$3);
  Expect.equals(5, list[2].$3);

  // Set containing spread records.
  var set = {(...pair, 10), (...pair, 20)};
  Expect.equals(2, set.length);

  // Map with spread records as values.
  var map = {
    'a': (...pair, 100),
    'b': (...pair, 200),
  };
  Expect.equals(100, map['a']!.$3);
  Expect.equals(200, map['b']!.$3);

  // List spread + record spread in the same expression.
  var records = [(...pair, 'x'), (...pair, 'y')];
  var combined = [...records, (...pair, 'z')];
  Expect.equals(3, combined.length);
  Expect.equals('z', combined[2].$3);
}

/// Record spreads with pattern matching.
void testPatternMatching() {
  var coords = (x: 10, y: 20);
  var point3d = (...coords, z: 30);

  // Destructure a spread record with a record pattern.
  var (x: px, y: py, z: pz) = point3d;
  Expect.equals(10, px);
  Expect.equals(20, py);
  Expect.equals(30, pz);

  // Switch expression on a spread record.
  var pair = (1, 2);
  var triple = (...pair, 3);
  var result = switch (triple) {
    (1, 2, 3) => 'match',
    _ => 'no match',
  };
  Expect.equals('match', result);

  // If-case with spread record.
  var named = (status: 'ok', code: 200);
  var response = (...named, body: 'hello');
  if (response case (status: 'ok', code: 200, body: var b)) {
    Expect.equals('hello', b);
  } else {
    Expect.fail('Pattern should match');
  }

  // Positional destructuring of spread record.
  var ab = (10, 20);
  var abc = (...ab, 30);
  var (a, b, c) = abc;
  Expect.equals(10, a);
  Expect.equals(20, b);
  Expect.equals(30, c);
}

/// Record spreads with functions, closures, and higher-order functions.
void testFunctions() {
  // Spread record as function argument.
  (int, int, int) identity((int, int, int) r) => r;
  var pair = (1, 2);
  var result = identity((...pair, 3));
  Expect.equals(3, result.$3);

  // Function returning a spread record.
  (int, int, String) extend((int, int) base) => (...base, 'done');
  var extended = extend((5, 6));
  Expect.equals(5, extended.$1);
  Expect.equals('done', extended.$3);

  // Closure capturing a record and spreading it.
  var base = (a: 1, b: 2);
  var addC = () => (...base, c: 3);
  var withC = addC();
  Expect.equals(1, withC.a);
  Expect.equals(2, withC.b);
  Expect.equals(3, withC.c);

  // Higher-order: map over a list, spreading into each result.
  var prefix = (tag: 'item');
  var items = [1, 2, 3].map((i) => (...prefix, index: i)).toList();
  Expect.equals(3, items.length);
  Expect.equals('item', items[0].tag);
  Expect.equals(2, items[1].index);

  // Spread record passed to generic function.
  T firstOf3<T>((T, T, T) triple) => triple.$1;
  var nums = (10, 20);
  Expect.equals(10, firstOf3((...nums, 30)));
}

/// Record spreads with conditional and null-aware expressions.
void testConditionals() {
  var small = (1, 2);
  var big = (100, 200);

  // Ternary selecting which record to spread.
  bool flag = true;
  var chosen = (...(flag ? small : big), 3);
  Expect.equals(1, chosen.$1);
  Expect.equals(2, chosen.$2);
  Expect.equals(3, chosen.$3);

  flag = false;
  var chosen2 = (...(flag ? small : big), 3);
  Expect.equals(100, chosen2.$1);
  Expect.equals(200, chosen2.$2);

  // Null-coalescing to get a record to spread.
  (int, int)? maybeNull;
  var fallback = (42, 43);
  var result = (...(maybeNull ?? fallback), 99);
  Expect.equals(42, result.$1);
  Expect.equals(43, result.$2);
  Expect.equals(99, result.$3);
}

/// Record spreads with async/await.
Future<void> testAsync() async {
  Future<(int, int)> fetchPoint() async => (10, 20);

  var point = await fetchPoint();
  var point3d = (...point, 30);
  Expect.equals(10, point3d.$1);
  Expect.equals(20, point3d.$2);
  Expect.equals(30, point3d.$3);

  // Spread result of awaited function.
  Future<({String name, int age})> fetchPerson() async =>
      (name: 'Alice', age: 30);

  var person = await fetchPerson();
  var employee = (...person, role: 'Engineer');
  Expect.equals('Alice', employee.name);
  Expect.equals(30, employee.age);
  Expect.equals('Engineer', employee.role);

  // Async function returning a spread record.
  Future<(int, int, int)> extendPoint((int, int) base) async {
    await Future.delayed(Duration.zero);
    return (...base, 99);
  }

  var extended = await extendPoint((7, 8));
  Expect.equals(7, extended.$1);
  Expect.equals(8, extended.$2);
  Expect.equals(99, extended.$3);
}

/// Record spreads with string interpolation and toString.
void testStringInterpolation() {
  var base = (1, 2);
  var triple = (...base, 3);
  var s = '${triple.$1},${triple.$2},${triple.$3}';
  Expect.equals('1,2,3', s);

  // Interpolation of named fields from spread.
  var person = (name: 'Bob');
  var fullPerson = (...person, age: 25);
  var desc = '${fullPerson.name} is ${fullPerson.age}';
  Expect.equals('Bob is 25', desc);
}

/// Record spreads with type tests.
void testTypeTests() {
  var pair = (1, 2);
  var triple = (...pair, 3);

  Expect.isTrue(triple is (int, int, int));
  Expect.isTrue(triple is (num, num, num));
  Expect.isFalse(triple is (String, String, String));
  Expect.isTrue(triple is Record);

  // Named field type test after spread.
  var named = (x: 1.0, y: 2.0);
  var point3d = (...named, z: 3.0);
  Expect.isTrue(point3d is ({double x, double y, double z}));

  // Dynamic dispatch through Object.
  Object obj = (...pair, 'hello');
  Expect.isTrue(obj is (int, int, String));
  Expect.isFalse(obj is (int, int, int));
}

/// Spread records used as loop bodies and comprehension-like patterns.
void testLoops() {
  var prefix = (tag: 'v');

  // Build a list of spread records in a for loop.
  var results = <({String tag, int index})>[];
  for (var i = 0; i < 3; i++) {
    results.add((...prefix, index: i));
  }
  Expect.equals(3, results.length);
  Expect.equals(0, results[0].index);
  Expect.equals(2, results[2].index);
  Expect.equals('v', results[1].tag);

  // For-in destructuring spread records from a list.
  var pairs = [(1, 2), (3, 4), (5, 6)];
  var triples = [for (var p in pairs) (...p, p.$1 + p.$2)];
  Expect.equals(3, triples.length);
  Expect.equals((1, 2, 3), triples[0]);
  Expect.equals((3, 4, 7), triples[1]);
  Expect.equals((5, 6, 11), triples[2]);

  // If-element in collection with spread record.
  var base = (1, 2);
  var filtered = [
    for (var n in [10, 20, 30])
      if (n > 15) (...base, n),
  ];
  Expect.equals(2, filtered.length);
  Expect.equals(20, filtered[0].$3);
  Expect.equals(30, filtered[1].$3);
}

/// Nested records: records inside records, then spreading.
void testNestedRecords() {
  // Record containing a record field, then spread the outer.
  var inner = (nested: (1, 2));
  var outer = (...inner, extra: 3);
  Expect.equals(1, outer.nested.$1);
  Expect.equals(2, outer.nested.$2);
  Expect.equals(3, outer.extra);

  // Spread into a record that itself becomes a field of another record.
  var pair = (10, 20);
  var container = (label: 'data', payload: (...pair, 30));
  Expect.equals('data', container.label);
  Expect.equals(10, container.payload.$1);
  Expect.equals(30, container.payload.$3);

  // Deeply nested spreading.
  var a = (1,);
  var b = (...a, 2);
  var c = (...b, 3);
  var d = (...c, 4);
  Expect.equals((1, 2, 3, 4), d);
}

/// Record spreads with class instances and methods.
void testWithClasses() {
  var widget = _Widget('Button', width: 100, height: 50);
  var rec = widget.asRecord();
  var styled = (...rec, color: 'blue');
  Expect.equals('Button', styled.label);
  Expect.equals(100, styled.width);
  Expect.equals(50, styled.height);
  Expect.equals('blue', styled.color);

  // Spread from method return value.
  var dims = _Widget('Box', width: 200, height: 300).dimensions();
  var dims3d = (...dims, depth: 400);
  Expect.equals(200, dims3d.width);
  Expect.equals(300, dims3d.height);
  Expect.equals(400, dims3d.depth);
}

class _Widget {
  final String label;
  final int width;
  final int height;

  _Widget(this.label, {required this.width, required this.height});

  ({String label, int width, int height}) asRecord() =>
      (label: label, width: width, height: height);

  ({int width, int height}) dimensions() => (width: width, height: height);
}

/// Spread records used with typedef aliases.
void testTypedef() {
  // Spread a typedefed record.
  Point p = (1, 2);
  var p3 = (...p, 3);
  Expect.equals(1, p3.$1);
  Expect.equals(2, p3.$2);
  Expect.equals(3, p3.$3);

  NamedPoint np = (x: 10, y: 20);
  var np3 = (...np, z: 30);
  Expect.equals(10, np3.x);
  Expect.equals(20, np3.y);
  Expect.equals(30, np3.z);
}

typedef Point = (int, int);
typedef NamedPoint = ({int x, int y});

/// Complex evaluation order: spreads mixed with collection literals and calls.
void testComplexEvaluationOrder() {
  log.clear();
  var base = tracked('base', (1, 2));
  var result = (
    tracked('a', 10),
    ...tracked('spread', base),
    tracked('b', 30),
  );
  Expect.equals(10, result.$1);
  Expect.equals(1, result.$2);
  Expect.equals(2, result.$3);
  Expect.equals(30, result.$4);
  Expect.listEquals(['base', 'a', 'spread', 'b'], log);

  // Spread with method calls as field values.
  log.clear();
  var pair = tracked('pair', (100, 200));
  var withCalls = (
    tracked('first', 'hello').length,
    ...tracked('mid', pair),
    tracked('last', [1, 2, 3]).length,
  );
  Expect.equals(5, withCalls.$1);
  Expect.equals(100, withCalls.$2);
  Expect.equals(200, withCalls.$3);
  Expect.equals(3, withCalls.$4);
  Expect.listEquals(['pair', 'first', 'mid', 'last'], log);
}

/// Record spreads used in switch statement cases and guard clauses.
void testSwitchGuards() {
  var base = (x: 1, y: 2);
  var point = (...base, z: 3);

  // Switch with guard clause on spread record fields.
  var label = switch (point) {
    (x: var x, y: var y, z: var z) when x + y + z > 5 => 'big',
    (x: var x, y: var y, z: var z) when x + y + z > 0 => 'small',
    _ => 'zero',
  };
  Expect.equals('big', label);

  // Nested pattern with wildcard on spread fields.
  var pair = (10, 20);
  var quad = (...pair, 30, 40);
  var matched = switch (quad) {
    (10, _, 30, _) => 'partial',
    _ => 'none',
  };
  Expect.equals('partial', matched);
}

/// Record spreads with cascade-like access chains.
void testAccessChains() {
  var pair = (1, 2);
  var triple = (...pair, 3);

  // Multiple field accesses in a single expression.
  var sum = triple.$1 + triple.$2 + triple.$3;
  Expect.equals(6, sum);

  // Chained record creation and access.
  var value = (...(10, 20), 30).$3;
  Expect.equals(30, value);

  // Spread record field used as index.
  var indices = (...(0, 2), 4);
  var data = ['a', 'b', 'c', 'd', 'e'];
  Expect.equals('a', data[indices.$1]);
  Expect.equals('c', data[indices.$2]);
  Expect.equals('e', data[indices.$3]);
}

/// Record spreads inside try/catch.
void testExceptionHandling() {
  var base = (code: 404);

  try {
    var error = (...base, message: 'Not Found');
    throw error;
  } catch (e) {
    // The thrown record should be catchable and usable.
    var rec = e as ({int code, String message});
    Expect.equals(404, rec.code);
    Expect.equals('Not Found', rec.message);
  }
}

/// Record spreads with const and non-const in the same scope.
void testConstAndNonConst() {
  const base = (1, 2);
  const constTriple = (...base, 3);

  var runtimeBase = (1, 2);
  var runtimeTriple = (...runtimeBase, 3);

  // Const and runtime should be equal.
  Expect.equals(constTriple, runtimeTriple);

  // Const should be identical (canonicalized).
  const another = (...base, 3);
  Expect.identical(constTriple, another);
}

void main() async {
  testCollections();
  testPatternMatching();
  testFunctions();
  testConditionals();
  await testAsync();
  testStringInterpolation();
  testTypeTests();
  testLoops();
  testNestedRecords();
  testWithClasses();
  testTypedef();
  testComplexEvaluationOrder();
  testSwitchGuards();
  testAccessChains();
  testExceptionHandling();
  testConstAndNonConst();
}
