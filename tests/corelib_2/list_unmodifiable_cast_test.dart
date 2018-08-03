// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library list_unmodifiable_cast_test;

import "package:expect/expect.dart";
import 'dart:collection';

void main() {
  test(const [37]);
  test(new UnmodifiableListView([37]));

  test(new UnmodifiableListView<num>(<num>[37]));
  test(new UnmodifiableListView<num>(<int>[37]));

  test(new UnmodifiableListView<num>(<num>[37]).cast<int>());
  test(new UnmodifiableListView<num>(<int>[37]).cast<int>());
  test(new UnmodifiableListView<Object>(<num>[37]).cast<int>());
  test(new UnmodifiableListView<Object>(<int>[37]).cast<num>());

  var m2 = new List<num>.unmodifiable([37]);
  test(m2);
  test(m2.cast<int>());
}

void test(List list) {
  Expect.equals(1, list.length);
  Expect.equals(37, list.first);

  Expect.throws(list.clear);
  Expect.throws(() {
    list.remove(37);
  });
  Expect.throws(() {
    list[0] = 42;
  });
  Expect.throws(() {
    list.addAll(<int>[42]);
  });
}
