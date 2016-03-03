// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test generating and running a simple precompiled snapshot of this script.

import 'dart:io';

main(List args) {
  if (args.length > 0 && args[0] == "--hello") {
    print("Hello");
    return;
  }

  var cc, cc_flags, shared, libname;
  if (Platform.isLinux) {
    cc = 'gcc';
    shared = '-shared';
    libname = 'libprecompiled.so';
  } else if (Platform.isMacOS) {
    cc = 'clang';
    shared = '-dynamiclib';
    libname = 'libprecompiled.dylib';
  } else {
    print("Test only supports Linux and Mac");
    return;
  }

  if (Platform.version.contains("x64")) {
    cc_flags = "-m64";
  } else if (Platform.version.contains("simarm64")) {
    cc_flags = "-m64";
  } else if (Platform.version.contains("simarm")) {
    cc_flags = "-m32";
  } else if (Platform.version.contains("simmips")) {
    cc_flags = "-m32";
  } else if (Platform.version.contains("arm")) {
    cc_flags = "";
  } else if (Platform.version.contains("mips")) {
    cc_flags = "-EL";
  } else {
    print("Architecture not supported: ${Platform.version}");
    return;
  }

  var abs_package_root = Uri.parse(Platform.packageRoot).toFilePath();
  var dart_executable =
      Directory.current.path + Platform.pathSeparator + Platform.executable;
  Directory tmp;
  try {
    tmp = Directory.current.createTempSync("temp_precompilation_test");
    var exec = "${dart_executable}_bootstrap";
    var args = ["--package-root=$abs_package_root",
                "--gen-precompiled-snapshot",
                "${abs_package_root}compiler/src/dart2js.dart"];
    print("$exec ${args.join(' ')}");
    var result = Process.runSync(exec, args, workingDirectory: tmp.path);
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      throw "Snapshot generation failed.";
    }

    // Check if gcc is present, and skip test if it is not.
    try {
      result = Process.runSync(
          cc,
          ["--version"],
          workingDirectory: tmp.path);
      if (result.exitCode != 0) {
        throw "$cc --version failed.";
      }
    } catch(e) {
      print("Skipping test because $cc is not present: $e");
      return;
    }

    result = Process.runSync(
        cc,
        [shared, cc_flags, "-nostartfiles", "-o", libname, "precompiled.S"],
        workingDirectory: tmp.path);
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      throw "Shared library creation failed!";
    }

    var ld_library_path = new String.fromEnvironment("LD_LIBRARY_PATH");
    ld_library_path = "${ld_library_path}:${tmp.path}";
    exec = "${dart_executable}_precompiled_runtime";
    args = ["--run-precompiled-snapshot", "ignored_script", "--version"];
    print("LD_LIBRARY_PATH=$ld_library_path $exec ${args.join(' ')}");
    result = Process.runSync(exec, args,
       workingDirectory: tmp.path,
       environment: {"LD_LIBRARY_PATH": ld_library_path});
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      throw "Precompiled binary failed.";
    }
    print(result.stdout);
    if (!result.stdout.contains("Dart-to-JavaScript compiler")) {
      throw "Precompiled binary output mismatch.";
    }
  } finally {
    tmp?.deleteSync(recursive: true);
  }
}
