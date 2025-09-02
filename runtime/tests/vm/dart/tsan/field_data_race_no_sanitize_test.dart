// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--experimental-shared-data

import "dart:ffi";
import "dart:io";
import "dart:isolate";
import "package:expect/expect.dart";

import '../dylib_utils.dart';

class Box {
  @pragma("vm:no-sanitize-thread") // __attribute__((no_sanitize("thread")))
  int foo = 0;
}

@pragma("vm:entry-point")
@pragma("vm:shared")
Box? box;

@pragma("vm:never-inline")
noopt() {}

@pragma("vm:never-inline")
dataRaceFromMain() {
  final localBox = box!;
  for (var i = 0; i < 1000000; i++) {
    localBox.foo += 1;
    noopt();
  }
}

@pragma("vm:never-inline")
dataRaceFromChild() {
  final localBox = box!;
  for (var i = 0; i < 1000000; i++) {
    localBox.foo += 1;
    noopt();
  }
}

child(_) {
  dataRaceFromChild();
}

final nativeLib = dlopenPlatformSpecific('ffi_test_functions');

final getRootLibraryUrl = nativeLib
    .lookupFunction<Handle Function(), Object Function()>('GetRootLibraryUrl');

final setFfiNativeResolverForTest = nativeLib
    .lookupFunction<Void Function(Handle), void Function(Object)>(
      'SetFfiNativeResolverForTest',
    );

@Native<IntPtr Function(Handle, Handle, Handle)>(symbol: 'UnsafeSetSharedTo')
external int unsafeSetSharedTo(Object library_name, String name, Object value);

main(List<String> arguments) {
  if (arguments.contains("--testee")) {
    setFfiNativeResolverForTest(getRootLibraryUrl());
    unsafeSetSharedTo(getRootLibraryUrl(), "box", Box());
    print(box); // side effect initialization
    Isolate.spawn(child, null);
    dataRaceFromMain();
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

  Expect.equals(0, result.exitCode);
}
