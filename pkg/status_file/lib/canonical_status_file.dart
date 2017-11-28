// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'environment.dart';
import 'expectation.dart';
import 'status_file.dart';
import 'src/expression.dart';

/// Matches the header that begins a new section, like:
///
///     [ $compiler == dart2js && $minified ]
final RegExp _sectionPattern = new RegExp(r"^\[(.+?)\]");

/// Matches an entry that defines the status for a path in the current section,
/// like:
///
///     some/path/to/some_test: Pass || Fail
final RegExp _entryPattern = new RegExp(r"^([^:#]+):([^#]+)(#.*)?");

/// Matches an issue number in a comment, like:
///
///     blah_test: Fail # Issue 1234
///                       ^^^^
final RegExp _issuePattern = new RegExp(r"[Ii]ssue (\d+)");

/// Matches a comment and indented comment, like:
///
///     < white space > #
final RegExp _commentPattern = new RegExp(r"^(\s*)#");

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
/// comma-separated list of [Expectation]s. The path is a regular expression
/// which may match one or more file or directory paths. If it matches a
/// directory path, it is considered to match all files in that directory or
/// (recursively) its subdirectories.
///
/// The intent is that status files will not have stand-alone comment lines. All
/// comments should be at the end of a single entry, and apply to that entry
/// only.
///
/// Until this is true for all status files, this program handles stand-alone
/// comment lines as follows:
///
/// 1) One or more comment lines immediately preceding a section header if there
/// is a linebreak from the previous section. Comment sections are added
/// directly to a section and are not entries.
/// 2) Comment lines anywhere else. These should be carefully removed when
/// found.
///
/// The reason for this distinction is to allow comments to be above sections,
/// without including these when lexicographically ordering section entries.
///
/// Entries may also appear before any section header, are considered to belong
/// to a default section, which always applies.
class StatusFile {
  final String path;
  final List<StatusSection> sections = [];

  int _lineCount = 0;

  /// Reads and parses the status file at [path].
  ///
  /// Throws a [SyntaxError] if the file could not be parsed.
  StatusFile.read(this.path) {
    _parse(new File(path).readAsLinesSync());
  }

  /// Parses lines of strings coming from a status file at [path].
  ///
  /// Throws a [SyntaxError] if the file could not be parsed.
  StatusFile.parse(this.path, List<String> lines) {
    _parse(lines);
  }

  void _parse(List<String> lines) {
    // We define a few helper functions that are used when parsing.

    /// Checks if [currentLine] is a comment and returns the first regular
    /// expression match, or null otherwise.
    Match commentEntryMatch(int currentLine) {
      if (currentLine < 1 || currentLine > lines.length) {
        return null;
      }
      return _commentPattern.firstMatch(lines[currentLine - 1]);
    }

    /// Finds a section header on [currentLine] if the line is in range of
    /// [lines].
    Match sectionHeaderMatch(int currentLine) {
      if (currentLine < 1 || currentLine > lines.length) {
        return null;
      }
      return _sectionPattern.firstMatch(lines[currentLine - 1]);
    }

    /// Checks if a line has a break from the previous section. A break is an
    /// empty line. It searches recursively until it find a break or a test
    /// entry.
    bool hasBreakFromPreviousSection(int currentLine) {
      if (currentLine <= 1) {
        return true;
      }

      var line = lines[currentLine - 1];
      if (line.isEmpty) {
        return true;
      }

      if (line.startsWith("#")) {
        return hasBreakFromPreviousSection(currentLine - 1);
      }

      return false;
    }

    /// Checks if comment on [currentLine] belongs to the next section.
    bool commentBelongsToNextSectionHeader(int currentLine) {
      if (currentLine >= lines.length ||
          commentEntryMatch(currentLine) == null) {
        return false;
      }
      return sectionHeaderMatch(currentLine + 1) != null ||
          commentBelongsToNextSectionHeader(currentLine + 1);
    }

    // The current section whose rules are being parsed. Initalized to an
    // implicit section that matches everything.
    StatusSection section = new StatusSection(null, -1, []);
    sections.add(section);

    // Placeholder for comments that should be added to a section.
    List<CommentEntry> sectionHeaderComments = [];

    for (var line in lines) {
      _lineCount++;

      fail(String message, [List<String> errors]) {
        throw new SyntaxError(_shortPath, _lineCount, line, message, errors);
      }

      // If it is an empty line
      if (line.trim().isEmpty) {
        section.entries.add(new EmptyEntry(_lineCount));
        continue;
      }

      // See if we are starting a new section.
      var match = _sectionPattern.firstMatch(line);
      if (match != null) {
        try {
          var condition = Expression.parse(match[1].trim());
          section =
              new StatusSection(condition, _lineCount, sectionHeaderComments);
          sections.add(section);
          // Reset section header comments.
          sectionHeaderComments = [];
        } on FormatException {
          fail("Status expression syntax error");
        }
        continue;
      }

      // If it is in a new entry we should add to the current section.
      match = _entryPattern.firstMatch(line);
      if (match != null) {
        var path = match[1].trim();
        var expectations = <Expectation>[];
        // split expectations
        match[2].split(",").forEach((name) {
          try {
            expectations.add(Expectation.find(name.trim()));
          } on ArgumentError {
            fail('Unrecognized test expectation "${name.trim()}"');
          }
        });
        if (match[3] == null) {
          section.entries
              .add(new StatusEntry(path, _lineCount, expectations, null));
        } else {
          section.entries.add(new StatusEntry(
              path, _lineCount, expectations, new Comment(match[3])));
        }
        continue;
      }

      // If it is a comment, we have to find if it belongs with the current
      // section or the next section
      match = _commentPattern.firstMatch(line);
      if (match != null) {
        var commentEntry = new CommentEntry(_lineCount, new Comment(line));
        if (hasBreakFromPreviousSection(_lineCount) &&
            commentBelongsToNextSectionHeader(_lineCount)) {
          sectionHeaderComments.add(commentEntry);
        } else {
          section.entries.add(commentEntry);
        }
        continue;
      }

      fail("Unrecognized input");
    }

    // There are no comment entries in [sectionHeaderComments], because of the
    // check for [commentBelongsToSectionHeader].
    assert(sectionHeaderComments.length == 0);
  }

  bool get isEmpty => sections.length == 1 && sections[0].isEmpty();

  /// Validates that the variables and values used in all of the section
  /// condition expressions are defined in [environment].
  ///
  /// Throws a [SyntaxError] on the first found error.
  void validate(Environment environment) {
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
    var repoRoot = p.fromUri(Platform.script.resolve('../../../'));
    return p.normalize(p.relative(path, from: repoRoot));
  }

  /// Returns the status file as a string. This preserves comments and gives a
  /// "canonical" rendering of the status file that can be saved back to disc.
  String toString() {
    var buffer = new StringBuffer();
    sections.forEach(buffer.write);
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

  /// The one-based line number where the section appears in the file.
  final int lineNumber;

  /// Collection of all comment and status line entries.
  final List<Entry> entries = [];
  final List<CommentEntry> sectionHeaderComments;

  /// Returns true if this section should apply in the given [environment].
  bool isEnabled(Environment environment) =>
      condition == null || condition.evaluate(environment);

  bool isEmpty() => !entries.any((entry) => entry is StatusEntry);

  StatusSection(this.condition, this.lineNumber, this.sectionHeaderComments);

  @override
  String toString() {
    var buffer = new StringBuffer();
    sectionHeaderComments.forEach(buffer.writeln);
    if (condition != null) {
      buffer.writeln("[ ${condition} ]");
    }
    entries.forEach(buffer.writeln);
    return buffer.toString();
  }
}

class Comment {
  final String _comment;

  Comment(this._comment);

  /// Returns the issue number embedded in [comment] or `null` if there is none.
  int issueNumber(String comment) {
    var match = _issuePattern.firstMatch(comment);
    if (match == null) return null;
    return int.parse(match[1]);
  }

  @override
  String toString() {
    return _comment;
  }
}

abstract class Entry {
  /// The one-based line number where the entry appears in the file.
  final int lineNumber;
  Entry(this.lineNumber);
}

class EmptyEntry extends Entry {
  EmptyEntry(lineNumber) : super(lineNumber);

  @override
  String toString() {
    return "";
  }
}

class CommentEntry extends Entry {
  final Comment comment;
  CommentEntry(lineNumber, this.comment) : super(lineNumber);

  @override
  String toString() {
    return comment.toString();
  }
}

/// Describes the test status of the file or files at a given path.
class StatusEntry extends Entry {
  final String path;
  final List<Expectation> expectations;
  final Comment comment;

  StatusEntry(this.path, lineNumber, this.expectations, this.comment)
      : super(lineNumber);

  @override
  String toString() {
    return comment == null
        ? "$path: ${expectations.join(', ')}"
        : "$path: ${expectations.join(', ')} $comment";
  }
}
