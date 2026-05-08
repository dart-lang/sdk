// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

const zero = 0.0;
const maxFinite = 1.7976931348623157e+308;
const minusMaxFinite = -maxFinite;

void main() {
  print(SomeClass.someStaticMethod(zero));
  print(SomeClass.someStaticMethod(maxFinite));
  print(SomeClass.someStaticMethod(minusMaxFinite));
}

class SomeClass {
  @RecordUse()
  static String someStaticMethod(double d) => d.toString();
}
