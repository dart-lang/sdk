// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'canonical_status_file.dart';
import 'dart:convert';

StatusFile normalizeStatusFile(StatusFile statusFile) {
  StatusFile newStatusFile = _sortSectionsAndCombine(statusFile);
  newStatusFile.sections.forEach((section) {
    _sortEntriesInSection(section);
    _oneLineBetweenSections(section);
  });
  // Remove empty line at the end of the file
  newStatusFile.sections.last.entries.removeLast();
  return newStatusFile;
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
      .add(new EmptyEntry(section.lineNumber + section.entries.length + 1));
}

StatusFile _sortSectionsAndCombine(StatusFile statusFile) {
  // Create the new status file to be returned.
  StatusFile oldStatusFile = new StatusFile.parse(
      statusFile.path, LineSplitter.split(statusFile.toString()).toList());
  List<StatusSection> newSections = [];
  // Copy over all sections and normalize all the expressions.
  oldStatusFile.sections.forEach((section) {
    if (section.condition != null && section.isEmpty()) {
      return;
    }
    if (section.condition != null) {
      newSections.add(new StatusSection(section.condition.normalize(),
          section.lineNumber, section.sectionHeaderComments)
        ..entries.addAll(section.entries));
    } else {
      newSections.add(section);
    }
  });
  // Sort the headers
  newSections.sort((a, b) {
    if (a.condition == null) {
      return -1;
    } else if (b.condition == null) {
      return 1;
    }
    return a.condition.compareTo(b.condition);
  });
  // See if we can combine section headers by simple comparison.
  StatusFile newStatusFile = new StatusFile(statusFile.path);
  newStatusFile.sections.add(newSections[0]);
  for (var i = 1; i < newSections.length; i++) {
    var previousSection = newSections[i - 1];
    var currentSection = newSections[i];
    if (previousSection.condition != null &&
        previousSection.condition.compareTo(currentSection.condition) == 0) {
      newStatusFile.sections.last.entries.addAll(currentSection.entries);
    } else {
      newStatusFile.sections.add(currentSection);
    }
  }
  return newStatusFile;
}
