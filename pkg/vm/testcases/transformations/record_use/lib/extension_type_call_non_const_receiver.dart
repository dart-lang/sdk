// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

extension type const ET(int i) {
  @RecordUse()
  void foo(String s) {
    print('$i $s');
  }
}

void main() {
  final et = ET(42);
  et.foo('arg');
}
