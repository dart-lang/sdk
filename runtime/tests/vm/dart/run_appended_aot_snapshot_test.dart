// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import 'dart:typed_data';

import "package:path/path.dart" as path;

import "snapshot_test_helper.dart";

final appSnapshotPageSize = 4096;
const appjitMagicNumber = <int>[0xdc, 0xdc, 0xf6, 0xf6, 0, 0, 0, 0];

Future writeAppendedExecutable(runtimePath, payloadPath, outputPath) async {
  final runtime = File(runtimePath);
  final int runtimeLength = runtime.lengthSync();

  final padding = (appSnapshotPageSize - (runtimeLength % appSnapshotPageSize));
  final padBytes = new List<int>.filled(padding, 0);
  final offset = runtimeLength + padding;

  final offsetBytes = new ByteData(8) // 64 bit in bytes.
    ..setUint64(0, offset, Endian.little);

  final outputFile = File(outputPath).openWrite();
  outputFile.add(runtime.readAsBytesSync());
  outputFile.add(padBytes);
  outputFile.add(File(payloadPath).readAsBytesSync());
  outputFile.add(offsetBytes.buffer.asUint8List());
  outputFile.add(appjitMagicNumber);
  await outputFile.close();
}

Future<void> main(List<String> args) async {
  if (args.length == 1 && args[0] == "--child") {
    print("Hello, Appended AOT");
    return;
  }

  await withTempDir((String tmp) async {
    final String dillPath = path.join(tmp, "test.dill");
    final String aotPath = path.join(tmp, "test.aot");
    final String exePath = path.join(tmp, "test.exe");

    final dillResult = await runGenKernel("generate dill", [
      "--aot",
      "-o",
      dillPath,
      "runtime/tests/vm/dart/run_appended_aot_snapshot_test.dart",
    ]);
    expectOutput("", dillResult);

    final aotResult = await runGenSnapshot("generate aot", [
      "--snapshot-kind=app-aot-blobs",
      "--blobs_container_filename=$aotPath",
      dillPath,
    ]);
    expectOutput("", aotResult);

    await writeAppendedExecutable(dartPrecompiledRuntime, aotPath, exePath);

    if (Platform.isLinux || Platform.isMacOS) {
      final execResult =
          await runBinary("make executable", "chmod", ["+x", exePath]);
      expectOutput("", execResult);
    }

    final runResult =
        await runBinary("run appended aot snapshot", exePath, ["--child"]);
    expectOutput("Hello, Appended AOT", runResult);
  });
}
