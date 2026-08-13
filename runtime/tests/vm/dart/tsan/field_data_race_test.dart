// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--experimental-shared-data --no-osr --no-background-compilation

import "dart:ffi";
import "dart:io";
import "dart:isolate";
import "package:expect/expect.dart";

import '../dylib_utils.dart';

class Box {
  int foo = 0;
}

// This is effectively shared, which is currently not allowed, but
// we still want to have tests that shows tsan diagnostic in presence
// of data races accessing list elements.
Box box = getObjectFromAddr(boxAddr) as Box;

@pragma("vm:entry-point")
@pragma("vm:shared")
final int boxAddr = getAddrFromObject(Box());

@pragma("vm:never-inline")
dataRaceFromMain() {
  final localBox = box;
  for (var i = 0; i < 50000; i++) {
    usleep(100);
    var t = localBox.foo;
    usleep(100);
    localBox.foo = t + 1;
  }
}

@pragma("vm:never-inline")
dataRaceFromChild() {
  final localBox = box;
  for (var i = 0; i < 50000; i++) {
    usleep(100);
    var t = localBox.foo;
    usleep(100);
    localBox.foo = t + 1;
  }
}

@pragma("vm:never-inline")
dataRaceFromMainCaller() => dataRaceFromMain();

@pragma("vm:never-inline")
dataRaceFromMainCallerCaller() => dataRaceFromMainCaller();

@pragma("vm:never-inline")
dataRaceFromChildCaller() => dataRaceFromChild();

@pragma("vm:never-inline")
dataRaceFromChildCallerCaller() => dataRaceFromChildCaller();

child(replyPort) {
  dataRaceFromChildCallerCaller();
  replyPort.send(null);
}

final nativeLib = dlopenPlatformSpecific('ffi_test_functions');
final getAddrFromObject = nativeLib
    .lookupFunction<IntPtr Function(Handle), int Function(Object)>(
      'GetAddrFromObject',
    );
final getObjectFromAddr = nativeLib
    .lookupFunction<Handle Function(IntPtr), Object Function(int)>(
      'GetObjectFromAddr',
    );
final releaseAddr = nativeLib
    .lookupFunction<Void Function(IntPtr), void Function(int)>('ReleaseAddr');

// Leaf: we don't want the two threads to synchronize via safepoint.
final usleep = DynamicLibrary.process()
    .lookupFunction<Void Function(Long), void Function(int)>(
      'usleep',
      isLeaf: true,
    );

main(List<String> arguments) {
  if (arguments.contains("--testee")) {
    // Avoid synchronizing via lazy compilation.
    usleep(0);
    box!.foo += 0;

    var port = new RawReceivePort();
    port.handler = (_) => port.close();
    Isolate.spawn(child, port.sendPort);
    dataRaceFromMainCallerCaller();
    return;
  }

  var exec = Platform.executable;
  var args = [
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    "--testee",
  ];
  print("+ $exec ${args.join(' ')}");

  var result = Process.runSync(exec, args);
  print("Command stdout:");
  print(result.stdout);
  print("Command stderr:");
  print(result.stderr);

  Expect.notEquals(0, result.exitCode);
  Expect.contains("ThreadSanitizer: data race", result.stderr);
  Expect.contains("of size 8", result.stderr);
  Expect.contains("dataRaceFromMain", result.stderr);
  Expect.contains("dataRaceFromMainCaller", result.stderr);
  Expect.contains("dataRaceFromMainCallerCaller", result.stderr);
  Expect.contains("dataRaceFromChild", result.stderr);
  Expect.contains("dataRaceFromChildCaller", result.stderr);
  Expect.contains("dataRaceFromChildCallerCaller", result.stderr);
}
