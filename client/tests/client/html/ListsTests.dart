// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


void testLists() {
  group('setRange', () {
    test('one element', () {
      var list = ["A", "B", "C"];
      Lists.setRange(list, 1, 1, ["D"], 0);
      Expect.listEquals(["A", "D", "C"], list);
    });

    test('several elements', () {
      var list = ["A", "B", "C"];
      Lists.setRange(list, 1, 2, ["D", "E"], 0);
      Expect.listEquals(["A", "D", "E"], list);
    });

    test('fewer than all source elements', () {
      var list = ["A", "B", "C"];
      Lists.setRange(list, 1, 1, ["D", "E"], 0);
      Expect.listEquals(["A", "D", "C"], list);
    });

    test('startFrom', () {
      var list = ["A", "B", "C"];
      Lists.setRange(list, 1, 1, ["D", "E"], 1);
      Expect.listEquals(["A", "E", "C"], list);
    });

    test('negative length', () {
      var list = ["A", "B", "C"];
      Expect.throws(
          () => Lists.setRange(list, 1, -1, ["D"], 0),
          (e) => e is IllegalArgumentException);
    });

    test('off the end of dest', () {
      var list = ["A", "B", "C"];
      Expect.throws(() {
        Lists.setRange(list, 2, 2, ["D", "E"], 0);
      }, (e) => e is IndexOutOfRangeException);
    });

    test('off the beginning of dest', () {
      var list = ["A", "B", "C"];
      Expect.throws(
          () => Lists.setRange(list, -1, 1, ["D"], 0),
          (e) => e is IndexOutOfRangeException);
    });

    test('off the end of source', () {
      var list = ["A", "B", "C"];
      Expect.throws(
          () => Lists.setRange(list, 1, 2, ["D"], 0),
          (e) => e is IndexOutOfRangeException);
    });

    test('off the beginning of source', () {
      var list = ["A", "B", "C"];
      Expect.throws(
          () => Lists.setRange(list, 1, 1, ["D"], -1),
          (e) => e is IndexOutOfRangeException);
    });
  });

  group('removeRange', () {
    void removeRange(list, start, length) =>
      Lists.removeRange(list, start, length, (i) => list.removeRange(i, 1));

    test('one element', () {
      var list = ["A", "B", "C"];
      removeRange(list, 1, 1);
      Expect.listEquals(["A", "C"], list);
    });

    test('two elements', () {
      var list = ["A", "B", "C"];
      removeRange(list, 1, 2);
      Expect.listEquals(["A"], list);
    });

    test('all elements', () {
      var list = ["A", "B", "C"];
      removeRange(list, 0, 3);
      Expect.isTrue(list.isEmpty());
    });

    test('negative length', () {
      var list = ["A", "B", "C"];
      Expect.throws(
          () => removeRange(list, 2, -1),
          (e) => e is IllegalArgumentException);
    });

    test('off the end', () {
      var list = ["A", "B", "C"];
      Expect.throws(
          () => removeRange(list, 2, 3),
          (e) => e is IndexOutOfRangeException);
    });

    test('off the beginning', () {
      var list = ["A", "B", "C"];
      Expect.throws(
          () => removeRange(list, -1, 1),
          (e) => e is IndexOutOfRangeException);
    });
  });

  group('getRange', () {
    test('one element', () {
      Expect.listEquals(["C"], Lists.getRange(["A", "B", "C"], 2, 1));
    });

    test('two elements', () {
      Expect.listEquals(["B", "C"], Lists.getRange(["A", "B", "C"], 1, 2));
    });

    test('negative length', () {
      Expect.throws(
          () => Lists.getRange(["A", "B", "C"], 2, -1),
          (e) => e is IllegalArgumentException);
    });

    test('off the end', () {
      Expect.throws(
          () => Lists.getRange(["A", "B", "C"], 2, 2),
          (e) => e is IndexOutOfRangeException);
    });

    test('off the beginning', () {
      Expect.throws(
          () => Lists.getRange(["A", "B", "C"], -1, 2),
          (e) => e is IndexOutOfRangeException);
    });
  });

  test('indexOf', () {
    var list = ["A", "B", "C"];
    Expect.equals(0, Lists.indexOf(list, "A", 0, list.length));
    Expect.equals(1, Lists.indexOf(list, "B", 0, list.length));
    Expect.equals(2, Lists.indexOf(list, "C", 0, list.length));
    Expect.equals(-1, Lists.indexOf(list, "D", 0, list.length));
    Expect.equals(1, Lists.indexOf(list, "B", 1, list.length));
    Expect.equals(-1, Lists.indexOf(list, "B", 2, list.length));
  });

  test('lastIndexOf', () {
    var list = ["A", "B", "C"];
    Expect.equals(0, Lists.lastIndexOf(list, "A", list.length - 1));
    Expect.equals(1, Lists.lastIndexOf(list, "B", list.length - 1));
    Expect.equals(2, Lists.lastIndexOf(list, "C", list.length - 1));
    Expect.equals(-1, Lists.lastIndexOf(list, "D", list.length - 1));
    Expect.equals(1, Lists.lastIndexOf(list, "B", 1));
    Expect.equals(-1, Lists.lastIndexOf(list, "E", 0));
  });
}
