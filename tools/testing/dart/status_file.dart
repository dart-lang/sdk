// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'expectation.dart';
import 'status_expression.dart';

/// Splits out a trailing line comment
final _commentPattern = new RegExp("^([^#]*)(#.*)?\$");

/// Matches the header that begins a new section, like:
///
///     [ $compiler == dart2js && $minified ]
final _sectionPattern = new RegExp(r"^\[([^\]]+)\]");

/// Matches an entry that defines the status for a path in the current section,
/// like:
///
///     some/path/to/some_test: Pass || Fail
final _entryPattern = new RegExp(r"\s*([^: ]*)\s*:(.*)");

/// Matches an issue number in a comment, like:
///
///     blah_test: Fail # Issue 1234
///                       ^^^^
final _issuePattern = new RegExp("[Ii]ssue ([0-9]+)");

/// A parsed status file, which describes how a collection of tests are
/// expected to behave under various configurations and conditions.
///
/// Each status file is made of a series of sections. Each section begins with
/// a header, followed by a series of entries. A header is enclosed in square
/// brackets and contains a Boolean expression. That expression is evaluated in
/// an environment. If it evaluates to true, then the entries after the header
/// take effect.
///
/// Each entry is a glob-like file path followed by a colon and then a
/// comma-separated list of [Expectation]s. The path may point to an individual
/// file, or a directory, in which case it applies to all files under that path.
///
/// Entries may also appear before any section header, in which case they
/// always apply.
class StatusFile {
  final List<StatusSection> sections = [];

  /// Parses the status file at [path].
  StatusFile.read(String path) {
    var lines = new File(path).readAsLinesSync();

    // The current section whose rules are being parsed.
    StatusSection section;

    var lineNumber = 0;
    for (var line in lines) {
      lineNumber++;

      // Strip off the comment and whitespace.
      var match = _commentPattern.firstMatch(line);
      var source = "";
      var comment = "";
      if (match != null) {
        source = match[1].trim();
        comment = match[2] ?? "";
      }

      // Ignore empty (or comment-only) lines.
      if (source.isEmpty) continue;

      // See if we are starting a new section.
      match = _sectionPattern.firstMatch(source);
      if (match != null) {
        var condition = Expression.parse(match[1].trim());
        section = new StatusSection(condition);
        sections.add(section);
        continue;
      }

      // Otherwise, it should be a new entry under the current section.
      match = _entryPattern.firstMatch(source);
      if (match != null) {
        var path = match[1].trim();
        // TODO(whesse): Handle test names ending in a wildcard (*).
        var expectations = _parseExpectations(match[2]);
        var issue = _issueNumber(comment);

        // If we haven't found a section header yet, create an implicit section
        // that matches everything.
        if (section == null) {
          section = new StatusSection(null);
          sections.add(section);
        }

        section.entries.add(new StatusEntry(path, expectations, issue));
        continue;
      }

      throw new FormatException(
          "Could not parse line $lineNumber of status file '$path':\n$line");
    }
  }

  /// Parses a comma-separated list of expectation names from [text].
  List<Expectation> _parseExpectations(String text) {
    return text
        .split(",")
        .map((name) => Expectation.find(name.trim()))
        .toList();
  }

  /// Returns the issue number embedded in [comment] or `null` if there is none.
  int _issueNumber(String comment) {
    var match = _issuePattern.firstMatch(comment);
    if (match == null) return null;

    return int.parse(match[1], onError: (_) => null);
  }

  String toString() {
    var buffer = new StringBuffer();
    for (var section in sections) {
      buffer.writeln("[${section._condition}]");

      for (var entry in section.entries) {
        buffer.write("${entry.path}: ${entry.expectations.join(', ')}");
        if (entry.issue != null) buffer.write(" # Issue ${entry.issue}");
        buffer.writeln();
      }

      buffer.writeln();
    }

    return buffer.toString();
  }
}

/// One section in a status file.
///
/// Contains the condition from the header that begins the section, then all of
/// the entries within the section.
class StatusSection {
  /// The expression that determines when this section is applied.
  ///
  /// May be `null` for paths that appear before any section header in the file.
  /// In that case, the section always applies.
  final Expression _condition;
  final List<StatusEntry> entries = [];

  /// Returns true if this section should apply in the given [environment].
  bool isEnabled(Map<String, dynamic> environment) =>
      _condition == null || _condition.evaluate(environment);

  StatusSection(this._condition);
}

/// Describes the test status of the file or files at a given path.
class StatusEntry {
  final String path;
  final List<Expectation> expectations;
  final int issue;

  StatusEntry(this.path, this.expectations, this.issue);
}
