// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:migration/src/analyze.dart';
import 'package:migration/src/io.dart';
import 'package:migration/src/log.dart';
import 'package:migration/src/test_directories.dart';

void main(List<String> arguments) {
  arguments = arguments.toList();
  dryRun = arguments.remove("--dry-run");

  if (arguments.length != 2) {
    stderr.writeln("Usage: dart migrate.dart [--dry-run] <step> <source dir>");
    exit(1);
  }

  var step = arguments[0];
  var testDir = arguments[1];

  // If the test directory is just a single identifier, assume it's a language
  // test subdirectory.
  if (!testDir.contains("/")) testDir = "language_2/$testDir";

  switch (step) {
    case "branch":
      _createBranch(testDir);
      break;

    case "copy":
      _copyFiles(testDir);
      break;

    case "fork":
      _forkFiles(testDir);
      break;

    case "analyze":
      _analyzeFiles(testDir);
      break;

    default:
      stderr.writeln("Unknown migration step '$step'.");
      exit(1);
  }
}

/// Creates a Git branch whose name matches [testDir].
void _createBranch(String testDir) {
  if (_createGitBranch(testDir)) {
    _showNextStep("Next, copy the migrated files over", "copy", testDir);
  }
}

/// Copies files from [testDir] to the corresponding NNBD test directory.
///
/// Checks for collisions.
void _copyFiles(String testDir, {bool showNextStep = false}) {
  for (var from in listFiles(testDir)) {
    var to = toNnbdPath(from);
    if (fileExists(to)) {
      if (filesIdentical(from, to)) {
        note("$from has already been copied to $to.");
      } else {
        warn(
            "$to already exists with different contents than $from. Skipping.");
      }
    } else {
      copyFile(from, to);
      done("Copied $from -> $to");
    }
  }

  print(green("Copied files from $testDir -> ${toNnbdPath(testDir)}."));
  if (showNextStep) {
    print("Next, commit the new files and upload a new CL with them:");
    print("");
    print(bold("  git add ."));
    print(bold("  git commit -m \"Migrate $testDir to NNBD\"."));
    print(bold("  git cl upload --bypass-hooks"));
    _showNextStep("Then use analyzer to migrate the files", "analyze", testDir);
  }
}

/// Same as "branch" + "copy" then a commit.
///
/// Creates a branch, copies files over, and then commits them.
void _forkFiles(String testDir) {
  if (!_createGitBranch(testDir)) return;
  _copyFiles(testDir, showNextStep: false);

  if (!runProcess("git", ["add", "."])) {
    print(red("Failed to stage changes."));
    return;
  }

  if (!runProcess("git", ["commit", "-m", "Migrate $testDir to NNBD."])) {
    print(red("Failed to commit changes."));
    return;
  }

  print(green("Copied files to a new branch and committed."));
  print("Next, upload a new CL with them:");
  print("");
  print(bold("  git cl upload --bypass-hooks"));
  _showNextStep("Then use analyzer to migrate the files", "analyze", testDir);
}

Future _analyzeFiles(String testDir) async {
  var toDir = p.join(testRoot, toNnbdPath(testDir));
  if (await analyzeTests(toDir)) {
    print(
        "Next, commit the changed files and upload a new patchset with them:");
    print(bold("  git add ."));
    print(bold("  git commit -m \"Apply changes needed for NNBD\"."));
    print(bold("  git cl upload --bypass-hooks"));
    print("");
    print("Finally, send that out for code review and land the changes!");
  } else {
    _showNextStep(
        "There are still analysis errors. Fix those and then re-run this step",
        "analyze",
        testDir);
  }
}

void _showNextStep(String message, String step, String testDir) {
  print("");
  print("$message:");
  print("");
  print(bold("  dart tools/migration/bin/migrate.dart "
      "${dryRun ? '--dry-run ' : ''}$step $testDir"));
}

bool _createGitBranch(String testDir) {
  var dirName = toNnbdPath(testDir)
      .replaceAll("/", "-")
      .replaceAll("_", "-")
      .replaceAll(RegExp("[^a-z0-9-]"), "");
  var branchName = "migrate-$dirName";
  var success = runProcess("git", ["checkout", "-b", branchName]);
  if (success) {
    print(green("Created and switched to Git branch '$branchName'."));
  } else {
    print(red("Failed to create Git branch '$branchName'."));
  }

  return success;
}
