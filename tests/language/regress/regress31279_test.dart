// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {
  void update(void Function(Iterable) updates);
  void update2(void updates(Iterable iterable));
}

class CovariantParsingIssue implements Base {
  void update(covariant void Function(List) updates) {}
  void update2(covariant void updates(List list)) {}
}

void VoidParsingIssue() {
  List<void Function(int)> functions = [(int i) => print(i + 1)];
  functions[0](42);
}

void main() {
  new CovariantParsingIssue();
  VoidParsingIssue();
}
