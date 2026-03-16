// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

enum MyEnum {
  a(1);

  final int value;
  const MyEnum(this.value);

  @RecordUse()
  factory MyEnum.fromValue(int value) {
    return MyEnum.values.firstWhere((e) => e.value == value);
  }
}

void main() {
  print(MyEnum.fromValue(1));
}
