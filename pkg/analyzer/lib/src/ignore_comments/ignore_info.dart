// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/generated/source.dart';

/// Information about analysis `//ignore:` and `//ignore_for_file` comments
/// within a source file.
class IgnoreInfo {
  ///  Instance shared by all cases without matches.
  static final IgnoreInfo _EMPTY_INFO = new IgnoreInfo();

  /// A regular expression for matching 'ignore' comments.  Produces matches
  /// containing 2 groups.  For example:
  ///
  ///     * ['//ignore: error_code', 'error_code']
  ///
  /// Resulting codes may be in a list ('error_code_1,error_code2').
  static final RegExp _IGNORE_MATCHER =
      new RegExp(r'//+[ ]*ignore:(.*)$', multiLine: true);

  /// A regular expression for matching 'ignore_for_file' comments.  Produces
  /// matches containing 2 groups.  For example:
  ///
  ///     * ['//ignore_for_file: error_code', 'error_code']
  ///
  /// Resulting codes may be in a list ('error_code_1,error_code2').
  static final RegExp _IGNORE_FOR_FILE_MATCHER =
      new RegExp(r'//[ ]*ignore_for_file:(.*)$', multiLine: true);

  final Map<int, List<String>> _ignoreMap = new HashMap<int, List<String>>();

  final Set<String> _ignoreForFileSet = new HashSet<String>();

  /// Whether this info object defines any ignores.
  bool get hasIgnores => ignores.isNotEmpty || _ignoreForFileSet.isNotEmpty;

  /// Iterable of error codes ignored for the whole file.
  Iterable<String> get ignoreForFiles => _ignoreForFileSet;

  /// Map of line numbers to associated ignored error codes.
  Map<int, Iterable<String>> get ignores => _ignoreMap;

  /// Ignore this [errorCode] at [line].
  void add(int line, String errorCode) {
    _ignoreMap.putIfAbsent(line, () => new List<String>()).add(errorCode);
  }

  /// Ignore these [errorCodes] at [line].
  void addAll(int line, Iterable<String> errorCodes) {
    _ignoreMap.putIfAbsent(line, () => new List<String>()).addAll(errorCodes);
  }

  /// Ignore these [errorCodes] in the whole file.
  void addAllForFile(Iterable<String> errorCodes) {
    _ignoreForFileSet.addAll(errorCodes);
  }

  /// Test whether this [errorCode] is ignored at the given [line].
  bool ignoredAt(String errorCode, int line) =>
      _ignoreForFileSet.contains(errorCode) ||
      _ignoreMap[line]?.contains(errorCode) == true;

  /// Calculate ignores for the given [content] with line [info].
  static IgnoreInfo calculateIgnores(String content, LineInfo info) {
    Iterable<Match> matches = _IGNORE_MATCHER.allMatches(content);
    Iterable<Match> fileMatches = _IGNORE_FOR_FILE_MATCHER.allMatches(content);
    if (matches.isEmpty && fileMatches.isEmpty) {
      return _EMPTY_INFO;
    }

    IgnoreInfo ignoreInfo = new IgnoreInfo();
    for (Match match in matches) {
      // See _IGNORE_MATCHER for format --- note the possibility of error lists.
      Iterable<String> codes = match
          .group(1)
          .split(',')
          .map((String code) => code.trim().toLowerCase());
      CharacterLocation location = info.getLocation(match.start);
      int lineNumber = location.lineNumber;
      String beforeMatch = content.substring(
          info.getOffsetOfLine(lineNumber - 1),
          info.getOffsetOfLine(lineNumber - 1) + location.columnNumber - 1);

      if (beforeMatch.trim().isEmpty) {
        // The comment is on its own line, so it refers to the next line.
        ignoreInfo.addAll(lineNumber + 1, codes);
      } else {
        // The comment sits next to code, so it refers to its own line.
        ignoreInfo.addAll(lineNumber, codes);
      }
    }
    for (Match match in fileMatches) {
      Iterable<String> codes = match
          .group(1)
          .split(',')
          .map((String code) => code.trim().toLowerCase());
      ignoreInfo.addAllForFile(codes);
    }
    return ignoreInfo;
  }
}
