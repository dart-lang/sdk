// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(SomeClass.someStaticMethod(const {1: 'int-key', true: 'bool-key'}));
}

class SomeClass {
  @RecordUse()
  static String someStaticMethod(Object? a) => a.runtimeType.toString();
}
