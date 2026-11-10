// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:checks/checks.dart';
import 'package:dartpad_worker/src/tools/frontend_server_client.dart';
import 'package:test/test.dart';

void main() {
  test('quit() after frontend_server crashed', () async {
    final client = FrontendServerClient.start(MemoryResourceProvider(), [
      '--incremental',
    ]);

    // A `recompile` before the initial `compile` throws inside
    // `frontend_server`, which writes no output and never completes the future
    // returned by `starter()`, leaving the read for that output abandoned.
    await check(
      client.recompile('main.dart', [], restart: false),
    ).throws<Object>();

    // The abandoned read is still queued, so cancelling the line queue must not
    // wait behind it.
    await client.quit().timeout(const Duration(seconds: 10));
  });
}
