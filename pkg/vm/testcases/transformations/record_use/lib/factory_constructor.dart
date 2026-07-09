// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

@RecordUse()
final class FactoryA {
  final int i;
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  FactoryA(this.i);

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  // Factories are treated like static methods. The call in the body of the
  // factory is treated like a normal constructor call with most likely
  // non-constant arguments.
  factory FactoryA.fact(int i) => FactoryA(i);
}

void main() {
  final i = int.parse('42');
  final a = FactoryA.fact(i); // Call to factory
  print(a.i);
}
