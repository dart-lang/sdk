// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

@RecordUse()
final class C<T, U> {
  final T t;
  final U u;
  C(this.t, this.u);
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  factory C.f(T t, U u) = C<T, U>;
}

void main() {
  final tc = C<String, int>.f('hello', 42);
  print(tc.t);
  print(tc.u);
}
