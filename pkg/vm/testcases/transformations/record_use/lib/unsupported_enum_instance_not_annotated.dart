// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  recorded(A.a);

  // To make record use expectation files be the same across backends, we ensure
  // to keep the `Enum.index` field alive.
  keepIndexFieldAlive(A.a);
  keepIndexFieldAlive(A.b);
}

@RecordUse()
void recorded(A a) {
  print(a.name);
}

void keepIndexFieldAlive(Enum e) {
  print(e.index);
}

enum A { a, b }
