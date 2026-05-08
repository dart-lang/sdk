// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

enum MyEnum {
  a;

  @RecordUse()
  static void staticMethod() {}
}

mixin MyMixin {
  @RecordUse()
  static void staticMethod() {}
}

void main() {
  final f1 = [MyEnum.staticMethod][0];
  print(f1);
  final f2 = [MyMixin.staticMethod][0];
  print(f2);
}
