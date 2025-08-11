// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(SomeClass.someStaticMethod(5, 3));
  print(SomeClass.someStaticMethod(6));
}

class SomeClass {
  @RecordUse()
  static someStaticMethod(int k, [int i = 4]) {
    return i + 1;
  }
}
