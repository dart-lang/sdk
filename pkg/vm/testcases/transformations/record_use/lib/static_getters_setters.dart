// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

class SomeClass {
  @RecordUse()
  static int get someStaticGetter => 42;

  @RecordUse()
  static set someStaticSetter(int value) {}
}

@RecordUse()
int get someTopLevelGetter => 42;

@RecordUse()
set someTopLevelSetter(int value) {}

void main() {
  print(SomeClass.someStaticGetter);
  SomeClass.someStaticSetter = 123;
  print(someTopLevelGetter);
  someTopLevelSetter = 456;
}
