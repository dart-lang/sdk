// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:path/path.dart" as p;

import "snapshot_test_helper.dart";

int fib(int n) {
  if (n <= 1) return 1;
  return fib(n - 1) + fib(n - 2);
}

Future<void> main(List<String> args) async {
  if (args.contains("--child")) {
    print(fib(35));
    return;
  }

  if (!Platform.script.toString().endsWith(".dart")) {
    print("This test must run from source");
    return;
  }

  await withTempDir((String tmp) async {
    final String coreVMDataPath = p.join(tmp, "core_vm_snapshot_data.bin");
    final String coreIsoDataPath =
        p.join(tmp, "core_isolate_snapshot_data.bin");
    final String baselineIsoDataPath =
        p.join(tmp, "baseline_isolate_snapshot_data.bin");
    final String baselineIsoInstrPath =
        p.join(tmp, "baseline_isolate_snapshot_instructions.bin");
    final String patchIsoDataPath =
        p.join(tmp, "patch_isolate_snapshot_data.bin");
    final String patchIsoInstrPath =
        p.join(tmp, "patch_isolate_snapshot_instr.bin");
    final String kernelPath = p.join(tmp, "app.dill");
    final String tracePath = p.join(tmp, "compilation_trace.txt");

    // We don't support snapshot with code on IA32.
    final String appSnapshotKind =
        Platform.version.contains("ia32") ? "app" : "app-jit";

    final result1 = await runGenKernel("generate kernel", [
      Platform.script.toFilePath(),
      "--output",
      kernelPath,
    ]);
    expectOutput("", result1);

    final result2 = await runDart("generate compilation trace", [
      "--save_compilation_trace=$tracePath",
      kernelPath,
      "--child",
    ]);
    expectOutput("14930352", result2);

    final result3 = await runGenSnapshot("generate core snapshot", [
      "--snapshot_kind=core",
      "--vm_snapshot_data=${coreVMDataPath}",
      "--isolate_snapshot_data=${coreIsoDataPath}",
      platformDill,
    ]);
    expectOutput("", result3);

    final result4 = await runGenSnapshot("generate baseline app snapshot", [
      "--snapshot_kind=${appSnapshotKind}",
      "--load_vm_snapshot_data=${coreVMDataPath}",
      "--load_isolate_snapshot_data=${coreIsoDataPath}",
      "--isolate_snapshot_data=${baselineIsoDataPath}",
      "--isolate_snapshot_instructions=${baselineIsoInstrPath}",
      "--load_compilation_trace=$tracePath",
      kernelPath,
    ]);
    expectOutput("", result4);

    final result5 = await runGenSnapshot("generate patch app snapshot", [
      "--snapshot_kind=${appSnapshotKind}",
      "--load_vm_snapshot_data=${coreVMDataPath}",
      "--load_isolate_snapshot_data=${coreIsoDataPath}",
      "--isolate_snapshot_data=${patchIsoDataPath}",
      "--isolate_snapshot_instructions=${patchIsoInstrPath}",
      "--reused_instructions=${baselineIsoInstrPath}",
      "--load_compilation_trace=$tracePath",
      kernelPath,
    ]);
    expectOutput("", result5);
  });
}
