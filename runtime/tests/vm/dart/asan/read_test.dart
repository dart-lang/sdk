// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";
import "dart:io";
import "package:expect/expect.dart";

@Native<Pointer Function(IntPtr)>(symbol: 'malloc')
external Pointer malloc(int size);
@Native<Void Function(Pointer)>(symbol: 'free')
external void free(Pointer ptr);

@pragma("vm:never-inline")
expectedFunction() {
  var p = malloc(1).cast<Int8>();   //# int8: ok
  var p = malloc(1).cast<Uint8>();  //# uint8: ok
  var p = malloc(2).cast<Int16>();  //# int16: ok
  var p = malloc(2).cast<Uint16>(); //# uint16: ok
  var p = malloc(4).cast<Int32>();  //# int32: ok
  var p = malloc(4).cast<Uint32>(); //# uint32: ok
  var p = malloc(8).cast<Int64>();  //# int64: ok
  var p = malloc(8).cast<Uint64>(); //# uint64: ok
  var p = malloc(4).cast<Float>();  //# float32: ok
  var p = malloc(8).cast<Double>(); //# float64: ok
  free(p);
  print(p[0]);  // ASAN: heap-use-after-free
}

main(List<String> arguments) {
  if (arguments.contains("--testee")) {
    expectedFunction();
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
  Expect.contains("AddressSanitizer: heap-use-after-free", result.stderr);
  Expect.contains("READ of size 1", result.stderr);  //# int8: ok
  Expect.contains("READ of size 1", result.stderr);  //# uint8: ok
  Expect.contains("READ of size 2", result.stderr);  //# int16: ok
  Expect.contains("READ of size 2", result.stderr);  //# uint16: ok
  Expect.contains("READ of size 4", result.stderr);  //# int32: ok
  Expect.contains("READ of size 4", result.stderr);  //# uint32: ok
  Expect.contains("READ of size 8", result.stderr);  //# int64: ok
  Expect.contains("READ of size 8", result.stderr);  //# uint64: ok
  Expect.contains("READ of size 4", result.stderr);  //# float32: ok
  Expect.contains("READ of size 8", result.stderr);  //# float64: ok
  if (Platform.executable.contains("aotruntime") && !Platform.isWindows) {
    Expect.contains("expectedFunction", result.stderr);
  }
}
