// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:expect/expect.dart';

import 'reload_utils.dart';
import 'reload_no_active_stack_test.dart' show dartTestFile;

const N = 250;

main() async {
  if (!currentVmSupportsReload) return;

  await withTempDir((String tempDir) async {
    final dills = await generateDills(tempDir, dartTestFile(N));
    final reloader = await launchOn(dills[0]);

    await reloader.waitUntilStdoutContainsN('entering ready loop', N);

    final reloadResult1 = await reloader.reload(dills[1]);
    Expect.equals('ReloadReport', reloadResult1['type']);
    Expect.equals(true, reloadResult1['success']);

    await reloader.waitUntilStdoutContainsN('entering done loop', N);

    final reloadResult2 = await reloader.reload(dills[2]);
    Expect.equals('ReloadReport', reloadResult2['type']);
    Expect.equals(true, reloadResult2['success']);

    final int exitCode = await reloader.close();
    Expect.equals(0, exitCode);
  });
}
