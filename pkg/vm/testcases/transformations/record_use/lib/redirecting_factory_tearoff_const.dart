// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

class Redirector {
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  @pragma('wasm:never-inline')
  const factory Redirector(int i) = HasInstances;
}

@RecordUse()
final class HasInstances implements Redirector {
  final int i;
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  @pragma('wasm:never-inline')
  const HasInstances(this.i);
}

void main() {
  const f = Redirector.new; // Constant tear-off of redirecting factory
  print(f(42));
}
