// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'io.dart';
import 'log.dart';
import 'test_directories.dart';
import 'validate.dart';

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

/// Tracks one test and the various forked locations where it may appear.
///
/// * "One" refers to the original Dart 1.0 location of the test: language/,
///   corelib/, etc.
///
/// * "Strong" is the DDC fork of the file: language_strong, etc.
///
/// * "Two" is the migrated 2.0 destination location: language_2, etc.
class Fork {
  final String twoPath;
  String get onePath => toOnePath(twoPath);
  String get strongPath => toStrongPath(twoPath);

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

  bool get oneExists => new File(p.join(testRoot, onePath)).existsSync();
  bool get strongExists => new File(p.join(testRoot, strongPath)).existsSync();
  bool get twoExists => new File(p.join(testRoot, twoPath)).existsSync();

  String _strongSource;

  Fork(this.twoPath);

  List<String> migrate() {
    print("- ${bold(twoPath)}:");

    var todos = <String>[];

    if (!oneExists && !twoExists) {
      // It's already been migrated, so there's nothing to move.
      note("Is already migrated.");
    } else if (twoExists) {
      // If there is a migrated version and it's the same as an unmigrated one,
      // delete the unmigrated one.
      if (oneExists) {
        if (oneSource == twoSource) {
          deleteFile(onePath);
          done("Deleted already-migrated $onePath.");
        } else {
          note("${bold(onePath)} does not match already-migrated file.");
          todos.add("Merge from ${bold(onePath)} into this file.");
          validateFile(onePath, oneSource);
        }
      }

      if (strongExists) {
        if (strongSource == twoSource) {
          deleteFile(strongPath);
          done("Deleted already-migrated ${bold(strongPath)}.");
        } else {
          note("${bold(strongPath)} does not match already-migrated file.");
          todos.add("Merge from ${bold(strongPath)} into this file.");
          validateFile(strongPath, strongSource);
        }
      }
    } else {
      if (!strongExists) {
        // If it only exists in one place, just move it.
        moveFile(onePath, twoPath);
        done("Moved from ${bold(onePath)} (no strong mode fork).");
      } else if (!oneExists) {
        // If it only exists in one place, just move it.
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
        moveFile(strongPath, twoPath);
        done("Moved strong fork, kept 1.0 fork, manual merge required.");
        todos.add("Merge from ${bold(onePath)} into this file.");
        validateFile(onePath, oneSource);
      }
    }

    // See what work is left to be done in the migrated file.
    if (twoExists) {
      validateFile(twoPath, twoSource, todos);
    }

    return todos;
  }
}
