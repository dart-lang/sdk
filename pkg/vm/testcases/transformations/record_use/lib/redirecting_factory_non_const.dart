// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

class A {
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  factory A(int i) = B;
}

@RecordUse()
final class B implements A {
  final int i;
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  B(this.i);
}

void main() {
  final a = A(42); // Non-const call to redirecting factory
  print(a);
}
