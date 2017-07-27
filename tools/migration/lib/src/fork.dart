// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'io.dart';
import 'log.dart';
import 'validate.dart';

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

  bool get isMigrated => new File(p.join(testRoot, twoPath)).existsSync();

  String _strongSource;

  Fork(this.twoPath);

  List<String> migrate() {
    print("- ${bold(twoPath)}:");

    var todos = <String>[];

    if (onePath == null && strongPath == null) {
      // It's already been migrated, so there's nothing to move.
      note("Is already migrated.");
    } else if (isMigrated) {
      // If there is a migrated version and it's the same as an unmigrated one,
      // delete the unmigrated one.
      if (onePath != null) {
        if (oneSource == twoSource) {
          deleteFile(onePath);
          done("Deleted already-migrated $onePath.");
        } else {
          note("${bold(onePath)} does not match already-migrated file.");
          todos.add("Merge from ${bold(onePath)} into this file.");
          validateFile(onePath, oneSource);
        }
      }

      if (strongPath != null) {
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
      if (strongPath == null) {
        // If it only exists in one place, just move it.
        moveFile(onePath, twoPath);
        done("Moved from ${bold(onePath)} (no strong mode fork).");
      } else if (onePath == null) {
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
    if (isMigrated) {
      validateFile(twoPath, twoSource, todos);
    }

    return todos;
  }
}
