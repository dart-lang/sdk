// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'log.dart';

/// True if the file system should be left untouched.
bool dryRun = false;

final String sdkRoot =
    p.normalize(p.join(p.dirname(p.fromUri(Platform.script)), '../../../'));

final String testRoot = p.join(sdkRoot, "tests");

final String nnbdSdkBuildDir = () {
  var buildDir = Platform.isMacOS ? "xcodebuild" : "out";
  var path = p.join(sdkRoot, buildDir, "ReleaseX64NNBD", "dart-sdk");

  if (!Directory(path).existsSync()) {
    print(red("Could not find an NNBD SDK at $path"));
    print(red("Please build the NNBD SDK using:"));
    print("");
    print(red("  ./tools/build.py -m release --nnbd create_sdk"));
    exit(1);
  }

  return path;
}();

/// Copies the file from [from] to [to], which are both assumed to be relative
/// paths inside "tests".
void copyFile(String from, String to) {
  if (dryRun) {
    print("Dry run: copy $from to $to");
    return;
  }

  // Create the directory if needed.
  new Directory(p.dirname(p.join(testRoot, to))).createSync(recursive: true);
  new File(p.join(testRoot, from)).copySync(p.join(testRoot, to));
}

/// Moves the file from [from] to [to], which are both assumed to be relative
/// paths inside "tests".
void moveFile(String from, String to) {
  if (dryRun) {
    print("Dry run: move $from to $to");
    return;
  }

  // Create the directory if needed.
  new Directory(p.dirname(p.join(testRoot, to))).createSync(recursive: true);
  new File(p.join(testRoot, from)).renameSync(p.join(testRoot, to));
}

/// Reads the contents of the file at [path], which is assumed to be relative
/// within "tests".
String readFile(String path) {
  return new File(p.join(testRoot, path)).readAsStringSync();
}

/// Reads the contents of the file at [path], which is assumed to be relative
/// within "tests".
List<String> readFileLines(String path) {
  return File(p.join(testRoot, path)).readAsLinesSync();
}

/// Reads the contents of the file at [path], which is assumed to be relative
/// within "tests".
List<int> readFileBytes(String path) {
  return File(p.join(testRoot, path)).readAsBytesSync();
}

/// Writes [contents] to a file at [path], which is assumed to be relative
/// within "tests".
void writeFile(String path, String contents) {
  if (dryRun) {
    print("Dry run: write ${contents.length} characters to $path");
    return;
  }

  final oldContents = File(p.join(testRoot, path)).readAsStringSync();
  if (oldContents != contents) {
    File(p.join(testRoot, path)).writeAsStringSync(contents);
  }
}

/// Whether the contents of the files at [aPath] and [bPath] are identical.
bool filesIdentical(String aPath, String bPath) {
  var aBytes = File(p.join(testRoot, aPath)).readAsBytesSync();
  var bBytes = File(p.join(testRoot, bPath)).readAsBytesSync();
  if (aBytes.length != bBytes.length) return false;

  for (var i = 0; i < aBytes.length; i++) {
    if (aBytes[i] != bBytes[i]) return false;
  }

  return true;
}

/// Deletes the file at [path], which is assumed to be relative within "tests".
void deleteFile(String path) {
  if (dryRun) {
    print("Dry run: delete $path");
    return;
  }

  new File(p.join(testRoot, path)).deleteSync();
}

/// Whether the file at [path], which is assumed to be relative within "tests"
/// exists on disc.
bool fileExists(String path) {
  return File(p.join(testRoot, path)).existsSync();
}

bool runProcess(String executable, List<String> arguments,
    {String workingDirectory}) {
  if (dryRun) {
    print("Dry run: run $executable ${arguments.join(' ')}");
    return true;
  }

  var result = Process.runSync(executable, arguments);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  return result.exitCode == 0;
}

Future<bool> runProcessAsync(String executable, List<String> arguments,
    {String workingDirectory}) async {
  if (dryRun) {
    print("Dry run: run $executable ${arguments.join(' ')}");
    return true;
  }

  var process = await Process.start(executable, arguments);
  process.stdout.listen(stdout.add);
  process.stderr.listen(stderr.add);

  return (await process.exitCode) == 0;
}

/// Returns a list of the paths to all files within [dir], which is
/// assumed to be relative to the SDK's "tests" directory and having file with
/// an extension in [extensions].
Iterable<String> listFiles(String dir,
    {List<String> extensions = const [".dart", ".html"]}) {
  var files = Directory(p.join(testRoot, dir))
      .listSync(recursive: true)
      .where((entry) => extensions.any(entry.path.endsWith))
      .map((entry) => p.relative(entry.path, from: testRoot))
      .toList();
  files.sort();

  return files;
}
