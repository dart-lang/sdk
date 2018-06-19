// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void main(List<String> args) {
  if (args.contains("--child")) {
    print("Hello, sharing world!");
    return;
  }

  if (!Platform.executable.endsWith("dart_precompiled_runtime")) {
    return; // Running in JIT or Windows: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and dart_bootstrap not available on the test device.
  }

  var buildDir =
      Platform.executable.substring(0, Platform.executable.lastIndexOf('/'));
  var tempDir = Directory.systemTemp.createTempSync("app-shared");
  var snapshot1Path = tempDir.uri.resolve("hello1.snapshot").toFilePath();
  var snapshot2Path = tempDir.uri.resolve("hello2.snapshot").toFilePath();
  var scriptPath = new Directory(buildDir)
      .uri
      .resolve("../../tests/standalone_2/app_snapshot_share_test.dart")
      .toFilePath();
  final scriptPathDill = tempDir.uri.resolve('app.dill').toFilePath();

  try {
    args = <String>[
      '--aot',
      '--strong-mode',
      '--sync-async',
      '--platform=$buildDir/vm_platform_strong.dill',
      '-o',
      scriptPathDill,
      '--entry-points',
      'out/ReleaseX64/gen/runtime/bin/precompiler_entry_points.json',
      '--entry-points',
      'pkg/vm/lib/transformations/type_flow/entry_points_extra.json',
      '--entry-points',
      'pkg/vm/lib/transformations/type_flow/entry_points_extra_standalone.json',
      scriptPath,
    ];
    runSync("pkg/vm/tool/gen_kernel${Platform.isWindows ? '.bat' : ''}", args);

    args = <String>[
      "--strong",
      "--deterministic",
      "--use-blobs",
      "--snapshot-kind=app-aot",
      "--snapshot=$snapshot1Path",
      scriptPathDill,
    ];
    runSync("$buildDir/dart_bootstrap", args);

    args = <String>[
      "--strong",
      "--deterministic",
      "--use-blobs",
      "--snapshot-kind=app-aot",
      "--snapshot=$snapshot2Path",
      "--shared-blobs=$snapshot1Path",
      scriptPathDill,
    ];
    runSync("$buildDir/dart_bootstrap", args);

    var sizeWithoutSharing = new File(snapshot1Path).statSync().size;
    var deltaWhenSharing = new File(snapshot2Path).statSync().size;
    print("sizeWithoutSharing: ${sizeWithoutSharing.toString().padLeft(8)}");
    print("deltaWhenSharing:   ${deltaWhenSharing.toString().padLeft(8)}");
    if (deltaWhenSharing >= sizeWithoutSharing) {
      throw "Sharing did not shrink size";
    }

    args = <String>[
      "--strong",
      "--shared-blobs=$snapshot1Path",
      snapshot2Path,
      "--child",
    ];
    final result = runSync("$buildDir/dart_precompiled_runtime", args);
    if (!result.stdout.contains("Hello, sharing world!")) {
      throw "Missing output";
    }
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

ProcessResult runSync(String executable, List<String> args) {
  print("+ $executable ${args.join(' ')}");

  final result = Process.runSync(executable, args);
  print("Exit code: ${result.exitCode}");
  print("stdout:");
  print(result.stdout);
  print("stderr:");
  print(result.stderr);

  if (result.exitCode != 0) {
    throw "Bad exit code";
  }
  return result;
}
