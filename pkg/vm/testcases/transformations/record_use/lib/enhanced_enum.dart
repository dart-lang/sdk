// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(const MyClass(A.a));
  print(const MyClass(A.b));

  // To make record use expectation files be the same across backends, we ensure
  // to keep the `Enum.index` field alive.
  keepIndexFieldAlive(A.a);
  keepIndexFieldAlive(A.b);
}

@RecordUse()
final class MyClass {
  final A a;

  const MyClass(this.a);
}

void keepIndexFieldAlive(Enum e) {
  print(e.index);
}

@RecordUse()
enum A {
  a(10),
  b(20);

  final int customField;
  const A(this.customField);
}
