// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.compile_platform_test;

import 'dart:async';

import 'dart:io';

import 'package:async_helper/async_helper.dart';

import 'package:expect/expect.dart';

main(List<String> arguments) {
  Uri dartVm = Uri.base.resolveUri(new Uri.file(Platform.resolvedExecutable));
  Uri librariesJson = Uri.base.resolve("sdk/lib/libraries.json");
  Uri compilePlatform =
      Uri.base.resolve("pkg/front_end/tool/_fasta/compile_platform.dart");
  asyncTest(() async {
    await withTemporaryDirectory("compile_platform_test_", (Uri tmp) async {
      Uri platformDill = tmp.resolve("vm_platform.dill");
      Uri outlineDill = tmp.resolve("vm_outline.dill");
      ProcessResult result = await Process.run(dartVm.toFilePath(), <String>[
        compilePlatform.toFilePath(),
        "-v",
        "dart:core",
        librariesJson.toFilePath(),
        platformDill.toFilePath(),
        outlineDill.toFilePath(),
      ]);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      Expect.equals(
          0, result.exitCode, "Non-zero exitcode from compile_platform.dart");
      Expect.isTrue(await new File.fromUri(platformDill).exists());
      Expect.isTrue(await new File.fromUri(outlineDill).exists());
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
