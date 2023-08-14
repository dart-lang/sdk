// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/47509.

void main() {
  List list1 = [1, 2, 3];
  print(list1);

  List list2 = const [1, 2, 3];
  print(list2);

  List list3 = List.from(list1, growable: false);
  print(list3);

  List list4 = List.from(list2, growable: false);
  print(list4);

  List list5 = list1.toList(growable: false);
  print(list5);

  List list6 = list2.toList(growable: false);
  print(list6);

  List list7 = List.from(list1);
  print(list7);

  List list8 = List.from(list2);
  print(list8);

  List list9 = list1.toList();
  print(list9);

  List list10 = list2.toList();
  print(list10);
}
