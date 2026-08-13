// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

@RecordUse()
final class C {
  final int i;
  C.a(int x) : this.b(x + 1);
  C.b(this.i);
}

void main() {
  // We expect to record a call to C.a with argument 5.
  // We do NOT expect to see a call to C.b with 6.
  final c = C.a(5);
  print(c.i);
}
