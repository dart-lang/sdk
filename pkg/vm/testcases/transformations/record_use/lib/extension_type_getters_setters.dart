// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

extension type const ET(int i) {
  @RecordUse()
  static int get staticGetter => 42;

  @RecordUse()
  static set staticSetter(int value) {}

  @RecordUse()
  int get instanceGetter => i;

  @RecordUse()
  set instanceSetter(int value) {}
}

void main() {
  print(ET.staticGetter);
  ET.staticSetter = 123;
  final et = ET(42);
  print(et.instanceGetter);
  et.instanceSetter = 456;
}
