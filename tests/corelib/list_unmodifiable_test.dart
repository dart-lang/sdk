// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:collection";
import "dart:typed_data";

main() {
  var intTest = new Test<int>();
  intTest.run("ConstList", createConstList);
  intTest.run("FixedList", createFixedList);
  intTest.run("GrowableList", createGrowableList);
  intTest.run("ConstMapKeys", createConstMapKeys);
  intTest.run("ConstMapValues", createConstMapValues);
  intTest.run("MapKeys", createMapKeys);
  intTest.run("MapValues", createMapValues);
  intTest.run("SplayMapKeys", createSplayMapKeys);
  intTest.run("SplayMapValues", createSplayMapValues);
  intTest.run("Set", createSet);
  intTest.run("SplaySet", createSplaySet);
  intTest.run("Queue", createQueue);
  intTest.run("ListMapKeys", createListMapKeys);
  intTest.run("ListMapValues", createListMapValues);
  intTest.run("CodeUnits", createCodeUnits);
  intTest.run("TypedList", createTypedList);

  new Test<String>().test("strings", ["a", "b", "c"]);

  new Test<num>().test("superclass", <int>[1, 2, 3]);
  new Test<int>().test("subclass", <num>[1, 2, 3]);
}

class Test<E> {
  run(name, Iterable create(int size)) {
    test(name, create(0));
    test(name, create(1));
    test(name, create(3));
  }

  test(name, iterable) {
    testSingle(name, iterable);
    testSingle("$name-where", iterable.where((x) => true));
    testSingle("$name-map", iterable.map((x) => x));
    testSingle("$name-expand", iterable.expand((x) => [x, x]));
    testSingle("$name-skip", iterable.skip(1));
    testSingle("$name-take", iterable.take(2));
    testSingle("$name-skipWhile", iterable.skipWhile((x) => false));
    testSingle("$name-takeWhile", iterable.takeWhile((x) => true));
  }

  testSingle(name, iterable) {
    var elements = iterable.toList();
    int length = elements.length;

    var list = new List<E>.unmodifiable(iterable);

    Expect.isTrue(list is List<E>, "$name-type-$E");
    Expect.isTrue(list is! List<Test>, "$name-!type-!$E");

    checkElements() {
      Expect.equals(length, list.length);
      for (int i = 0; i < length; i++) {
        Expect.identical(elements[i], list[i], "$name-identical-$i");
      }
    }

    checkElements();

    throws(funcName, func) {
      try {
        func();
      } catch (e, s) {
        Expect.isTrue(e is UnsupportedError, "$name: $funcName threw $e");
        return;
      }
      checkElements();
      Expect.fail("$name: $funcName didn't throw");
    }

    throws("[]=", () {
      list[0] = null;
    });
    throws("length=", () {
      list.length = length + 1;
    });
    throws("length=", () {
      list.length = length - 1;
    });
    throws("setAll", () {
      list.setAll(0, []);
    });
    throws("add", () {
      list.add(null);
    });
    throws("insert", () {
      list.insert(0, null);
    });
    throws("insertAll", () {
      list.insertAll(0, []);
    });
    throws("addAll", () {
      list.addAll([]);
    });
    throws("remove", () {
      list.remove(null);
    });
    throws("removeWhere", () {
      list.removeWhere((x) => true);
    });
    throws("retainWhere", () {
      list.retainWhere((x) => false);
    });
    throws("sort", () {
      list.sort();
    });
    throws("shuffle", () {
      list.shuffle();
    });
    throws("clear", () {
      list.clear();
    });
    throws("removeAt", () {
      list.removeAt(0);
    });
    throws("removeLast", () {
      list.removeLast();
    });
    throws("setRange", () {
      list.setRange(0, 1, []);
    });
    throws("removeRange", () {
      list.removeRange(0, 1);
    });
    throws("replaceRange", () {
      list.replaceRange(0, 1, []);
    });
    throws("fillRange", () {
      list.fillRange(0, 1, null);
    });

    success(opName, op(list)) {
      var expect;
      try {
        expect = op(elements);
      } catch (e) {
        try {
          op(list);
        } catch (e2) {
          Expect.equals(
              e.runtimeType,
              e2.runtimeType,
              "$name :: $opName threw different exceptions: "
              "${e.runtimeType} vs ${e2.runtimeType}");
          return;
        }
        Expect.fail("$name-$opName didn't throw, expected: $e");
      }
      var actual = op(list);
      checkElements();
      if (expect is List) {
        Expect.listEquals(expect, actual, "$name-$opName");
      } else if (expect is Iterable) {
        Expect.isTrue(actual is Iterable);
        Expect.listEquals(expect.toList(), actual.toList(), "$name-$opName");
      } else {
        Expect.equals(expect, actual, "$name-$opName");
      }
    }

    success("indexOf", (l) => l.indexOf(null));
    success("lastIndexOf", (l) => l.lastIndexOf(null));
    success("contains", (l) => l.contains(2));
    success("elementAt", (l) => l.elementAt[1]);
    success("reversed", (l) => l.reversed);
    success("sublist0-1", (l) => l.sublist(0, 1));
    success("getRange0-1", (l) => l.getRange(0, 1));
    success("asMap-keys", (l) => l.asMap().keys);
    success("asMap-values", (l) => l.asMap().values);
    success("where", (l) => l.where((x) => true));
    success("map", (l) => l.map((x) => x));
    success("expand", (l) => l.expand((x) => [x, x]));
    success("skip", (l) => l.skip(1));
    success("take", (l) => l.take(1));
    success("skipWhile", (l) => l.skipWhile((x) => false));
    success("takeWhile", (l) => l.takeWhile((x) => true));
    success("first", (l) => l.first);
    success("last", (l) => l.last);
    success("single", (l) => l.single);
    success("firstWhere", (l) => l.firstWhere((x) => true));
    success("lastWhere", (l) => l.lastWhere((x) => true));
    success("singleWhere", (l) => l.singleWhere((x) => true));
    success("isEmpty", (l) => l.isEmpty);
    success("isNotEmpty", (l) => l.isNotEmpty);
    success("join", (l) => l.join("/"));
    success("fold", (l) => l.fold("--", (a, b) => "$a/$b"));
    success("reduce", (l) => l.reduce((a, b) => a + b));
    success("every", (l) => l.every((x) => x == 0));
    success("any", (l) => l.any((x) => x == 2));
    success("toList", (l) => l.toList());
    success("toSet", (l) => l.toSet());
    success("toString", (l) => l.toString());

    var it = elements.iterator;
    list.forEach((v) {
      Expect.isTrue(it.moveNext());
      Expect.equals(it.current, v);
    });
    Expect.isFalse(it.moveNext());

    if (elements is List<int> && list is List<int>) {
      success("String.fromCharCodes", (l) => new String.fromCharCodes(l));
    }
  }
}

createConstList(n) {
  if (n == 0) return const <int>[];
  return const <int>[1, 2, 3];
}

createFixedList(n) {
  var result = new List<int>(n);
  for (int i = 0; i < n; i++) result[i] = n;
  return result;
}

createGrowableList(n) {
  var result = new List<int>()..length = n;
  for (int i = 0; i < n; i++) result[i] = n;
  return result;
}

createIterable(n) => new Iterable.generate(n);
createConstMapKeys(n) {
  if (n == 0) return const <int, int>{}.keys;
  return const <int, int>{0: 0, 1: 1, 2: 2}.keys;
}

createConstMapValues(n) {
  if (n == 0) return const <int, int>{}.values;
  return const <int, int>{0: 0, 1: 1, 2: 2}.values;
}

createMapKeys(n) {
  var map = <int, int>{};
  for (int i = 0; i < n; i++) map[i] = i;
  return map.keys;
}

createMapValues(n) {
  var map = <int, int>{};
  for (int i = 0; i < n; i++) map[i] = i;
  return map.values;
}

createSplayMapKeys(n) {
  var map = new SplayTreeMap<int, int>();
  for (int i = 0; i < n; i++) map[i] = i;
  return map.keys;
}

createSplayMapValues(n) {
  var map = new SplayTreeMap<int, int>();
  for (int i = 0; i < n; i++) map[i] = i;
  return map.values;
}

createSet(n) {
  var set = new Set<int>();
  for (int i = 0; i < n; i++) set.add(i);
  return set;
}

createSplaySet(n) {
  var set = new SplayTreeSet<int>();
  for (int i = 0; i < n; i++) set.add(i);
  return set;
}

createQueue(n) {
  var queue = new Queue<int>();
  for (int i = 0; i < n; i++) queue.add(i);
  return queue;
}

createListMapKeys(n) {
  return createGrowableList(n).asMap().keys;
}

createListMapValues(n) {
  return createGrowableList(n).asMap().values;
}

createCodeUnits(n) {
  var string = new String.fromCharCodes(new Iterable.generate(n));
  return string.codeUnits;
}

createTypedList(n) {
  var tl = new Uint8List(n);
  for (int i = 0; i < n; i++) tl[i] = i;
  return tl;
}
