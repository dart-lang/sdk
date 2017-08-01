// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'environment.dart';
import 'expectation.dart';
import 'src/expression.dart';

/// Matches the header that begins a new section, like:
///
///     [ $compiler == dart2js && $minified ]
final _sectionPattern = new RegExp(r"^\[(.+?)\]");

/// Matches an entry that defines the status for a path in the current section,
/// like:
///
///     some/path/to/some_test: Pass || Fail
final _entryPattern = new RegExp(r"^([^:#]+):(.*)");

/// Matches an issue number in a comment, like:
///
///     blah_test: Fail # Issue 1234
///                       ^^^^
final _issuePattern = new RegExp(r"[Ii]ssue (\d+)");

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
  final String path;
  final List<StatusSection> sections = [];

  StatusFile(this.path);

  /// Parses the status file at [path].
  ///
  /// Throws a [SyntaxError] if the file could not be parsed.
  StatusFile.read(this.path) {
    var lines = new File(path).readAsLinesSync();

    // The current section whose rules are being parsed.
    StatusSection section;

    var lineNumber = 0;

    for (var line in lines) {
      lineNumber++;

      fail(String message, [List<String> errors]) {
        throw new SyntaxError(_shortPath, lineNumber, line, message, errors);
      }

      // Strip off the comment and whitespace.
      var source = line;
      var comment = "";
      var hashIndex = line.indexOf('#');
      if (hashIndex >= 0) {
        source = line.substring(0, hashIndex);
        comment = line.substring(hashIndex);
      }
      source = source.trim();

      // Ignore empty (or comment-only) lines.
      if (source.isEmpty) continue;

      // See if we are starting a new section.
      var match = _sectionPattern.firstMatch(source);
      if (match != null) {
        try {
          var condition = Expression.parse(match[1].trim());
          section = new StatusSection(condition, lineNumber);
          sections.add(section);
        } on FormatException {
          fail("Status expression syntax error");
        }
        continue;
      }

      // Otherwise, it should be a new entry under the current section.
      match = _entryPattern.firstMatch(source);
      if (match != null) {
        var path = match[1].trim();
        // TODO(whesse): Handle test names ending in a wildcard (*).
        var expectations = <Expectation>[];
        for (var name in match[2].split(",")) {
          name = name.trim();
          try {
            expectations.add(Expectation.find(name));
          } on ArgumentError {
            fail('Unrecognized test expectation "$name"');
          }
        }

        var issue = _issueNumber(comment);

        // If we haven't found a section header yet, create an implicit section
        // that matches everything.
        if (section == null) {
          section = new StatusSection(null, -1);
          sections.add(section);
        }

        section.entries
            .add(new StatusEntry(path, lineNumber, expectations, issue));
        continue;
      }

      fail("Unrecognized input");
    }
  }

  bool get isEmpty => sections.isEmpty;

  /// Validates that the variables and values used in all of the section
  /// condition expressions are defined in [environment].
  ///
  /// Throws a [SyntaxError] on the first found error.
  void validate(Environment environment) {
    // TODO(rnystrom): It would be more useful if it reported all of the errors
    // instead of stopping on the first.
    for (var section in sections) {
      if (section.condition == null) continue;

      var errors = <String>[];
      section.condition.validate(environment, errors);

      if (errors.isNotEmpty) {
        var s = errors.length > 1 ? "s" : "";
        throw new SyntaxError(_shortPath, section.lineNumber,
            "[ ${section.condition} ]", 'Validation error$s', errors);
      }
    }
  }

  /// Gets the path to this status file relative to the Dart repo root.
  String get _shortPath {
    var repoRoot = p.join(p.dirname(p.fromUri(Platform.script)), "../../../");
    return p.normalize(p.relative(path, from: repoRoot));
  }

  /// Returns the issue number embedded in [comment] or `null` if there is none.
  int _issueNumber(String comment) {
    var match = _issuePattern.firstMatch(comment);
    if (match == null) return null;

    return int.parse(match[1]);
  }

  String toString() {
    var buffer = new StringBuffer();
    for (var section in sections) {
      buffer.writeln("[ ${section.condition} ]");

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
  final Expression condition;

  /// The one-based line number where the entry appears in the file.
  final int lineNumber;

  final List<StatusEntry> entries = [];

  /// Returns true if this section should apply in the given [environment].
  bool isEnabled(Environment environment) =>
      condition == null || condition.evaluate(environment);

  StatusSection(this.condition, this.lineNumber);
}

/// Describes the test status of the file or files at a given path.
class StatusEntry {
  final String path;

  /// The one-based line number where the entry appears in the file.
  final int lineNumber;

  final List<Expectation> expectations;
  final int issue;

  StatusEntry(this.path, this.lineNumber, this.expectations, this.issue);
}

/// Error thrown when a parse or validation error occurs in a [StatusFile].
class SyntaxError implements Exception {
  final String file;
  final int lineNumber;
  final String line;
  final String message;
  final List<String> errors;

  SyntaxError(this.file, this.lineNumber, this.line, this.message, this.errors);

  String toString() {
    var buffer = new StringBuffer();
    buffer.writeln('$message in "$file" line $lineNumber:');
    buffer.writeln(line);

    if (errors != null) {
      for (var error in errors) {
        buffer.writeln("- ${error.replaceAll('\n', '\n  ')}");
      }
    }

    return buffer.toString().trimRight();
  }
}
