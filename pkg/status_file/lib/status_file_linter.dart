// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:status_file/canonical_status_file.dart';

class LintingError {
  final int lineNumber;
  final String message;
  LintingError(this.lineNumber, this.message);

  String toString() {
    return "Error at line $lineNumber: $message";
  }
}

/// Main function to check a status file for linting errors.
List<LintingError> lint(StatusFile file, {checkForDisjunctions = false}) {
  var errors = <LintingError>[];
  for (var section in file.sections) {
    errors
      ..addAll(lintCommentLinesInSection(section))
      ..addAll(lintAlphabeticalOrderingOfPaths(section))
      ..addAll(lintNormalizedSection(section))
      ..addAll(lintSectionEntryDuplicates(section));
    if (checkForDisjunctions) {
      errors.addAll(lintDisjunctionsInHeader(section));
    }
  }
  errors.addAll(lintSectionHeaderOrdering(file.sections));
  errors.addAll(lintSectionHeaderDuplicates(file.sections));
  return errors;
}

/// Checks for invalid comment lines in a section.
///
/// We do not allow the following:
///
/// [ ... ]
///
/// vm/test: Skip # description
/// # Some comment <-- invalid
/// ...
///
/// This function checks for such invalid comments.
Iterable<LintingError> lintCommentLinesInSection(StatusSection section) {
  if (section.lineNumber == -1) {
    // This is the default section, which also has the dart copyright notice.
    // Allow comment entries in the beginning of the file, until the first
    // status entry.
    var seenStatusEntry = false;
    var lintingErrors = <LintingError>[];
    for (var entry in section.entries) {
      seenStatusEntry = seenStatusEntry || entry is StatusEntry;
      if (seenStatusEntry && entry is CommentEntry) {
        lintingErrors.add(new LintingError(
            entry.lineNumber, "Comment is on a line by itself."));
      }
    }
    return lintingErrors;
  }
  return section.entries.whereType<CommentEntry>().map((entry) =>
      new LintingError(entry.lineNumber, "Comment is on a line by itself."));
}

/// Checks for disjunctions in headers. Disjunctions should be separated out.
///
/// Example:
/// [ $mode == debug || $mode == release ]
///
/// should not be allowed. The clauses should be refactored into own sections:
/// [ $mode == debug ]
/// ...
///
///
/// [ $mode == release ]
/// ...
///
/// Removing disjunctions will turn some sections into two or more sections with
/// the same status entries, but these will be much easier to process with our
/// tools.
Iterable<LintingError> lintDisjunctionsInHeader(StatusSection section) {
  if (section.condition.toString().contains("||")) {
    return [
      new LintingError(
          section.lineNumber,
          "Expression contains '||'. Please split the expression into multiple "
          "separate sections.")
    ];
  }
  return [];
}

/// Checks for correct ordering of test entries in sections. They should be
/// ordered alphabetically.
Iterable<LintingError> lintAlphabeticalOrderingOfPaths(StatusSection section) {
  var entries = section.entries
      .whereType<StatusEntry>()
      .map((entry) => entry.path)
      .toList();
  var sortedList = entries.toList()..sort((a, b) => a.compareTo(b));
  var witness = _findNotEqualWitness<String>(sortedList, entries);
  if (witness != null) {
    return [
      new LintingError(
          section.lineNumber,
          "Test paths are not alphabetically ordered in section. "
          "${witness.first} should come before ${witness.second}.")
    ];
  }
  return [];
}

/// Checks that each section expression have been normalized.
Iterable<LintingError> lintNormalizedSection(StatusSection section) {
  if (section.condition == null) return const [];
  var nonNormalized = section.condition.toString();
  var normalized = section.condition.normalize().toString();
  if (section.condition.toString() != normalized) {
    return [
      new LintingError(
          section.lineNumber,
          "Condition expression should be '$normalized' "
          "but was '$nonNormalized'.")
    ];
  }
  return const [];
}

/// Checks for duplicate section entries in the body of a section.
Iterable<LintingError> lintSectionEntryDuplicates(StatusSection section) {
  var errors = <LintingError>[];
  List<StatusEntry> statusEntries =
      section.entries.whereType<StatusEntry>().toList();
  for (var i = 0; i < statusEntries.length; i++) {
    var entry = statusEntries[i];
    for (var j = i + 1; j < statusEntries.length; j++) {
      var otherEntry = statusEntries[j];
      if (entry.path == otherEntry.path &&
          _findNotEqualWitness(entry.expectations, otherEntry.expectations) ==
              null) {
        errors.add(new LintingError(
            section.lineNumber,
            "The status entry "
            "'${entry}' is duplicated on lines "
            "${entry.lineNumber} and ${otherEntry.lineNumber}."));
      }
    }
  }
  return errors;
}

/// Checks for incorrect ordering of section headers. Section headers should be
/// alphabetically ordered, except, when negation is used, it should be
/// lexicographically close to the none-negated one, but still come after.
///
/// [ $compiler == dart2js ] < [ $strong ]
/// [ $mode == debug ]       < [ $mode != debug ]
/// [ $strong ]              < [ ! $strong ]
///
/// A larger example could be the following:
///
/// [ $mode != debug ]
/// [ !strong ]
/// [ $mode == debug ]
/// [ strong ]
/// [ $compiler == dart2js ]
///
/// which should should become:
///
/// [ $compiler == dart2js ]
/// [ $mode == debug ]
/// [ $mode != debug ]
/// [ strong ]
/// [ !strong ]
///
Iterable<LintingError> lintSectionHeaderOrdering(List<StatusSection> sections) {
  var unsorted = sections.where((section) => section.lineNumber != -1).toList();
  var sorted = unsorted.toList()
    ..sort((a, b) => a.condition.compareTo(b.condition));
  var witness = _findNotEqualWitness<StatusSection>(sorted, unsorted);
  if (witness != null) {
    return [
      new LintingError(
          witness.second.lineNumber,
          "Section expressions are not correctly ordered in file. "
          "'${witness.first.condition}' on line ${witness.first.lineNumber} "
          "should come before '${witness.second.condition}' at line "
          "${witness.second.lineNumber}.")
    ];
  }
  return [];
}

/// Checks for duplicate section headers.
Iterable<LintingError> lintSectionHeaderDuplicates(
    List<StatusSection> sections) {
  var errors = <LintingError>[];
  var sorted = sections.where((section) => section.condition != null).toList()
    ..sort((a, b) => a.condition.compareTo(b.condition));
  for (var i = 1; i < sorted.length; i++) {
    var section = sorted[i];
    var previousSection = sorted[i - 1];
    if (section.condition != null &&
        previousSection.condition != null &&
        section.condition.compareTo(previousSection.condition) == 0) {
      errors.add(new LintingError(
          section.lineNumber,
          "The condition "
          "'${section.condition}' is duplicated on lines "
          "${previousSection.lineNumber} and ${section.lineNumber}."));
    }
  }
  return errors;
}

ListNotEqualWitness<T> _findNotEqualWitness<T>(List<T> first, List<T> second) {
  if (first.isEmpty && second.isEmpty) {
    return null;
  }
  for (var i = 0; i < math.max(first.length, second.length); i++) {
    if (i >= second.length) {
      return new ListNotEqualWitness(first[i], null);
    } else if (i >= first.length) {
      return new ListNotEqualWitness(null, second[i]);
    } else if (first[i] != second[i]) {
      return new ListNotEqualWitness(first[i], second[i]);
    }
  }
  return null;
}

class ListNotEqualWitness<T> {
  final T first;
  final T second;
  ListNotEqualWitness(this.first, this.second);
}
