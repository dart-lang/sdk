// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  // 1. Record used as a constant argument.
  doSomething(const (1, name: 'foo'));

  // 2. Record containing a recorded instance.
  doSomething(const (MyClass(10), val: MyClass(20)));
}

@RecordUse()
void doSomething(Object? o) {
  print(o);
}

@RecordUse()
final class MyClass {
  final int value;
  const MyClass(this.value);
}
