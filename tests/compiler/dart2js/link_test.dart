// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../lib/compiler/implementation/util/util.dart';
import '../../../lib/compiler/implementation/util/util_implementation.dart';

main() {
  test(const Link<Comparable>().prepend('three').prepend(2).prepend('one'),
       ['one', 2, 'three']);
  test(const Link<Comparable>().prepend(3).prepend('two').prepend(1),
       [1, 'two', 3]);
  test(const Link<String>().prepend('single'), ['single']);
  test(const Link(), []);
  testFromList([]);
  testFromList([0]);
  testFromList([0, 1]);
  testFromList([0, 1, 2]);
  testFromList([0, 1, 2, 3]);
  testFromList([0, 1, 2, 3, 4]);
  testFromList([0, 1, 2, 3, 4, 5]);
}

testFromList(List list) {
  test(new Link.fromList(list), list);
}

test(Link link, List list) {
  Expect.equals(list.isEmpty, link.isEmpty);
  int i = 0;
  for (var element in link.toList()) {
    Expect.equals(list[i++], element);
  }
  Expect.equals(list.length, i);
  i = 0;
  for (var element in link) {
    Expect.equals(list[i++], element);
  }
  Expect.equals(list.length, i);
  i = 0;
  for (; !link.isEmpty; link = link.tail) {
    Expect.equals(list[i++], link.head);
  }
  Expect.equals(list.length, i);
  Expect.isTrue(link.isEmpty);
}
