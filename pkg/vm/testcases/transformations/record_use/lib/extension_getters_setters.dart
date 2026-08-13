// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

extension Ext on String {
  @RecordUse()
  static int get staticGetter => 42;

  @RecordUse()
  static set staticSetter(int value) {}

  @RecordUse()
  int get instanceGetter => length;

  @RecordUse()
  set instanceSetter(int value) {}
}

void main() {
  print(Ext.staticGetter);
  Ext.staticSetter = 123;
  print('abc'.instanceGetter);
  'abc'.instanceSetter = 456;
}
