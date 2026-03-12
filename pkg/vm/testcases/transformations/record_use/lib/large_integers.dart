// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  // Max signed 64-bit int
  print(SomeClass.someStaticMethod(0x7FFFFFFFFFFFFFFF));

  // Min signed 64-bit int
  print(SomeClass.someStaticMethod(0x8000000000000000));

  // Some other large values
  print(SomeClass.someStaticMethod(0x1234567890ABCDEF));
  print(SomeClass.someStaticMethod(0xFEDCBA0987654321));

  // Bit pattern of all ones
  print(SomeClass.someStaticMethod(0xFFFFFFFFFFFFFFFF));

  // Values near the limits
  print(SomeClass.someStaticMethod(0x7FFFFFFFFFFFFFFE));
  print(SomeClass.someStaticMethod(0x8000000000000001));

  // Large values that are definitely positive
  print(SomeClass.someStaticMethod(0x1000000000000000));
  print(SomeClass.someStaticMethod(0x2000000000000000));
  print(SomeClass.someStaticMethod(0x4000000000000000));

  // Bit patterns
  print(SomeClass.someStaticMethod(0xAAAAAAAAAAAAAAAA));
  print(SomeClass.someStaticMethod(0x5555555555555555));
}

class SomeClass {
  @RecordUse()
  static String someStaticMethod(int i) => i.toString();
}
