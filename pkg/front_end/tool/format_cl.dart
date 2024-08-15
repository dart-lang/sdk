// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show LineSplitter, utf8;
import 'dart:developer' as dev show NativeRuntime;
import 'dart:io';

import '../presubmit_helper.dart' show getChangedFiles;
import '../test/utils/io_utils.dart';

Future<void> main() async {
  Uri executable = getDartExecutable();
  final List<String> allChangedFiles =
      getChangedFiles(collectUncommitted: true);
  if (allChangedFiles.isEmpty) {
    print("No changes in CL.");
    return;
  }
  final List<String> changedDartFiles = [];
  for (String changedFile in allChangedFiles) {
    if (changedFile.toLowerCase().endsWith(".dart")) {
      changedDartFiles.add(changedFile);
    }
  }
  if (changedDartFiles.isEmpty) {
    print("No changed dart files in CL.");
    return;
  }
  Process p = await Process.start(
      executable.toFilePath(), ["format", ...changedDartFiles]);

  p.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
    stderr.writeln("stderr> $line");
  });
  p.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
    stdout.writeln("stdout> $line");
  });

  exitCode = await p.exitCode;
}

Uri getDartExecutable() {
  Uri executable = Uri.base.resolve(Platform.resolvedExecutable);
  if (executable == Platform.script || dev.NativeRuntime.buildId != null) {
    // Probably aot compiled. We need to find "dart" another way.
    bool found = false;
    try {
      final Uri repoDir = computeRepoDirUri();
      for (String candidatePath in [
        "out/ReleaseX64/dart",
        "out/ReleaseX64/dart-sdk/bin/dart",
        "out/ReleaseX64/dart.exe",
        "out/ReleaseX64/dart-sdk/bin/dart.exe",
        "xcodebuild/ReleaseX64/dart",
        "xcodebuild/ReleaseX64/dart-sdk/bin/dart",
      ]) {
        Uri candidate = repoDir.resolve(candidatePath);
        if (File.fromUri(candidate).existsSync()) {
          executable = candidate;
          found = true;
          break;
        }
      }
    } catch (e) {
      print("Warning: $e");
    }
    if (!found) {
      Uri? candidate = where("dart");
      if (candidate != null) {
        executable = candidate;
      } else {
        throw "Couldn't find a dart executable to use.";
      }
    }
    print("Using $executable");
  }
  return executable;
}

Uri? where(String needle) {
  String pathEnvironment = Platform.environment["PATH"] ?? '';
  List<String> paths;
  if (Platform.isWindows) {
    paths = pathEnvironment.split(";");
  } else {
    paths = pathEnvironment.split(":");
  }
  // This isn't great but will probably work for our purposes.
  List<String> extensions = ["", ".exe", ".bat", ".com"];

  for (String path in paths) {
    for (String extension in extensions) {
      File f = new File("$path${Platform.pathSeparator}$needle$extension");
      if (f.existsSync()) {
        return f.uri;
      }
    }
  }
  return null;
}
