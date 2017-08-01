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

import 'package:migration/src/fork.dart';
import 'package:migration/src/io.dart';
import 'package:migration/src/log.dart';
import 'package:migration/src/migrate_statuses.dart';
import 'package:migration/src/test_directories.dart';

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

  tests = tests.sublist(startIndex, endIndex + 1);

  if (tests.isEmpty) {
    print(bold("No tests in range."));
    return;
  }

  var s = tests.length == 1 ? "" : "s";
  var first = tests.first.twoPath;
  var last = tests.last.twoPath;
  print("Migrating ${bold(tests.length)} test$s from ${bold(first)} "
      "to ${bold(last)}...");
  print("");

  var allTodos = <String, List<String>>{};
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

  migrateStatusEntries(tests);

  // Tell the user what's left to do.
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

  for (var fromDir in fromRootDirs) {
    var twoDir = toTwoDirectory(fromDir);
    for (var path in listFiles(fromDir)) {
      var fromPath = p.relative(path, from: testRoot);
      var twoPath = p.join(twoDir, p.relative(fromPath, from: fromDir));

      tests.putIfAbsent(twoPath, () => new Fork(twoPath));
    }
  }

  // Include tests that have already been migrated too so we can show what
  // works remains to be done in them.
  for (var dir in twoRootDirs) {
    for (var path in listFiles(dir)) {
      var twoPath = p.relative(path, from: testRoot);
      tests.putIfAbsent(twoPath, () => new Fork(twoPath));
    }
  }

  var sorted = tests.values.toList();
  sorted.sort((a, b) => a.twoPath.compareTo(b.twoPath));
  return sorted;
}
