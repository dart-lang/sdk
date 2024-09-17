// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  print(SomeClass.someStaticMethod(42));
}

class SomeClass {
  @ResourceIdentifier('id')
  static someStaticMethod(int i) {
    return i + 1;
  }
}

class ResourceIdentifier {
  final Object? metadata;

  const ResourceIdentifier([this.metadata]);
}
