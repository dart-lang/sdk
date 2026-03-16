// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  SomeClass.staticPositional();
}

class SomeClass {
  @RecordUse()
  static int staticPositional([int i = 12]) => i;
}
