// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

@RecordUse()
final class MyClass {
  final int i;

  const MyClass(this.i);

  @override
  String toString() {
    return 'My $i';
  }
}

final class WrapperClass {
  final MyClass nested;

  const WrapperClass(this.nested);

  @override
  String toString() {
    return 'Use nested: $nested';
  }
}
