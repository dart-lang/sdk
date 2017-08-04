// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Given the beginning and ending file names in a batch, does as much automated
/// migration and possible and prints out the remaining manual steps required.
///
/// This should be safe to run, and safe to re-run on an in-progress chunk.
/// However, it has not been thoroughly tested, so run at your own risk.

import 'dart:io';

import 'package:migration/src/fork.dart';
import 'package:migration/src/io.dart';
import 'package:migration/src/log.dart';
import 'package:migration/src/migrate_statuses.dart';

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
    stderr.writeln("    \$ dart migrate_batch.dart map_to_string queue");
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

  migrateStatusEntries(tests, allTodos);

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
