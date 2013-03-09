// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  List<int> list1 = <int>[1, 2, 3];
  List<int> list2 = const <int>[4, 5];
  List<String> list3 = <String>[];
  Set<int> set1 = new Set<int>();
  set1..add(11)
      ..add(12)
      ..add(13);
  Set<String> set2 = new Set<String>();
  set2..add("foo")
      ..add("bar")
      ..add("toto");
  Set set3 = new Set();

  var listCopy = list1.toList();
  Expect.listEquals(list1, listCopy);
  Expect.isTrue(listCopy is List<int>);
  Expect.isFalse(listCopy is List<String>);
  Expect.isFalse(identical(list1, listCopy));

  listCopy = list2.toList();
  Expect.listEquals(list2, listCopy);
  Expect.isTrue(listCopy is List<int>);
  Expect.isFalse(listCopy is List<String>);
  Expect.isFalse(identical(list2, listCopy));

  listCopy = list3.toList();
  Expect.listEquals(list3, listCopy);
  Expect.isTrue(listCopy is List<String>);
  Expect.isFalse(listCopy is List<int>);
  Expect.isFalse(identical(list3, listCopy));

  listCopy = set1.toList();
  Expect.equals(3, listCopy.length);
  Expect.isTrue(listCopy.contains(11));
  Expect.isTrue(listCopy.contains(12));
  Expect.isTrue(listCopy.contains(13));
  Expect.isTrue(listCopy is List<int>);
  Expect.isFalse(listCopy is List<String>);

  listCopy = set2.toList();
  Expect.equals(3, listCopy.length);
  Expect.isTrue(listCopy.contains("foo"));
  Expect.isTrue(listCopy.contains("bar"));
  Expect.isTrue(listCopy.contains("toto"));
  Expect.isTrue(listCopy is List<String>);
  Expect.isFalse(listCopy is List<int>);

  listCopy = set3.toList();
  Expect.isTrue(listCopy.isEmpty);
  Expect.isTrue(listCopy is List<int>);
  Expect.isTrue(listCopy is List<String>);
}
