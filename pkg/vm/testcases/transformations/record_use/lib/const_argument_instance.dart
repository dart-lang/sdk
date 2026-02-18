// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(someStaticMethod2(const SomeClass(14)));
}

@RecordUse()
int someStaticMethod2(SomeClass someClass) {
  return someClass.i + 1;
}

class SomeClass {
  final int i;

  const SomeClass(this.i);
}
