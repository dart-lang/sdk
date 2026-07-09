// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/dart-lang/sdk/issues/54855
// The VM should not confuse these for the actual VM isolate, etc.

import "dart:isolate";

child(_) {
  new RawReceivePort(); // Keep alive.
}

main() {
  Isolate.spawn(child, null, debugName: "vm-isolate");
  Isolate.spawn(child, null, debugName: "vm-service");
  Isolate.spawn(child, null, debugName: "kernel-service");
}
