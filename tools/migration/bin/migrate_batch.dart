// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Given the beginning and ending file names in a batch, does as much automated
/// migration and possible and prints out the remaining manual steps required.
///
/// This should be safe to run, and safe to re-run on an in-progress chunk.
/// However, it has not been thoroughly tested, so run at your own risk.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:migration/src/log.dart';

const simpleDirs = const ["corelib", "language", "lib"];

final String sdkRoot =
    p.normalize(p.join(p.dirname(p.fromUri(Platform.script)), '../../../'));

final String testRoot = p.join(sdkRoot, "tests");

bool dryRun = false;

void main(List<String> arguments) {
  if (arguments.contains("--dry-run")) {
    dryRun = true;
    arguments = arguments.where((argument) => argument != "--dry-run").toList();
  }

  if (arguments.length != 2) {
    stderr.writeln(
        "Usage: dart migrate_batch.dart [--dry-run] <first file> <last file>");
    stderr.writeln();
    stderr.writeln("Example:");
    stderr.writeln();
    stderr.writeln(
        "    \$ dart migrate_batch.dart corelib/map_to_string corelib/queue");
    exit(1);
  }

  var first = toTwoPath(arguments[0]);
  var last = toTwoPath(arguments[1]);

  var tests = scanTests();

  // Find the range of files in the chunk. We use comparisons here instead of
  // equality to try to compensate for files that may only appear in one fork
  // and should be part of the chunk but aren't officially listed as the begin
  // or end point.
  var startIndex = -1;
  var endIndex = 0;
  for (var i = 0; i < tests.length; i++) {
    if (startIndex == -1 && tests[i].twoPath.compareTo(first) >= 0) {
      startIndex = i;
    }

    if (tests[i].twoPath.compareTo(last) > 0) {
      endIndex = i;
      break;
    }
  }

  print("Migrating ${bold(endIndex - startIndex)} tests from ${bold(first)} "
      "to ${bold(last)}...");
  print("");

  var todos = <String>[];
  var migratedTests = 0;
  var unmigratedTests = 0;
  for (var i = startIndex; i < endIndex; i++) {
    if (tests[i].migrate(todos)) {
      migratedTests++;
    } else {
      unmigratedTests++;
    }
  }

  print("");

  var summary = "";

  if (migratedTests > 0) {
    var s = migratedTests == 1 ? "" : "s";
    summary += "Successfully migrated ${green(migratedTests)} test$s. ";
  }

  if (unmigratedTests > 0) {
    var s = migratedTests == 1 ? "" : "s";
    summary += "Need manual work on ${red(unmigratedTests)} test$s:";
  }

  print(summary);
  todos.forEach(todo);
}

String toTwoPath(String path) {
  // Allow eliding "_test" and/or ".dart" to make things more command-line
  // friendly.
  if (!path.endsWith("_test.dart")) path += "_test.dart";
  if (!path.endsWith(".dart")) path += ".dart";

  for (var dir in simpleDirs) {
    if (p.isWithin(dir, path)) {
      return p.join("${dir}_2", p.relative(path, from: dir));
    }

    if (p.isWithin("${dir}_strong", path)) {
      return p.join("${dir}_2", p.relative(path, from: dir));
    }
  }

  if (p.isWithin("html", path)) {
    return p.join("lib_2/html", p.relative(path, from: "html"));
  }

  if (p.isWithin("isolate", path)) {
    return p.join("lib_2/isolate", p.relative(path, from: "isolate"));
  }

  // Guess it's already a two path.
  return path;
}

/// Loads all of the unforked test files.
///
/// Creates an list of [Fork]s, ordered by their destination paths. Handles
/// tests that only appear in one fork or the other, or both.
List<Fork> scanTests() {
  var tests = <String, Fork>{};

  addTestDirectory(String fromDir, String twoDir) {
    for (var entry
        in new Directory(p.join(testRoot, fromDir)).listSync(recursive: true)) {
      if (!entry.path.endsWith("_test.dart")) continue;

      var fromPath = p.relative(entry.path, from: testRoot);
      var twoPath = p.join(twoDir, p.relative(fromPath, from: fromDir));

      var fork = tests.putIfAbsent(twoPath, () => new Fork(twoPath));
      if (fromDir.contains("_strong")) {
        fork.strongPath = fromPath;
      } else {
        fork.onePath = fromPath;
      }
    }
  }

  addTestDirectory("corelib", "corelib_2");
  addTestDirectory("corelib_strong", "corelib_2");
  addTestDirectory("html", "lib_2/html");
  addTestDirectory("isolate", "lib_2/isolate");
  addTestDirectory("language", "language_2");
  addTestDirectory("language_strong", "language_2");
  addTestDirectory("lib", "lib_2");
  addTestDirectory("lib_strong", "lib_2");

  var sorted = tests.values.toList();
  sorted.sort((a, b) => a.twoPath.compareTo(b.twoPath));
  return sorted;
}

/// Moves the file from [from] to [to], which are both assumed to be relative
/// paths inside "tests".
void moveFile(String from, String to) {
  if (dryRun) {
    print("  Dry run: move $from to $to");
    return;
  }

  new File(p.join(testRoot, from)).renameSync(p.join(testRoot, to));
}

/// Reads the contents of the file at [path], which is assumed to be relative
/// within "tests".
String readFile(String path) {
  return new File(p.join(testRoot, path)).readAsStringSync();
}

/// Deletes the file at [path], which is assumed to be relative within "tests".
void deleteFile(String path) {
  if (dryRun) {
    print("  Dry run: delete $path");
    return;
  }

  new File(p.join(testRoot, path)).deleteSync();
}

bool checkForUnitTest(String path, String source) {
  if (!source.contains("package:unittest")) return false;

  note("${bold(path)} uses unittest package.");
  return true;
}

class Fork {
  final String twoPath;
  String onePath;
  String strongPath;

  String get twoSource {
    if (twoPath == null) return null;
    if (_twoSource == null) _twoSource = readFile(twoPath);
    return _twoSource;
  }

  String _twoSource;

  String get oneSource {
    if (onePath == null) return null;
    if (_oneSource == null) _oneSource = readFile(onePath);
    return _oneSource;
  }

  String _oneSource;

  String get strongSource {
    if (strongPath == null) return null;
    if (_strongSource == null) _strongSource = readFile(strongPath);
    return _strongSource;
  }

  String _strongSource;

  Fork(this.twoPath);

  bool migrate(List<String> todos) {
    print("- ${bold(twoPath)}:");

    var todosBefore = todos.length;
    var isMigrated = new File(p.join(testRoot, twoPath)).existsSync();

    // If there is a migrated version and it's the same as an unmigrated one,
    // delete the unmigrated one.
    if (isMigrated) {
      if (onePath != null) {
        if (oneSource == twoSource) {
          deleteFile(onePath);
          done("Deleted already-migrated $onePath.");
        } else {
          note("${bold(onePath)} does not match already-migrated "
              "${bold(twoPath)}.");
          todos.add("Merge ${bold(onePath)} into ${bold(twoPath)}.");
          checkForUnitTest(onePath, oneSource);
        }
      }

      if (strongPath != null) {
        if (strongSource == twoSource) {
          deleteFile(strongPath);
          done("Deleted already-migrated ${bold(strongPath)}.");
        } else {
          note("${bold(strongPath)} does not match already-migrated "
              "${bold(twoPath)}.");
          todos.add("Merge ${bold(strongPath)} into ${bold(twoPath)}.");
          checkForUnitTest(strongPath, strongSource);
        }
      }
    } else {
      // If it only exists in one place, just move it.
      if (strongPath == null) {
        moveFile(onePath, twoPath);
        done("Moved from ${bold(onePath)} (no strong mode fork).");
      } else if (onePath == null) {
        moveFile(strongPath, twoPath);
        done("Moved from ${bold(strongPath)} (no 1.0 mode fork).");
      } else if (oneSource == strongSource) {
        // The forks are identical, pick one.
        moveFile(onePath, twoPath);
        deleteFile(strongPath);
        done("Merged identical forks.");
        checkForUnitTest(twoPath, oneSource);
      } else {
        // Otherwise, a manual merge is required. Start with the strong one.
        moveFile(strongPath, twoPath);
        done("Moved strong fork, kept 1.0 fork, manual merge required.");
        todos.add("Merge ${bold(onePath)} into ${bold(twoPath)}.");
        checkForUnitTest(onePath, oneSource);
      }
    }

    if (checkForUnitTest(twoPath, twoSource)) {
      todos.add("Migrate ${bold(twoPath)} off unittest.");
    }

    return todos.length == todosBefore;
  }
}
