// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:expect/expect.dart";

main() {
  print("new dart.vm.asan = ${new bool.fromEnvironment('dart.vm.asan')}");
  print("new dart.vm.msan = ${new bool.fromEnvironment('dart.vm.msan')}");
  print("new dart.vm.tsan = ${new bool.fromEnvironment('dart.vm.tsan')}");
  print("new dart.vm.product = ${new bool.fromEnvironment('dart.vm.product')}");
  print("const dart.vm.asan = ${const bool.fromEnvironment('dart.vm.asan')}");
  print("const dart.vm.msan = ${const bool.fromEnvironment('dart.vm.msan')}");
  print("const dart.vm.tsan = ${const bool.fromEnvironment('dart.vm.tsan')}");
  print(
    "const dart.vm.product = ${const bool.fromEnvironment('dart.vm.product')}",
  );

  // From package:test_runner.
  print("DART_CONFIGURATION = ${Platform.environment['DART_CONFIGURATION']}");

  Expect.equals(
    Platform.environment["DART_CONFIGURATION"]!.contains("ASAN"),
    new bool.fromEnvironment("dart.vm.asan"),
    "new dart.vm.asan",
  );
  Expect.equals(
    Platform.environment["DART_CONFIGURATION"]!.contains("MSAN"),
    new bool.fromEnvironment("dart.vm.msan"),
    "new dart.vm.msan",
  );
  Expect.equals(
    Platform.environment["DART_CONFIGURATION"]!.contains("TSAN"),
    new bool.fromEnvironment("dart.vm.tsan"),
    "new dart.vm.tsan",
  );
  Expect.equals(
    Platform.environment["DART_CONFIGURATION"]!.contains("Product"),
    new bool.fromEnvironment("dart.vm.product"),
    "new dart.vm.product",
  );

  Expect.equals(
    Platform.environment["DART_CONFIGURATION"]!.contains("ASAN"),
    const bool.fromEnvironment("dart.vm.asan"),
    "const dart.vm.asan",
  );
  Expect.equals(
    Platform.environment["DART_CONFIGURATION"]!.contains("MSAN"),
    const bool.fromEnvironment("dart.vm.msan"),
    "const dart.vm.msan",
  );
  Expect.equals(
    Platform.environment["DART_CONFIGURATION"]!.contains("TSAN"),
    const bool.fromEnvironment("dart.vm.tsan"),
    "const dart.vm.tsan",
  );
  Expect.equals(
    Platform.environment["DART_CONFIGURATION"]!.contains("Product"),
    const bool.fromEnvironment("dart.vm.product"),
    "const dart.vm.product",
  );
}
