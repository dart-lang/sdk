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
import 'package:status_file/status_file.dart';

import 'package:migration/src/fork.dart';
import 'package:migration/src/io.dart';
import 'package:migration/src/log.dart';

const simpleDirs = const ["corelib", "language", "lib"];

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

  var tests = scanTests();

  var startIndex = findFork(tests, arguments[0]);
  var endIndex = findFork(tests, arguments[1]);

  if (startIndex == null || endIndex == null) exit(1);

  var first = tests[startIndex].twoPath;
  var last = tests[endIndex].twoPath;

  // Make the range half-inclusive to simplify the math below.
  endIndex++;

  if (endIndex - startIndex == 0) {
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

int findFork(List<Fork> forks, String description) {
  var matches = <int>[];

  for (var i = 0; i < forks.length; i++) {
    if (forks[i].twoPath.contains(description)) matches.add(i);
  }

  if (matches.isEmpty) {
    print('Could not find a test matching "${bold(description)}".');
    return null;
  } else if (matches.length == 1) {
    return matches.first;
  } else {
    print('Description "${bold(description)}" is ambiguous. Could be any of:');
    for (var i in matches) {
      print("- ${forks[i].twoPath.replaceAll(description, bold(description))}");
    }

    print("Please use a more precise description.");
    return null;
  }
}

/// Loads all of the unforked test files.
///
/// Creates an list of [Fork]s, ordered by their destination paths. Handles
/// tests that only appear in one fork or the other, or both.
List<Fork> scanTests() {
  var tests = <String, Fork>{};

  addFromDirectory(String fromDir, String twoDir) {
    for (var path in listFiles(fromDir)) {
      var fromPath = p.relative(path, from: testRoot);
      var twoPath = p.join(twoDir, p.relative(fromPath, from: fromDir));

      var fork = tests.putIfAbsent(twoPath, () => new Fork(twoPath));
      if (fromDir.contains("_strong")) {
        fork.strongPath = fromPath;
      } else {
        fork.onePath = fromPath;
      }
    }
  }

  addFromDirectory("corelib", "corelib_2");
  addFromDirectory("corelib_strong", "corelib_2");
  addFromDirectory("html", "lib_2/html");
  addFromDirectory("isolate", "lib_2/isolate");
  addFromDirectory("language", "language_2");
  addFromDirectory("language_strong", "language_2");
  addFromDirectory("lib", "lib_2");
  addFromDirectory("lib_strong", "lib_2");

  // Include tests that have already been migrated too so we can show what
  // works remains to be done in them.
  const twoDirs = const [
    "corelib_2",
    "lib_2",
    "language_2",
  ];

  for (var dir in twoDirs) {
    for (var path in listFiles(dir)) {
      var twoPath = p.relative(path, from: testRoot);
      tests.putIfAbsent(twoPath, () => new Fork(twoPath));
    }
  }

  var sorted = tests.values.toList();
  sorted.sort((a, b) => a.twoPath.compareTo(b.twoPath));
  return sorted;
}

List<StatusFile> loadStatusFiles() {
  var statusFiles = <StatusFile>[];

  addStatusFile(String fromDir) {
    for (var path in listFiles(fromDir, extension: ".status")) {
      statusFiles.add(new StatusFile.read(path));
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
