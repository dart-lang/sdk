// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:migration/src/io.dart';
import 'package:migration/src/test_directories.dart';

/// Rough estimate of how many lines of code someone could migrate per day.
/// Based on rnystrom migrating corelib_2/r-z, lib_2/js, and lib_2/collection
/// in one day (along with some other tasks).
///
/// This is an optimistic estimate since those were particularly easy libraries.
/// But it's also conservative since it didn't take the entire day to migrate
/// them.
// TODO(rnystrom): Update this with numbers from migrating some language tests.
const _linesPerDay = 24607;

/// Some legacy files test behavior that doesn't apply to NNBD at all which
/// means they don't end up in the migrated directory but are done. We put this
/// comment in the *legacy* file to track that it has been migrated.
const _nonMigratedMarker = "[NNBD non-migrated]";

void main(List<String> arguments) {
  var totalFiles = 0;
  var totalLines = 0;
  var totalMigratedFiles = 0;
  var totalMigratedLines = 0;
  var languageDirs = 0;
  var migratedLanguageDirs = 0;

  var skipCompleteSubfolders = arguments.contains("--incomplete");

  for (var rootDir in legacyRootDirs) {
    var subdirs = Directory(p.join(testRoot, rootDir))
        .listSync()
        .where((subdir) => subdir is Directory)
        .map((subdir) => p.relative(subdir.path, from: testRoot))
        .toList();
    subdirs.add(rootDir);
    subdirs.sort();

    for (var dir in subdirs) {
      var files = 0;
      var lines = 0;
      var migratedFiles = 0;
      var migratedLines = 0;

      for (var legacyPath in listFiles(dir)) {
        files++;
        var sourceLines = readFileLines(legacyPath);
        lines += sourceLines.length;

        var nnbdPath = toNnbdPath(legacyPath);
        if (fileExists(nnbdPath) ||
            sourceLines.any((line) => line.contains(_nonMigratedMarker))) {
          migratedFiles++;
          migratedLines += sourceLines.length;
        }
      }

      if (files == 0) continue;
      if (skipCompleteSubfolders && lines == migratedLines) continue;

      _show(dir, migratedFiles, files, migratedLines, lines);
      totalFiles += files;
      totalLines += lines;
      totalMigratedFiles += migratedFiles;
      totalMigratedLines += migratedLines;

      if (dir.startsWith("language_2/")) {
        languageDirs++;
        if (migratedLines == lines) {
          migratedLanguageDirs++;
        }
      }
    }
  }

  print("");
  _show(
      "total", totalMigratedFiles, totalFiles, totalMigratedLines, totalLines);
  print("");
  print("Finished $migratedLanguageDirs/$languageDirs language directories.");
}

void _show(
    String label, int migratedFiles, int files, int migratedLines, int lines) {
  percent(num n, num max) =>
      (100 * migratedFiles / files).toStringAsFixed(1).padLeft(5);
  pad(Object value, int length) => value.toString().padLeft(length);

  var days = lines / _linesPerDay;
  var migratedDays = migratedLines / _linesPerDay;
  var daysLeft = days - migratedDays;

  var daysLeftString = ", ${pad(daysLeft.toStringAsFixed(2), 6)}/"
      "${pad(days.toStringAsFixed(2), 5)} days left";
  if (migratedLines == 0) {
    daysLeftString = ", ${pad(daysLeft.toStringAsFixed(2), 6)} days left";
  } else if (migratedLines == lines) {
    daysLeftString = "";
  }

  print("${label.padRight(40)} ${pad(migratedFiles, 4)}/${pad(files, 4)} "
      "files (${percent(migratedFiles, files)}%), "
      "${pad(migratedLines, 6)}/${pad(lines, 6)} "
      "lines (${percent(migratedLines, lines)}%)"
      "$daysLeftString");
}
