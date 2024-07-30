// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import "utils/io_utils.dart";

Future<void> main(List<String> args) async {
  Uri dart = repoDir.resolve(
      "tools/sdks/dart-sdk/bin/dart${Platform.isWindows ? ".exe" : ""}");
  if (!new File.fromUri(dart).existsSync()) {
    throw "Couldn't find $dart executable.";
  }

  Uri d8 = repoDir.resolve(_d8executable);
  if (!new File.fromUri(d8).existsSync()) {
    throw "Couldn't find $d8 executable.";
  }

  Uri fileHelper =
      repoDir.resolve("pkg/front_end/test/web_parser_git_test_helper.dart");
  if (!new File.fromUri(fileHelper).existsSync()) {
    throw "Couldn't find $fileHelper file.";
  }

  Directory tempDir = Directory.systemTemp.createTempSync("web_parser_test");
  try {
    Uri outFile = tempDir.uri.resolve("out.js");
    ProcessResult dartRun = Process.runSync(dart.toFilePath(), [
      "compile",
      "js",
      "--output",
      outFile.toFilePath(),
      "--enable-asserts",
      fileHelper.toFilePath()
    ]);
    if (dartRun.exitCode != 0) {
      throw "---\n"
          "Dart run returned ${dartRun.exitCode}.\n"
          "stdout: ${dartRun.stdout}\n\n"
          "stderr: ${dartRun.stderr}"
          "---";
    }
    ProcessResult d8Run =
        Process.runSync(d8.toFilePath(), [outFile.toFilePath()]);
    if (d8Run.exitCode != 0) {
      throw "---\n"
          "D8 run returned ${d8Run.exitCode}.\n"
          "stdout: ${d8Run.stdout}\n\n"
          "stderr: ${d8Run.stderr}\n"
          "---";
    }
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

final Uri repoDir = computeRepoDirUri();

String get _d8executable {
  final arch = Abi.current().toString().split('_')[1];
  if (Platform.isWindows) {
    return 'third_party/d8/windows/$arch/d8.exe';
  } else if (Platform.isLinux) {
    return 'third_party/d8/linux/$arch/d8';
  } else if (Platform.isMacOS) {
    return 'third_party/d8/macos/$arch/d8';
  }
  throw UnsupportedError('Unsupported platform.');
}
