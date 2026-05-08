// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

@RecordUse()
final class C {
  final int i;
  C.a(int i) : this.b(i);
  C.b(this.i);
}

void main() {
  final c = C.a(42);
  print(c.i);
}
