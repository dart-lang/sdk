// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherScripts=error_exit_at_spawning_shared.dart

library error_exit_at_spawnuri;

import "dart:isolate";

import 'error_exit_at_spawning_shared.dart';

main() {
  testIsolate((SendPort replyPort, SendPort errorPort, SendPort exitPort) {
    Isolate.spawnUri(
        Uri.parse("error_exit_at_spawning_shared.dart"), [], replyPort,
        // Setup handlers as part of spawn.
        errorsAreFatal: false,
        onError: errorPort,
        onExit: exitPort);
  });
}
