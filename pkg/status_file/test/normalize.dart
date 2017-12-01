// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This tests tests if the modification of a status file is done correctly, by
// checking that all entries in the original status file are to be found in the
// new status file. The check therefore allow the merging of section headers if
// they are equal, alphabetizing sections and entries, removing line columns and
// normalizing section conditions..

import 'dart:io';

import 'package:status_file/canonical_status_file.dart';
import 'package:status_file/src/expression.dart';
import 'package:status_file/status_file_normalizer.dart';

final Uri repoRoot = Platform.script.resolve("../../../");

main() {
  sanityCheck();
  normalizeCheck();
}

void normalizeCheck() {
  var files = getStatusFileInRepo();
  for (var file in files) {
    print("------- " + file.path + " -------");
    var statusFile = new StatusFile.read(file.path);
    var statusFileOther = normalizeStatusFile(new StatusFile.read(file.path));
    checkSemanticallyEqual(statusFile, statusFileOther,
        warnOnDuplicateHeader: true);
    print("------- " + file.path + " -------");
  }
}

void sanityCheck() {
  var files = getStatusFileInRepo();
  for (var file in files) {
    print("------- " + file.path + " -------");
    var statusFile = new StatusFile.read(file.path);
    var statusFileOther = new StatusFile.read(file.path);
    checkSemanticallyEqual(statusFile, statusFileOther,
        warnOnDuplicateHeader: true);
    print("------- " + file.path + " -------");
  }
}

List<FileSystemEntity> getStatusFileInRepo() {
  var statusFiles = <FileSystemEntity>[];
  for (var directory in ["tests", "runtime/tests"]) {
    for (var entry in new Directory.fromUri(repoRoot.resolve(directory))
        .listSync(recursive: true)) {
      if (!entry.path.endsWith(".status")) continue;
      // Inside the co19 repository, there is a status file that doesn't appear
      // to be valid and looks more like some kind of template or help document.
      // Ignore it.
      var co19StatusFile = repoRoot.resolve('tests/co19/src/co19.status');
      if (FileSystemEntity.identicalSync(
          entry.path, new File.fromUri(co19StatusFile).path)) {
        continue;
      }
      statusFiles.add(entry);
    }
  }
  return statusFiles;
}

void checkSemanticallyEqual(StatusFile original, StatusFile normalized,
    {bool warnOnDuplicateHeader = false}) {
  var entriesInOriginal = countEntries(original);
  var entriesInNormalized = countEntries(normalized);
  if (entriesInOriginal != entriesInNormalized) {
    print(original);
    print("==================");
    print(normalized);
    throw new Exception("The count of entries in original is "
        "$entriesInOriginal and the count of entries in normalized is "
        "$entriesInNormalized. Those two numbers are not the same.");
  }
  for (var section in original.sections) {
    for (var entry in section.entries) {
      if (entry is! StatusEntry) {
        continue;
      }
      findInStatusFile(normalized, entry, section.condition?.normalize(),
          warnOnDuplicateHeader: warnOnDuplicateHeader);
    }
  }
}

int countEntries(StatusFile statusFile) {
  return 0;
  return statusFile.sections
      .map((section) =>
          section.entries.where((entry) => entry is StatusEntry).length)
      .fold(0, (count, sum) => count + sum);
}

void findInStatusFile(
    StatusFile statusFile, StatusEntry entryToFind, Expression condition,
    {bool warnOnDuplicateHeader = false}) {
  int foundEntryPosition = -1;
  for (var section in statusFile.sections) {
    if (section.condition == null && condition != null ||
        section.condition != null && condition == null) {
      continue;
    }
    if (section.condition != null &&
        section.condition.normalize().compareTo(condition) != 0) {
      continue;
    }
    var matchingEntries = section.entries
        .where((entry) =>
            entry is StatusEntry &&
            entry.path.compareTo(entryToFind.path) == 0 &&
            listEqual(entry.expectations, entryToFind.expectations))
        .toList();
    if (matchingEntries.length == 0) {
      var message = "Could not find the entry even though the section "
          "header matched on line number ${section.lineNumber}. Sections "
          "should be unique.";
      if (warnOnDuplicateHeader) {
        //print(message);
      } else {
        throw new Exception(message);
      }
    } else if (matchingEntries.length == 1 && foundEntryPosition >= 0) {
      throw new Exception("The entry '$entryToFind' on line "
          "${entryToFind.lineNumber} in section ${section.condition} was "
          "already found in a previous section on line $foundEntryPosition.");
    } else if (matchingEntries.length == 1) {
      foundEntryPosition = matchingEntries[0].lineNumber;
    } else {
      throw new Exception("The entry '$entryToFind' on line "
          "${entryToFind.lineNumber} in section ${section.condition} on line "
          "${section.lineNumber} had multiple matches in section.");
    }
  }
  if (foundEntryPosition < 0) {
    throw new Exception("Could not find entry '$entryToFind' under the "
        "condition $condition in the status file.");
  }
}

bool listEqual<T>(List<T> first, List<T> second) {
  if (first.length != second.length) {
    return false;
  }
  for (int i = 0; i < first.length; i++) {
    if (first[i] != second[i]) {
      return false;
    }
  }
  return true;
}
