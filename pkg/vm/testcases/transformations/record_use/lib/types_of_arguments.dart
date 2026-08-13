// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(SomeClass.someStaticMethod(42));
  print(SomeClass.someStaticMethod(null));
  print(SomeClass.someStaticMethod('s'));
  print(SomeClass.someStaticMethod(true));
  print(
    SomeClass.someStaticMethod(const {
      'a': ['a1', 'a2'],
      'b': ['b1', 'b2'],
    }),
  );

  print(SomeClass.someStaticMethod([true, false].first));
}

class SomeClass {
  @RecordUse()
  static String someStaticMethod(Object? a) => a.runtimeType.toString();
}
