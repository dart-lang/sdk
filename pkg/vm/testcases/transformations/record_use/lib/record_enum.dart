// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(const MyClass(A.a));

  // To make record use expectation files be the same across backends, we ensure
  // to keep the `Enum.index` field alive. If we don't do this then the VM's AOT
  // and dart2wasm will tree shake differently (e.g. due to different platform
  // file) and produce different record use information, no longer allowing the
  // same expectation file across backends.
  keepIndexFieldAlive(A.a);
  keepIndexFieldAlive(A.b);
}

@RecordUse()
final class MyClass {
  final A a;

  const MyClass(this.a);
}

void keepIndexFieldAlive(Enum e) {
  print(e.index);
}

enum A { a, b }
