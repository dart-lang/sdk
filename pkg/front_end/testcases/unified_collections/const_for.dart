// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  const List<int> list1 = const [for (var i = 1; i < 4; i++) i];
  const List<int> list2 = const [for (int i in list1) i];
  const Set<int> set1 = const {for (var i = 1; i < 4; i++) i};
  const Set<int> set2 = const {for (int i in set1) i};
}
