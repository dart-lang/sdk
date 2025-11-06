// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

/// Generates a "focused" unified diff, showing only the changed lines
/// plus a few lines of context around them.
List<String> generateFocusedDiff(
  String expected,
  String actual, {
  int contextLines = 3,
}) {
  var fullDiff = _createDiff(expected, actual);
  var outputLines = <String>[];

  var indicesToInclude = <int>{};

  for (var (i, result) in fullDiff.indexed) {
    if (result.type != _DiffType.common) {
      indicesToInclude.add(i);
      for (
        int j = max(0, i - contextLines);
        j < min(fullDiff.length, i + contextLines + 1);
        j++
      ) {
        indicesToInclude.add(j);
      }
    }
  }

  if (indicesToInclude.isEmpty) {
    return ['No differences found.'];
  }

  int lastIncludedIndex = -1;
  var sortedIndices = indicesToInclude.toList()..sort();

  for (int i in sortedIndices) {
    if (lastIncludedIndex != -1 && i > lastIncludedIndex + 1) {
      outputLines.add('...');
    }

    outputLines.add(_formatLine(fullDiff[i]));
    lastIncludedIndex = i;
  }

  return outputLines;
}

/// Generates a "full" unified diff, showing every line from the comparison.
List<String> generateFullDiff(String expected, String actual) {
  var diffResults = _createDiff(expected, actual);
  return diffResults.map(_formatLine).toList();
}

void printPrettyDiff(String expected, String actual, {int context = 3}) {
  var full = generateFullDiff(expected, actual);
  var short = generateFocusedDiff(expected, actual);

  if (full.length * 0.3 >= short.length) {
    print('-------- Short diff --------');
    print(short.join('\n'));
  }
  print('-------- Full diff ---------');
  print(full.join('\n'));
  print('---------- Actual ----------');
  print(actual.trimRight());
  print('----------------------------');
}

/// Backtracks through the LCS table to build the list of diff results.
List<_DiffResult> _backtrack(
  List<List<int>> table,
  List<String> list1,
  List<String> list2,
) {
  var diff = <_DiffResult>[];
  int i = list1.length;
  int j = list2.length;

  while (i > 0 || j > 0) {
    if (i == 0) {
      diff.add(_DiffResult(_DiffType.added, list2[j - 1]));
      j--;
      continue;
    }
    if (j == 0) {
      diff.add(_DiffResult(_DiffType.removed, list1[i - 1]));
      i--;
      continue;
    }
    if (list1[i - 1] == list2[j - 1]) {
      diff.add(_DiffResult(_DiffType.common, list1[i - 1]));
      i--;
      j--;
    } else if (table[i - 1][j] >= table[i][j - 1]) {
      diff.add(_DiffResult(_DiffType.removed, list1[i - 1]));
      i--;
    } else {
      diff.add(_DiffResult(_DiffType.added, list2[j - 1]));
      j--;
    }
  }

  return diff.reversed.toList();
}

List<List<int>> _computeLcsTable(List<String> list1, List<String> list2) {
  var n = list1.length;
  var m = list2.length;

  var table = List.generate(n + 1, (_) => List.filled(m + 1, 0));

  for (int i = 1; i <= n; i++) {
    for (int j = 1; j <= m; j++) {
      if (list1[i - 1] == list2[j - 1]) {
        table[i][j] = table[i - 1][j - 1] + 1;
      } else {
        table[i][j] = max(table[i - 1][j], table[i][j - 1]);
      }
    }
  }
  return table;
}

/// Returns a line by line difference between [actual] and [expected].
///
/// It uses Longest Common Sequence Algorithm to generate a table
/// (https://en.wikipedia.org/wiki/Longest_common_subsequence)
List<_DiffResult> _createDiff(String expected, String actual) {
  var expectedLines = expected.split('\n');
  var actualLines = actual.split('\n');

  var lcsTable = _computeLcsTable(expectedLines, actualLines);

  return _backtrack(lcsTable, expectedLines, actualLines);
}

String _formatLine(_DiffResult result) {
  switch (result.type) {
    case _DiffType.added:
      return '+ ${result.line}';
    case _DiffType.removed:
      return '- ${result.line}';
    case _DiffType.common:
      return '  ${result.line}';
  }
}

class _DiffResult {
  final _DiffType type;
  final String line;

  _DiffResult(this.type, this.line);
}

enum _DiffType { added, removed, common }
