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
import 'package:migration/src/validate.dart';
import 'package:status_file/status_file.dart';

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

  if ((endIndex - startIndex) == 0) {
    print(bold("No tests in range."));
    return;
  }

  print("Migrating ${bold(endIndex - startIndex)} tests from ${bold(first)} "
      "to ${bold(last)}...");
  print("");

  var allTodos = <String, List<String>>{};
  tests = tests.sublist(startIndex, endIndex);
  var migratedTests = 0;
  var unmigratedTests = 0;
  for (var test in tests) {
    var todos = test.migrate();
    if (todos.isEmpty) {
      migratedTests++;
    } else {
      unmigratedTests++;
      allTodos[test.twoPath] = todos;
    }
  }

  // Print status file entries.
  var statusFileEntries = new StringBuffer();
  var statusFiles = loadStatusFiles();
  for (var statusFile in statusFiles) {
    printStatusFileEntries(statusFileEntries, tests, statusFile);
  }

  new File("statuses.migration")
      .writeAsStringSync(statusFileEntries.toString());
  print("Wrote relevant test status file entries to 'statuses.migration'.");

  // Tell the user what's left TODO.
  print("");
  var summary = "";

  if (migratedTests > 0) {
    var s = migratedTests == 1 ? "" : "s";
    summary += "Successfully migrated ${green(migratedTests)} test$s. ";
  }

  if (unmigratedTests > 0) {
    var s = unmigratedTests == 1 ? "" : "s";
    summary += "Need manual work on ${red(unmigratedTests)} test$s:";
  }

  print(summary);
  var todoTests = allTodos.keys.toList();
  todoTests.sort();
  for (var todoTest in todoTests) {
    print("- ${bold(todoTest)}:");
    allTodos[todoTest].forEach(todo);
  }
}

/// Returns a [String] of the relevant status file entries associated with the
/// tests in [tests] found in [statusFile].
void printStatusFileEntries(
    StringBuffer statusFileEntries, List<Fork> tests, StatusFile statusFile) {
  var filteredStatusFile = new StatusFile(statusFile.path);
  var testNames = <String>[];
  for (var test in tests) {
    testNames.add(test.twoPath.split("/").last.split(".")[0]);
  }
  for (var section in statusFile.sections) {
    StatusSection currentSection;
    for (var entry in section.entries) {
      for (var testName in testNames) {
        if (entry.path.contains(testName)) {
          if (currentSection == null) {
            currentSection = new StatusSection(section.condition);
          }
          currentSection.entries.add(entry);
        }
      }
    }
    if (currentSection != null) {
      filteredStatusFile.sections.add(currentSection);
    }
  }
  if (!filteredStatusFile.isEmpty) {
    statusFileEntries.writeln("Entries for status file ${statusFile.path}:");
    statusFileEntries.writeln(filteredStatusFile);
  }
}

String toTwoPath(String path) {
  // Allow eliding "_test" and/or ".dart" to make things more command-line
  // friendly.
  if (!path.endsWith(".dart") && !path.endsWith("_test.dart")) {
    path += "_test.dart";
  }
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
      if (!entry.path.endsWith(".dart")) continue;

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

List<StatusFile> loadStatusFiles() {
  var statusFiles = <StatusFile>[];

  addStatusFile(String fromDir) {
    for (var entry
        in new Directory(p.join(testRoot, fromDir)).listSync(recursive: true)) {
      if (!entry.path.endsWith(".status")) continue;

      statusFiles.add(new StatusFile.read(entry.path));
    }
  }

  addStatusFile("corelib");
  addStatusFile("corelib_strong");
  addStatusFile("html");
  addStatusFile("isolate");
  addStatusFile("language");
  addStatusFile("language_strong");
  addStatusFile("lib");
  addStatusFile("lib_strong");
  return statusFiles;
}

/// Moves the file from [from] to [to], which are both assumed to be relative
/// paths inside "tests".
void moveFile(String from, String to) {
  if (dryRun) {
    print("  Dry run: move $from to $to");
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

/// Deletes the file at [path], which is assumed to be relative within "tests".
void deleteFile(String path) {
  if (dryRun) {
    print("  Dry run: delete $path");
    return;
  }

  new File(p.join(testRoot, path)).deleteSync();
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

  List<String> migrate() {
    print("- ${bold(twoPath)}:");

    var todos = <String>[];
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
          todos.add("Merge from ${bold(onePath)} into this file.");
          validateFile(onePath, oneSource);
        }
      }

      if (strongPath != null) {
        if (strongSource == twoSource) {
          deleteFile(strongPath);
          done("Deleted already-migrated ${bold(strongPath)}.");
        } else {
          note("${bold(strongPath)} does not match already-migrated "
              "${bold(twoPath)}.");
          todos.add("Merge from ${bold(strongPath)} into this file.");
          validateFile(strongPath, strongSource);
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
        validateFile(twoPath, oneSource);
      } else {
        // Otherwise, a manual merge is required. Start with the strong one.
        print(new File(strongPath).existsSync());
        moveFile(strongPath, twoPath);
        done("Moved strong fork, kept 1.0 fork, manual merge required.");
        todos.add("Merge from ${bold(onePath)} into this file.");
        validateFile(onePath, oneSource);
      }
    }

    validateFile(twoPath, twoSource, todos);

    return todos;
  }
}
