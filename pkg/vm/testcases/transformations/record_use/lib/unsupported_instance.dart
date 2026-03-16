// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  recorded(const MyClass(someStaticMethod));
}

void someStaticMethod() {}

@RecordUse()
final class MyClass {
  final Object field;
  const MyClass(this.field);
}

@RecordUse()
void recorded(Object arg) {}
