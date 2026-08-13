// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

@RecordUse()
final class C {
  final int i;
  C.named(this.i);
  factory C.fact(int i) => C.named(i);
}

void main() {
  final c1 = C.named(42);
  final f1 = [C.named][0];
  print(c1);
  print(f1(43));

  final c2 = C.fact(44);
  final f2 = [C.fact][0];
  print(c2);
  print(f2(45));
}
