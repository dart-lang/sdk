// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.compile_platform_test;

import 'dart:async';

import 'dart:io';

import 'package:async_helper/async_helper.dart';

import 'package:expect/expect.dart';

import 'compile_platform.dart' show compilePlatform;

main(List<String> arguments) {
  asyncTest(() async {
    await withTemporaryDirectory("compile_platform_test_", (Uri tmp) async {
      String librariesJson = Uri.base
          .resolveUri(new Uri.file(Platform.resolvedExecutable))
          .resolve("patched_sdk/lib/libraries.json")
          .toFilePath();
      // This first invocation should succeed.
      await compilePlatform(<String>[
        "-v",
        "dart:core",
        librariesJson,
        tmp.resolve("vm_platform.dill").toFilePath(),
        tmp.resolve("vm_outline.dill").toFilePath(),
      ]);
      print("Successfully compiled $librariesJson.\n\n");

      try {
        // This invocation is expected to throw an exception for now. Patching
        // isn't fully implemented yet.
        //
        // TODO(ahe): When this stops crashing, use Process to invoke the tool
        // instead of importing its main entry point.
        await compilePlatform(<String>[
          "-v",
          "dart:core",
          "sdk/lib/libraries.json",
          tmp.resolve("vm_platform.dill").toFilePath(),
          tmp.resolve("vm_outline.dill").toFilePath(),
        ]);
      } on String catch (e) {
        Expect.isTrue(
            e.startsWith("Class '_InvocationMirror' not found in library "));
        print("Failed as expected: $e");
        exitCode = 0;
        return;
      }
      Expect.fail("Test didn't throw expected exception.");
    });
  });
}

withTemporaryDirectory(String prefix, Future f(Uri tmp)) async {
  Directory tmp = await Directory.systemTemp.createTemp(prefix);
  try {
    await f(tmp.uri);
  } finally {
    await tmp.delete(recursive: true);
  }
}
