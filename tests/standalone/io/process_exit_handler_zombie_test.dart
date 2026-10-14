// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";
import "dart:io";

import "package:ffi/ffi.dart";

const int _prSetChildSubreaper = 36;
const int _eintr = 4;
const int _echild = 10;

typedef _PrctlNative = Int32 Function(Int32, IntPtr, IntPtr, IntPtr, IntPtr);
typedef _Prctl = int Function(int, int, int, int, int);

typedef _SpawnNative = Int32 Function(
  Pointer<Int32>,
  Pointer<Utf8>,
  Pointer<Void>,
  Pointer<Void>,
  Pointer<Pointer<Utf8>>,
  Pointer<Pointer<Utf8>>,
);
typedef _Spawn = int Function(
  Pointer<Int32>,
  Pointer<Utf8>,
  Pointer<Void>,
  Pointer<Void>,
  Pointer<Pointer<Utf8>>,
  Pointer<Pointer<Utf8>>,
);

final _libc = DynamicLibrary.process();
final _spawn = _libc.lookupFunction<_SpawnNative, _Spawn>("posix_spawnp");
final _waitpid = _libc
    .lookupFunction<
      Int32 Function(Int32, Pointer<Int32>, Int32),
      int Function(int, Pointer<Int32>, int)
    >("waitpid");
final _errno = _libc
    .lookupFunction<Pointer<Int32> Function(), Pointer<Int32> Function()>(
      "__errno_location",
    );

Future<void> main(List<String> args) async {
  if (!Platform.isLinux) {
    return;
  }

  if (args.isNotEmpty) {
    // Reap the last tracked child before shutting down. Exercise both the
    // transition to an idle handler and a handler already waiting on its
    // monitor, which must wake up and reap the shutdown child itself.
    final result = await Process.run("/bin/true", []);
    if (result.exitCode != 0) {
      throw StateError("Child failed: ${result.exitCode}");
    }
    if (args.single == "idle") {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
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
    // Test this runtime even when a separate packaged SDK is available for pub.
    final dart = Platform.resolvedExecutable;
    for (final mode in ["immediate", "idle"]) {
      for (var iteration = 0; iteration < 10; iteration++) {
        _runAndCheckChildren(dart, [Platform.script.toFilePath(), mode]);
      }
    }

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
    // A standalone VM build cannot run the pub command. Its adjacent packaged
    // SDK supplies pub; keep this distinct from the runtime tested above.
    final pubDart = _pubDartExecutable();
    _runAndCheckChildren(pubDart, [
      "pub",
      "global",
      "activate",
      "--source",
      "path",
      packageDir.path,
    ], environment: environment);
    _runAndCheckChildren("nice", [
      "-n",
      "15",
      pubDart,
      "pub",
      "global",
      "run",
      "exit_handler_test",
    ], environment: environment);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

String _pubDartExecutable() {
  final executable = File(Platform.resolvedExecutable);
  final sdkDart = File.fromUri(
    executable.parent.uri.resolve("dart-sdk/bin/dart"),
  );
  return sdkDart.existsSync() ? sdkDart.path : executable.path;
}

// Never use Dart's Process API in the observer: its exit handler calls wait(-1)
// and could silently reap an adopted wakeup child, hiding the regression.
// posix_spawnp also avoids returning into the Dart VM in a forked child.
void _runAndCheckChildren(
  String executable,
  List<String> arguments, {
  Map<String, String> environment = const {},
}) {
  using((arena) {
    Pointer<Pointer<Utf8>> strings(List<String> values) {
      final result = arena<Pointer<Utf8>>(values.length + 1);
      for (var i = 0; i < values.length; i++) {
        result[i] = values[i].toNativeUtf8(allocator: arena);
      }
      result[values.length] = nullptr;
      return result;
    }

    final child = arena<Int32>();
    final status = arena<Int32>();
    final argv = strings([executable, ...arguments]);
    final envp = strings([
      for (final entry in {...Platform.environment, ...environment}.entries)
        "${entry.key}=${entry.value}",
    ]);
    final error = _spawn(child, argv[0], nullptr, nullptr, argv, envp);
    if (error != 0) {
      throw StateError("posix_spawnp($executable) failed: errno $error");
    }

    int waitFor(int childPid) {
      int result;
      do {
        result = _waitpid(childPid, status, 0);
      } while (result == -1 && _errno().value == _eintr);
      return result;
    }

    if (waitFor(child.value) != child.value) {
      throw StateError(
        "waitpid(${child.value}) failed: errno ${_errno().value}",
      );
    }
    final childStatus = status.value;
    final adopted = <int>[];
    while (true) {
      final result = waitFor(-1);
      if (result == -1) {
        if (_errno().value != _echild) {
          throw StateError("waitpid(-1) failed: errno ${_errno().value}");
        }
        break;
      }
      adopted.add(result);
    }
    // The target has exited, so all of its orphaned descendants have been
    // adopted. Blocking waitpid catches even a wakeup child that has not exited
    // yet, and reaps every orphan before reporting the failure.
    if (adopted.isNotEmpty) {
      throw StateError(
        "$executable $arguments left unreaped children: $adopted",
      );
    }
    if (childStatus != 0) {
      throw StateError(
        "$executable $arguments failed: wait status $childStatus",
      );
    }
  });
}
