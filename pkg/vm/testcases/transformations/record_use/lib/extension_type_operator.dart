// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

extension type const ET(int i) {
  @RecordUse()
  int operator +(int other) => i + other;
}

void main() {
  final et = ET(42);
  print(et + 1);
}
