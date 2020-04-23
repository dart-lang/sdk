// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform, Process, ProcessResult;

import 'package:front_end/src/api_prototype/compiler_options.dart';

import 'package:kernel/ast.dart' as kernel show Version, defaultLanguageVersion;

import '../utils/io_utils.dart';

final String repoDir = computeRepoDir();

String get dartVm => Platform.executable;

main(List<String> args) async {
  ProcessResult result = await Process.run(
      "python", ["tools/make_version.py", "--no_git", "-q"],
      workingDirectory: repoDir);

  String stdout = result.stdout.toString();
  String stderr = result.stderr.toString();
  int exitCode = result.exitCode;

  print("--- stdout ---");
  print(stdout);
  print("--- stderr ---");
  print(stderr);
  print("---exit code ---");
  print(exitCode);

  // E.g. "2.6.0-edge" (without the quotes).
  String versionString = stdout.split("\n")[0];
  List<String> dotSeparatedParts = versionString.split(".");
  int major = int.tryParse(dotSeparatedParts[0]);
  int minor = int.tryParse(dotSeparatedParts[1]);
  kernel.Version version = new kernel.Version(major, minor);

  if (kernel.defaultLanguageVersion != version) {
    throw "Kernel defaults "
        "${kernel.defaultLanguageVersion}"
        " does not match output from make_version.py ($version)";
  } else {
    print("Kernel version matches.");
  }

  CompilerOptions compilerOptions = new CompilerOptions();

  List<String> dotSeparatedPartsFromOptions =
      compilerOptions.currentSdkVersion.split(".");
  int majorFromOptions = int.tryParse(dotSeparatedPartsFromOptions[0]);
  int minorFromOptions = int.tryParse(dotSeparatedPartsFromOptions[1]);
  if (majorFromOptions != major || minorFromOptions != minor) {
    throw "CompilerOptions defaults "
        "${majorFromOptions}.${minorFromOptions}"
        " does not match output from make_version.py ($major.$minor)";
  } else {
    print("CompilerOptions default version matches.");
  }
}
