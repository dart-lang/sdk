// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";
import "dart:io";

import "package:expect/expect.dart";
import "package:path/path.dart" as path;

import "use_flag_test_helper.dart";

main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree not available on the test device.
  }

  // These are the tools we need to be available to run on a given platform:
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }
  if (!await testExecutable(genSnapshot)) {
    throw "Cannot run test as $genSnapshot not available";
  }

  await withTempDir("incompatible-loading-unit-test", (String tempDir) async {
    final source1 = path.join(
        sdkDir, "runtime/tests/vm/dart_2/incompatible_loading_unit_1.dart");
    final source2 = path.join(
        sdkDir, "runtime/tests/vm/dart_2/incompatible_loading_unit_2.dart");
    final dill1 = path.join(tempDir, "incompatible_loading_unit_1.dart.dill");
    final dill2 = path.join(tempDir, "incompatible_loading_unit_2.dart.dill");
    final snapshot1 = path.join(tempDir, "incompatible_loading_unit_1.so");
    final snapshot2 = path.join(tempDir, "incompatible_loading_unit_2.so");
    final manifest1 = path.join(tempDir, "incompatible_loading_unit_1.txt");
    final manifest2 = path.join(tempDir, "incompatible_loading_unit_2.txt");
    final deferredSnapshot1 = snapshot1 + "-2.part.so";
    final deferredSnapshot2 = snapshot2 + "-2.part.so";

    // Compile source to kernel.
    await run(genKernel, <String>[
      "--aot",
      "--platform=$platformDill",
      "-o",
      dill1,
      source1,
    ]);
    await run(genKernel, <String>[
      "--aot",
      "--platform=$platformDill",
      "-o",
      dill2,
      source2,
    ]);

    // Compile kernel to ELF.
    await run(genSnapshot, <String>[
      "--snapshot-kind=app-aot-elf",
      "--use-bare-instructions=false",
      "--elf=$snapshot1",
      "--loading-unit-manifest=$manifest1",
      dill1,
    ]);
    var manifest = jsonDecode(await new File(manifest1).readAsString());
    Expect.equals(2, manifest["loadingUnits"].length);
    Expect.isTrue(await new File(deferredSnapshot1).exists());

    await run(genSnapshot, <String>[
      "--snapshot-kind=app-aot-elf",
      "--use-bare-instructions=false",
      "--elf=$snapshot2",
      "--loading-unit-manifest=$manifest2",
      dill2,
    ]);
    manifest = jsonDecode(await new File(manifest1).readAsString());
    Expect.equals(2, manifest["loadingUnits"].length);
    Expect.isTrue(await new File(deferredSnapshot2).exists());

    // Works when used normally.
    var lines = await runOutput(aotRuntime, <String>[snapshot1]);
    Expect.listEquals(["One!"], lines);

    lines = await runOutput(aotRuntime, <String>[snapshot2]);
    Expect.listEquals(["Two!"], lines);

    // Fails gracefully when mixing snapshot parts.
    await new File(deferredSnapshot2).rename(deferredSnapshot1);
    lines = await runError(aotRuntime, <String>[snapshot1]);
    Expect.equals(
        "DeferredLoadException: 'Deferred loading unit is from a different program than the main loading unit'",
        lines[1]);
  });
}
