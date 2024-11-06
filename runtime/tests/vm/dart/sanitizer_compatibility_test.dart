// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check for a proper error when a snapshot and a runtime don't agree on which
// sanitizer they are using.

import "dart:io";

import "package:expect/expect.dart";

import "use_flag_test_helper.dart";

String find(String haystack, List<String> needles) {
  for (String needle in needles) {
    if (haystack.contains(needle)) {
      return needle;
    }
  }
  throw "None of ${needles.join(' ')}";
}

void checkExists(String path) {
  if (!File(path).existsSync()) {
    throw "$path does not exist";
  }
}

main() async {
  var sanitizer = find(Platform.executable, ["MSAN", "TSAN"]);
  var mode = find(Platform.executable, ["Debug", "Release", "Product"]);
  var arch = find(Platform.executable, ["X64", "ARM64", "RISCV64"]);
  var out = find(Platform.executable, ["out", "xcodebuild"]);
  var targetFlag = {
    "MSAN": "--target_memory_sanitizer",
    "TSAN": "--target_thread_sanitizer"
  }[sanitizer]!;

  var nonePlatform = "$out/$mode$arch/vm_platform_strong.dill";
  var noneGenSnapshot = "$out/$mode$arch/gen_snapshot";
  var noneJitRuntime = "$out/$mode$arch/dart";
  var noneAotRuntime = "$out/$mode$arch/dart_precompiled_runtime";
  var sanitizerGenSnapshot = "$out/$mode$sanitizer$arch/gen_snapshot";
  var sanitizerAotRuntime =
      "$out/$mode$sanitizer$arch/dart_precompiled_runtime";

  checkExists(noneGenSnapshot);
  checkExists(noneJitRuntime);
  checkExists(noneAotRuntime);
  checkExists(sanitizerGenSnapshot);
  checkExists(sanitizerAotRuntime);

  await withTempDir('sanitizer-compatibility-test', (String tempDir) async {
    var aotDill = "$tempDir/aot.dill";
    var noneElf = "$tempDir/none.elf";
    var sanitizerElf = "$tempDir/$sanitizer.elf";
    var sanitizerElf2 = "$tempDir/${sanitizer}2.elf";

    await run(noneJitRuntime, [
      "pkg/vm/bin/gen_kernel.dart",
      "--platform",
      nonePlatform,
      "--aot",
      "-o",
      aotDill,
      "tests/language/unsorted/first_test.dart"
    ]);

    await run(noneGenSnapshot,
        ["--snapshot-kind=app-aot-elf", "--elf=$noneElf", aotDill]);
    await run(sanitizerGenSnapshot,
        ["--snapshot-kind=app-aot-elf", "--elf=$sanitizerElf", aotDill]);
    await run(noneGenSnapshot, [
      "--snapshot-kind=app-aot-elf",
      "--elf=$sanitizerElf2",
      targetFlag,
      aotDill
    ]);

    await run(noneAotRuntime, [noneElf]);
    await run(sanitizerAotRuntime, [sanitizerElf]);
    await run(sanitizerAotRuntime, [sanitizerElf2]);

    var errorLines = await runError(noneAotRuntime, [sanitizerElf]);
    Expect.contains("Snapshot not compatible", errorLines[0]);
    errorLines = await runError(noneAotRuntime, [sanitizerElf2]);
    Expect.contains("Snapshot not compatible", errorLines[0]);
    errorLines = await runError(sanitizerAotRuntime, [noneElf]);
    Expect.contains("Snapshot not compatible", errorLines[0]);
  });
}
