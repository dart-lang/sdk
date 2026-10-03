// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../worker_harness.dart';

void main() {
  testFlutterWorker('worker.version()', (worker) async {
    final version = await worker.version();
    check(version.workerProtocolMajor).equals(1);
    check(version.workerProtocolMinor).equals(0);
    check(version.modes).deepEquals(['console', 'flutter']);
    check(version.dartVersion).isNotEmpty;
    // Note: version.dartRevision may be empty in testing (RBE builds).
    check(version.properties['flutterVersion']).isNotNull().isNotEmpty;
    check(version.properties['flutterRevision']).isNotNull().isNotEmpty;
    check(version.properties['engineRevision']).isNotNull().isNotEmpty;
  });
}
