// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(SomeClass.someStaticMethod(42));
  print(SomeClass.someStaticMethod2(99));
  print(someTopLevelMethod(11));
}

class SomeClass {
  @pragma('dart2js:resource-identifier')
  @pragma('dart2js:noInline')
  static int someStaticMethod(int i) {
    return i + 1;
  }

  @RecordUse()
  static int someStaticMethod2(int i) {
    return i + 1;
  }
}

@pragma('dart2js:resource-identifier')
@pragma('dart2js:noInline')
int someTopLevelMethod(int i) {
  return i + 1;
}
