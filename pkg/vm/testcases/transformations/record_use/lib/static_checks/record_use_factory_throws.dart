// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

final class SomeClass {
  SomeClass._();

  @RecordUse()
  factory SomeClass.fact() => SomeClass._();
}

void main() {
  print(SomeClass.fact());
}
