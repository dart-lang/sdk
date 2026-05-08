// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

class Redirector1 {
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  @pragma('wasm:never-inline')
  factory Redirector1(int i) = Redirector2;
}

class Redirector2 implements Redirector1 {
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  @pragma('wasm:never-inline')
  factory Redirector2(int i) = HasInstances;
}

@RecordUse()
final class HasInstances implements Redirector2 {
  final int i;
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  @pragma('wasm:never-inline')
  HasInstances(this.i);
}

void main() {
  final f = [Redirector1.new][0]; // Multi-level redirecting factory tear-off
  print(f(42));
}
