// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension SafeAccess<T> on Iterable<T> {
  T get safeFirst {
    return isNotEmpty ? first : null;
  }
}

main() {}

void test() {
  final list = [];
  list.safeFirst();
  final list2 = <void Function(int)>[];
  list2.safeFirst(0);
}

void errors() {
  final list = <Object>[];
  list.safeFirst();
  final list2 = <void Function(int)>[];
  list2.safeFirst();
}
