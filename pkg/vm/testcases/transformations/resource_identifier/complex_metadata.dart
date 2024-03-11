// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show ResourceIdentifier;

void main() {
  print(SomeClass.stringMetadata(42));
  print(SomeClass.doubleMetadata(42));
  print(SomeClass.intMetadata(42));
  print(SomeClass.boolMetadata(42));
}

class SomeClass {
  @ResourceIdentifier('leroyjenkins')
  static stringMetadata(int i) {
    return i + 1;
  }

  @ResourceIdentifier(3.14)
  static doubleMetadata(int i) {
    return i + 1;
  }

  @ResourceIdentifier(42)
  static intMetadata(int i) {
    return i + 1;
  }

  @ResourceIdentifier(true)
  static boolMetadata(int i) {
    return i + 1;
  }
}
