// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";
import "dart:io";

const int _prSetChildSubreaper = 36;

typedef _PrctlNative = Int32 Function(Int32, IntPtr, IntPtr, IntPtr, IntPtr);
typedef _Prctl = int Function(int, int, int, int, int);

Future<void> main() async {
  if (!Platform.isLinux) {
    return;
  }

  final prctl = DynamicLibrary.process().lookupFunction<_PrctlNative, _Prctl>(
    "prctl",
  );
  if (prctl(_prSetChildSubreaper, 1, 0, 0, 0) != 0) {
    throw StateError("Failed to become a child subreaper");
  }

  final tempDir = Directory.systemTemp.createTempSync(
    "process-exit-handler-zombie-",
  );
  try {
    final dart = _dartExecutable();
    final packageDir = Directory.fromUri(tempDir.uri.resolve("package/"))
      ..createSync();
    final binDir = Directory.fromUri(packageDir.uri.resolve("bin/"))
      ..createSync();
    File.fromUri(packageDir.uri.resolve("pubspec.yaml")).writeAsStringSync("""
name: exit_handler_test
environment:
  sdk: ^3.12.0
executables:
  exit_handler_test:
""");
    File.fromUri(binDir.uri.resolve("exit_handler_test.dart"))
        .writeAsStringSync("void main() {}\n");

    final pubCache = Directory.fromUri(tempDir.uri.resolve("pub-cache/"));
    final environment = {
      "CI": "true",
      "DASH__SUPPRESS_ANALYTICS": "true",
      "PUB_CACHE": pubCache.path,
    };
    final activation = await Process.run(dart, [
      "pub",
      "global",
      "activate",
      "--source",
      "path",
      packageDir.path,
    ], environment: environment);
    if (activation.exitCode != 0) {
      throw StateError(
        "Activation failed: ${activation.stdout}\n${activation.stderr}",
      );
    }

    final process = await Process.start("nice", [
      "-n",
      "15",
      dart,
      "pub",
      "global",
      "run",
      "exit_handler_test",
    ], environment: environment);
    final stdout = process.stdout.transform(systemEncoding.decoder).join();
    final stderr = process.stderr.transform(systemEncoding.decoder).join();
    if (await process.exitCode != 0) {
      throw StateError("Dart child failed: ${await stdout}\n${await stderr}");
    }
    await stdout;
    await stderr;

    for (var attempt = 0; attempt < 100; attempt++) {
      final zombies = _zombieChildren();
      if (zombies.isNotEmpty) {
        throw StateError("Found zombie children: $zombies");
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

String _dartExecutable() {
  final executable = File(Platform.resolvedExecutable);
  final sdkDart = File.fromUri(
    executable.parent.uri.resolve("dart-sdk/bin/dart"),
  );
  return sdkDart.existsSync() ? sdkDart.path : executable.path;
}

List<int> _zombieChildren() {
  final zombies = <int>[];

  for (final entry in Directory("/proc").listSync()) {
    final processId = int.tryParse(
      entry.uri.pathSegments.lastWhere(
        (segment) => segment.isNotEmpty,
        orElse: () => "",
      ),
    );
    if (processId == null) {
      continue;
    }

    try {
      final stat = File("/proc/$processId/stat").readAsStringSync();
      final closeParen = stat.lastIndexOf(")");
      final fields = stat.substring(closeParen + 2).split(" ");
      if (fields[0] == "Z" && int.parse(fields[1]) == pid) {
        zombies.add(processId);
      }
    } on FileSystemException {
      // The process exited while /proc was being scanned.
    }
  }

  return zombies;
}
