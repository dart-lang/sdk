// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// Character role in a candidate string.
enum CharRole {
  NONE,
  SEPARATOR,
  TAIL,
  UC_TAIL,
  HEAD,
}

/// A fuzzy matcher that takes a pattern at construction time, and then can
/// evaluate how well various strings match this pattern. Together with a score,
/// it computes a corresponding mapping of pattern characters on the candidate
/// string, which can be retrieved later by calling `getMatchedRanges`.
///
/// A string matches the pattern if every character of the pattern occurs in
/// the string in the same order as in the pattern, and first letters of
/// separate words in pattern are aligned with words in the string. Characters
/// matching the beginning of a word, case-sensitive and just longer matches get
/// higher scores.
///
/// The algorithm takes inspiration from Sublime, VS Code, and IntelliJ and is
/// tuned to produce visually good results for code completion, navigation, and
/// all other kinds of element filtering in the UI.
///
/// Note: if constructed in filename or symbol matching mode, the matcher
/// requires that there is at least some match in the last segment of the path
/// or in the symbol name. In this case, we also prefer reporting sub-matches in
/// the last segment.
///
/// Similar implementations (for reference):
/// - github.com/Microsoft/vscode/blob/master/src/vs/base/common/filters.ts#L439
///
/// Typical usage:
/// ```dart
/// var topN = TopN(100);
/// var matcher = FuzzyMatcher(pattern, FuzzyInput.SYMBOL);
/// for (var item of completionItems) {
///   var score = matcher.score(item.title);
///   if (score > -1) {
///     var matchRanges = matcher.getMatchedRanges();
///     topN.push({item, matchRanges}, score);
///   }
/// }
/// // ... use topN.getTopElements();
/// ```
class FuzzyMatcher {
  /// The maximum size of the input scored against the fuzzy matcher. Longer
  /// inputs will be truncated to this size.
  static const int maxInputSize = 127;

  /// The maximum size of the pattern used to construct the fuzzy matcher.
  /// Longer patterns are truncated to this size.
  static const int maxPatternSize = 63;

  /// The minimum integer score (before normalization).
  static const int minScore = -10000;

  /// Character types for the first 127 ASCII symbols encoded as a string.
  ///
  /// This is:
  ///   [a-z0-9]  LOWER
  ///   [A-Z]     UPPER
  ///   [:./ ]    PUNCT
  ///   otherwise NONE
  static const String TYPES =
      '0000000000000000000000000000000010000000000000112222222222100000'
      '0333333333333333333333333330000002222222222222222222222222200000';

  /// TODO(brianwilkerson) Use package:charcode.
  static final int $a = 'a'.codeUnitAt(0);
  static final int $z = 'z'.codeUnitAt(0);

  /// The (potentially truncated) pattern to be matched.
  String pattern;

  /// The style of match to be performed.
  MatchStyle matchStyle;

  /// The lowercase version of the pattern.
  String patternLower;

  /// The first three characters of the lowercase version of the pattern.
  String patternShort;

  /// The length of the last matched candidate.
  int lastCandidateLen = 0;

  /// A flag indicating whether the last matched candidate matched the pattern.
  bool lastCandidateMatched = false;

  /// MatchStyle.FILENAME only: For the last matched candidate, the length of
  /// text that was trimmed from the start of the string.
  int lastCandidatePrefixTrimmedLen = 0;

  /// Dynamic programming table.
  ///
  /// We use a 3-dimensional dynamic programming table, with the 3-rd dimension
  /// telling us whether the last character matched (true or false). The table
  /// for matched characters is stored adjacent to the table for unmatched
  /// characters to avoid too nested arrays.
  ///
  /// The zero bit of the score value keeps track of where we came from (1 if
  /// the previous character matched, and 0 otherwise).
  List<List<int>> table;

  /// The offset of the "previous symbol matched" table on the pattern axis.
  int matchesLayerOffset;

  /// Pre-allocated memory for storing the role of each character in the
  /// candidate string.
  List<CharRole> candidateRoles = List.filled(maxInputSize, CharRole.NONE);

  /// The role of each character in the pattern.
  List<CharRole> patternRoles;

  /// A flag indicating whether scoring should be case-sensitive. Mix-case
  /// patterns turn on case-sensitive scoring.
  bool caseSensitive;

  /// Normalizes scores for the pattern length.
  double scoreScale;

  /// Initialize a newly created matcher to match the [pattern] using the given
  /// [matchStyle].
  FuzzyMatcher(this.pattern, {this.matchStyle = MatchStyle.TEXT}) {
    if (pattern.length > maxPatternSize) {
      pattern = pattern.substring(0, maxPatternSize);
    }
    patternLower = pattern.toLowerCase();
    caseSensitive = pattern != patternLower;
    if (patternLower.length > 3) {
      patternShort = patternLower.substring(0, 3);
    } else {
      patternShort = patternLower;
    }
    matchesLayerOffset = pattern.length + 1;

    table = [];
    for (var i = 0; i <= maxInputSize; i++) {
      table.add(List.filled(2 * matchesLayerOffset, 0));
    }

    patternRoles = List.filled(pattern.length, CharRole.NONE);
    fuzzyMap(pattern, patternRoles);
    var maxCharScore = matchStyle == MatchStyle.TEXT ? 6 : 4;
    scoreScale =
        pattern.isNotEmpty ? 1.0 / (maxCharScore * pattern.length) : 0.0;
  }

  /// This function picks the matches layer with the best score.
  int bestLayerIndexAt(int i, int j) {
    return scoreAt(i, j, 0) < scoreAt(i, j, 1) ? 1 : 0;
  }

  /// Scores the candidate string.
  ///
  /// Return a non-negative value in case of success, or a negative value if the
  /// candidate does not match or matches poorly.
  int computeScore(String candidate, String candidateLower) {
    for (var j = 0; j <= pattern.length; j++) {
      var mj = matchesLayerOffset + j;
      // We start with zero but only in the layer where the previous character
      // didn't match.
      table[0][j] = j == 0 ? 0 : minScore << 1;
      table[0][mj] = minScore << 1;
    }

    var segmentsLeft = 1;
    var lastSegmentStart = 0;
    for (var i = 0; i < candidate.length; i++) {
      if (candidateRoles[i] == CharRole.SEPARATOR) {
        segmentsLeft++;
        lastSegmentStart = i + 1;
      }
    }

    for (var i = 1; i <= candidate.length; i++) {
      var isHead = candidateRoles[i - 1] == CharRole.HEAD;
      if (candidateRoles[i - 1] == CharRole.SEPARATOR && segmentsLeft > 1) {
        segmentsLeft--;
      }

      // Boost the very last segment.
      var segmentScore = segmentsLeft > 1 ? 0 : 1;

      var skipPenalty = 0;
      // Penalize missing words.
      if (segmentsLeft == 1 && isHead && matchStyle != MatchStyle.TEXT) {
        skipPenalty += 1;
      }
      // Penalize skipping the first letter of a last segment.
      if (i - 1 == lastSegmentStart) {
        skipPenalty += 3;
      }

      for (var j = 0; j <= pattern.length; j++) {
        var mj = matchesLayerOffset + j;

        // By default, we don't have a match. Fill in the skip data.
        table[i][mj] = minScore << 1;
        if (segmentsLeft > 1 && j == pattern.length) {
          // The very last pattern character can only be matched in the last
          // segment.
          table[i][j] = minScore << 1;
          continue;
        }

        // Keep track where we came from.
        var k = bestLayerIndexAt(i - 1, j);
        var skipScore = scoreAt(i - 1, j, k);
        // Do not penalize missing characters after the last matched segment.
        if (j != pattern.length) {
          skipScore -= skipPenalty;
        }

        table[i][j] = (skipScore << 1) + k;

        if (j == 0 ||
            !(candidateLower.codeUnitAt(i - 1) ==
                patternLower.codeUnitAt(j - 1))) {
          // Not a match.
          continue;
        }

        // Score the match.
        var charScore = segmentScore;
        if (candidateRoles[i - 1] == CharRole.TAIL &&
            patternRoles[j - 1] == CharRole.HEAD) {
          if (j > 1) {
            // Not a match: a Head in the pattern matches some tail character.
            continue;
          }
          // Special treatment for the first character of the pattern. We allow
          // matches in the middle of a word if they are long enough, at least
          // min(3, pattern.length) characters.
          if (patternShort !=
              candidateLower.substring(
                  i - 1,
                  math.min(
                      candidateLower.length, i - 1 + patternShort.length))) {
            continue;
          }
          charScore -= 4;
        }

        if ((candidate.codeUnitAt(i - 1) == pattern.codeUnitAt(j - 1)) ||
            (isHead &&
                (!caseSensitive || patternRoles[j - 1] == CharRole.HEAD))) {
          // Case match, or a Head in the pattern aligns with one in the word.
          // Single-case patterns lack segmentation signals and we assume any
          // character can be a head of a segment.
          charScore++;
        }

        // The third dimension tells us if there is a gap between the previous
        // match and the current one.
        for (var k = 0; k < 2; k++) {
          var score = scoreAt(i - 1, j - 1, k) + charScore;
          var prevMatches = k == 1;

          var isConsecutive =
              prevMatches || i - 1 == 0 || i - 1 == lastSegmentStart;
          if (isConsecutive || (matchStyle == MatchStyle.TEXT && j - 1 == 0)) {
            // Bonus for a consecutive match. First character match also gets a
            // bonus to ensure prefix final match score normalizes to 1.0.
            // Logically, this is a part of charScore, but we have to compute it
            // here because it only applies for consecutive matches (k == 1).
            score += matchStyle == MatchStyle.TEXT ? 4 : 2;
          }

          if (!prevMatches &&
              (candidateRoles[i - 1] == CharRole.TAIL ||
                  candidateRoles[i - 1] == CharRole.UC_TAIL)) {
            // Match starts in the middle of a word. Penalize for the lack of
            // alignment.
            score -= 3;
          }
          if (score > (table[i][mj] >> 1)) {
            table[i][mj] = (score << 1) + k;
          }
        }
      }
    }

    return scoreAt(candidate.length, pattern.length,
        bestLayerIndexAt(candidate.length, pattern.length));
  }

  /// Identify the role of each character in the given [string] for fuzzy
  /// matching. The roles are stored in the list of [roles].
  void fuzzyMap(String string, List<CharRole> roles) {
    assert(roles.length >= string.length);
    var prev = _CharType.NONE;
    for (var i = 0; i < string.length; i++) {
      var ch = string.codeUnitAt(i);
      var type = ch < 128
          ? _CharType.values[TYPES.codeUnitAt(ch) - 48]
          : _CharType.LOWER;
      var role = CharRole.NONE;
      if (type == _CharType.LOWER) {
        role = (prev.index <= _CharType.PUNCT.index)
            ? CharRole.HEAD
            : CharRole.TAIL;
      } else if (type == _CharType.UPPER) {
        role = CharRole.HEAD;
        // Note: this treats RPCTest as two words.
        if (prev == _CharType.UPPER &&
            !(i + 1 < string.length &&
                string.codeUnitAt(i + 1) >= $a &&
                string.codeUnitAt(i + 1) <= $z)) {
          role = CharRole.UC_TAIL;
        }
      } else if (type == _CharType.PUNCT) {
        if (matchStyle == MatchStyle.FILENAME && string[i] == '/' ||
            matchStyle == MatchStyle.SYMBOL &&
                (string[i] == '.' || string[i] == ':' || string[i] == ' ')) {
          role = CharRole.SEPARATOR;
        }
      }
      roles[i] = role;
      prev = type;
    }
    for (var i = string.length - 1;
        i >= 0 && roles[i] == CharRole.SEPARATOR;
        i--) {
      roles[i] = CharRole.NONE;
    }
  }

  /// Returns matched ranges for the last scored string as a flattened array of
  /// [begin, end) pairs, where the start and end of each range aer consecutive
  /// elements in the list.
  List<int> getMatchedRanges() {
    if (pattern.isEmpty || !lastCandidateMatched) {
      return [];
    }
    var i = lastCandidateLen;
    var j = pattern.length;
    if (scoreAt(i, j, 0) < minScore / 2 && scoreAt(i, j, 1) < minScore / 2) {
      return [];
    }

    var result = <int>[];
    var k = bestLayerIndexAt(i, j); // bestK in go
    while (i > 0) {
      var take = k == 1;
      k = prevK(i, j, k);
      if (take) {
        if (result.isEmpty || result[result.length - 1] != i) {
          result.add(lastCandidatePrefixTrimmedLen + i);
          result.add(lastCandidatePrefixTrimmedLen + i - 1);
        } else {
          result[result.length - 1] = lastCandidatePrefixTrimmedLen + i - 1;
        }
        j--;
      }
      i--;
    }
    return result.reversed.toList();
  }

  /// A match is poor if it has more than one short sub-match that is not
  /// aligned at a word boundary.
  bool isPoorMatch() {
    if (pattern.length < 2) {
      return false;
    }
    var i = lastCandidateLen;
    var j = pattern.length;
    var k = bestLayerIndexAt(i, j);
    var counter = 0;
    var len = 0;
    while (i > 0) {
      var take = k == 1;
      k = prevK(i, j, k);
      if (take) {
        len++;
        if (k == 0 && len < 3 && candidateRoles[i - 1] == CharRole.TAIL) {
          // Short match in the middle of a word.
          counter++;
          if (counter > 1) {
            return true;
          }
        }
        j--;
      } else {
        len = 0;
      }
      i--;
    }
    return false;
  }

  /// Return `true` if the [candidate] matches the pattern at all.
  bool match(String candidate, String candidateLower) {
    var i = 0;
    var j = 0;
    for (; i < candidateLower.length && j < patternLower.length; i++) {
      if (candidateLower.codeUnitAt(i) == patternLower.codeUnitAt(j)) {
        j++;
      }
    }
    if (j != patternLower.length) {
      return false;
    }

    // The input passes the simple test against pattern, so it is time to
    // classify its characters. Character roles are used below to find the last
    // segment.
    fuzzyMap(candidate, candidateRoles);
    if (matchStyle != MatchStyle.TEXT) {
      var sep = candidateLower.length - 1;
      while (sep >= i && candidateRoles[sep] != CharRole.SEPARATOR) {
        sep--;
      }
      if (sep >= i) {
        // We are not in the last segment, check that we have at least one
        // character match in the last segment of the candidate.
        return candidateLower.contains(
            patternLower.substring(patternLower.length - 1), sep);
      }
    }
    return true;
  }

  /// Returns the previous value for the third dimension.
  int prevK(int i, int j, int k) {
    return table[i][j + k * matchesLayerOffset] & 1;
  }

  /// Computes the fuzzy score of how well the [candidate] matches the pattern,
  /// and returns a value in the range of [0, 1] for matching strings, and -1
  /// for non-matching ones.
  double score(String candidate) {
    lastCandidatePrefixTrimmedLen = 0;
    if (candidate.length > maxInputSize) {
      if (matchStyle == MatchStyle.FILENAME) {
        lastCandidatePrefixTrimmedLen = candidate.length - maxInputSize;
        candidate = candidate.substring(lastCandidatePrefixTrimmedLen);
      } else {
        candidate = candidate.substring(0, maxInputSize);
      }
    }
    if (pattern.isEmpty) {
      // Empty patterns perfectly match candidates.
      return 1.0;
    }
    lastCandidateLen = candidate.length;
    var candidateLower = candidate.toLowerCase();
    if (match(candidate, candidateLower)) {
      var score = computeScore(candidate, candidateLower);
      if (score > minScore / 2 && !isPoorMatch()) {
        lastCandidateMatched = true;
        if (pattern.length == candidate.length) {
          // Exact matches are always perfect.
          return 1.0;
        }
        if (score < 0) {
          score = 0;
        }
        var normalizedScore = score * scoreScale;
        if (normalizedScore > 1) {
          return 1.0;
        }
        return normalizedScore;
      }
    }

    // Make sure subsequent calls to getMatchedRanges() return an empty list.
    lastCandidateMatched = false;
    return -1.0;
  }

  /// Returns the pre-computed score for a given cell.
  int scoreAt(int i, int j, int k) {
    return table[i][j + k * matchesLayerOffset] >> 1;
  }

  void setInput(MatchStyle style) {
    if (matchStyle == style) {
      return;
    }
    matchStyle = style;
    fuzzyMap(pattern, patternRoles);
  }
}

/// The type of strings to match against. For files and symbols, FuzzyMatcher
/// ensures that the match touches the last segment of the candidate string.
enum MatchStyle {
  /// An arbitrary string such as a menu title.
  TEXT,

  /// A path that uses forward slashes for segment separation.
  FILENAME,

  /// A qualified symbol name.
  SYMBOL,
}

enum _CharType { NONE, PUNCT, LOWER, UPPER }
