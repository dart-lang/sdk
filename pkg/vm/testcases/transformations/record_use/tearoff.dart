// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(m(SomeClass.someStaticMethod)(42));
}

// Prevent the tearoff becoming a static call.
@pragma('dart2js:never-inline')
Function m(Function f) => f;

class SomeClass {
  @RecordUse()
  static int someStaticMethod(int i) {
    return i + 1;
  }
}
