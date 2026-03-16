// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(const SomeClass.positional());
  print(SomeClass.positional());
}

@RecordUse()
final class SomeClass {
  final int i;
  const SomeClass.positional([this.i = 11]);
}
