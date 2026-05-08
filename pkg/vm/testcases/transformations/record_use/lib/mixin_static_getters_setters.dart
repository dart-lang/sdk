// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

mixin MyMixin {
  @RecordUse()
  static int get staticGetter => 42;

  @RecordUse()
  static set staticSetter(int value) {}
}

void main() {
  print(MyMixin.staticGetter);
  MyMixin.staticSetter = 123;
}
