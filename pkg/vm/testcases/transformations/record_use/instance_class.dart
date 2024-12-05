// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(A());
}

@MyClass(42)
class A {}

@RecordUse()
class MyClass {
  final int i;

  const MyClass(this.i);
}
