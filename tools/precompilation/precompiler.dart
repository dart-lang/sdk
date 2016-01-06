// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library precompiler;

import 'dart:io';

void run(String executable, String arguments, [String workingDirectory]) {
  print("+ $executable ${arguments.join(' ')}");
  var result = Process.runSync(executable, arguments,
                               workingDirectory: workingDirectory);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}

void main(List<String> args) {
  var configuration = Platform.environment["DART_CONFIGURATION"];

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

  if (configuration.endsWith("X64")) {
    cc_flags = "-m64";
  } else if (configuration.endsWith("SIMARM64")) {
    cc_flags = "-m64";
  } else if (configuration.endsWith("SIMARM")) {
    cc_flags = "-m32";
  } else if (configuration.endsWith("SIMMIPS")) {
    cc_flags = "-m32";
  } else if (configuration.endsWith("ARM")) {
    cc_flags = "";
  } else if (configuration.endsWith("MIPS")) {
    cc_flags = "-EL";
  } else {
    print("Architecture not supported: $configuration");
    return;
  }

  var tmpDir;
  for (var arg in args) {
    if (arg.startsWith("--gen-precompiled-snapshot")) {
      tmpDir = arg.substring("--gen-precompiled-snapshot".length + 1);
    }
  }
  print("Using directory $tmpDir");

  run(args[0], args.sublist(1));
  run(cc, [shared, cc_flags, "-o", libname, "precompiled.S"], tmpDir);
}
