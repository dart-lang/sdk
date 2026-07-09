// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(const MyClass(const A()));
}

@RecordUse()
final class MyClass {
  final A a;

  const MyClass(this.a);
}

@RecordUse()
final class A {
  const A();
}
