// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  List<int> list1 = <int>[1, 2, 3];
  List<int> list2 = const <int>[4, 4];
  List<String> list3 = <String>[];
  Set<int> set1 = new Set<int>();
  set1..add(11)..add(12)..add(13);
  Set<String> set2 = new Set<String>();
  set2..add("foo")..add("bar")..add("toto");
  Set set3 = new Set();

  var setCopy = list1.toSet();
  Expect.equals(3, setCopy.length);
  Expect.isTrue(setCopy.contains(1));
  Expect.isTrue(setCopy.contains(2));
  Expect.isTrue(setCopy.contains(3));
  Expect.isTrue(setCopy is Set<int>);
  Expect.isFalse(setCopy is Set<String>);

  setCopy = list2.toSet();
  Expect.equals(1, setCopy.length);
  Expect.isTrue(setCopy.contains(4));
  Expect.isTrue(setCopy is Set<int>);
  Expect.isFalse(setCopy is Set<String>);

  var setStrCopy = list3.toSet();
  Expect.isTrue(setStrCopy.isEmpty);
  Expect.isTrue(setStrCopy is Set<String>);
  Expect.isFalse(setStrCopy is Set<int>);

  setCopy = set1.toSet();
  Expect.setEquals(set1, setCopy);
  Expect.isTrue(setCopy is Set<int>);
  Expect.isFalse(setCopy is Set<String>);
  Expect.isFalse(identical(setCopy, set1));

  setStrCopy = set2.toSet();
  Expect.setEquals(set2, setStrCopy);
  Expect.isTrue(setStrCopy is Set<String>);
  Expect.isFalse(setStrCopy is Set<int>);
  Expect.isFalse(identical(setStrCopy, set2));

  var set3Copy = set3.toSet();
  Expect.setEquals(set3, set3Copy);
  Expect.isTrue(set3Copy is Set);
  Expect.isFalse(set3Copy is Set<String>);
  Expect.isFalse(set3Copy is Set<int>);
  Expect.isFalse(identical(set3Copy, set3));
}
