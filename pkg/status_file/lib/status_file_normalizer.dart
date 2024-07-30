// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:status_file/src/expression.dart';
import 'package:status_file/status_file_entries_file_checker.dart';

import 'canonical_status_file.dart';
import 'dart:convert';

StatusFile normalizeStatusFile(StatusFile statusFile,
    {required bool deleteNonExisting}) {
  StatusFile newStatusFile = _sortSectionsAndCombine(statusFile);
  for (var section in newStatusFile.sections) {
    if (deleteNonExisting) {
      _deleteNonExistingEntries(statusFile, section);
    }
    _sortEntriesInSection(section);
    _oneLineBetweenSections(section);
  }

  // Remove any empty sections.
  newStatusFile.sections.removeWhere((section) =>
      section.sectionHeaderComments.isEmpty &&
      (section.entries.isEmpty ||
          (section.entries.length == 1 &&
              section.entries.single is EmptyEntry)));

  // Remove empty line at the end of the file
  newStatusFile.sections.last.entries.removeLast();
  return newStatusFile;
}

void _deleteNonExistingEntries(StatusFile file, StatusSection section) {
  Uri statusFileUri = Uri.base.resolveUri(Uri.file(file.path));
  Set<Entry> remove = {};
  for (var entry in section.entries.whereType<StatusEntry>()) {
    if (isNonExistingEntry(statusFileUri, entry)) {
      // Doesn't exist. Remove it.
      remove.add(entry);
    }
  }
  if (remove.isNotEmpty) {
    section.entries.removeWhere(remove.contains);
  }
}

/// Sort section entries alphabetically.
void _sortEntriesInSection(StatusSection section) {
  section.entries.sort((a, b) {
    if (a is CommentEntry) {
      return -1;
    }
    if (b is CommentEntry) {
      return 1;
    }
    if (a is StatusEntry && b is StatusEntry) {
      return a.path.compareTo(b.path);
    }
    if (a is StatusEntry) {
      return -1;
    }
    if (b is StatusEntry) {
      return 1;
    }
    return 0;
  });
}

/// Ensure that there is only one empty line to end a section.
void _oneLineBetweenSections(StatusSection section) {
  section.entries.removeWhere((entry) => entry is EmptyEntry);
  section.entries
      .add(EmptyEntry(section.lineNumber + section.entries.length + 1));
}

StatusFile _sortSectionsAndCombine(StatusFile statusFile) {
  // Create the new status file to be returned.
  StatusFile oldStatusFile = StatusFile.parse(
      statusFile.path, LineSplitter.split(statusFile.toString()).toList());
  List<StatusSection> newSections = [];
  // Copy over all sections and normalize all the expressions.
  for (var section in oldStatusFile.sections) {
    if (section.condition != Expression.always) {
      if (section.isEmpty()) continue;

      newSections.add(StatusSection(section.condition.normalize(),
          section.lineNumber, section.sectionHeaderComments)
        ..entries.addAll(section.entries));
    } else {
      newSections.add(section);
    }
  }

  // Sort the headers
  newSections.sort((a, b) => a.condition.compareTo(b.condition));

  // See if we can combine section headers by simple comparison.
  var newStatusFile = StatusFile(statusFile.path);
  newStatusFile.sections.add(newSections[0]);
  for (var i = 1; i < newSections.length; i++) {
    var previousSection = newSections[i - 1];
    var currentSection = newSections[i];
    if (previousSection.condition.compareTo(currentSection.condition) == 0) {
      newStatusFile.sections.last.entries.addAll(currentSection.entries);
    } else {
      newStatusFile.sections.add(currentSection);
    }
  }
  return newStatusFile;
}
