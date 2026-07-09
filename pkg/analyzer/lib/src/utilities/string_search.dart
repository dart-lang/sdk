// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library contains helper methods and generated methods for effecient
/// string searching using a combination of BMH and KMP.
///
/// Method bodies - including the "magic tables" are generated and will be
/// recreated when the tool
/// `pkg/analyzer/tool/generators/string_search_util_generator.dart`
/// is run.
///
/// With the implementation it can only search for ascii characters and
/// the generator will crash if trying to generate for non-ascii characters.
/// Matching against a string with non-ascii characters is fine.
/// This is not considered a defect, but a tradeoff.
///
/// Adding new things to search for can be done by adding a new class with
/// new static members with an annotation like
/// `@_GeneratedSearchData('myNeedle')`
library;

/// Searches for [needle] in [haystack] starting from [offset].
///
/// Expects [bmhTable] and [kmpTable] to be correctly precomputed const lists.
///
/// This is a combination of Boyer–Moore–Horspool (BMH)
/// (https://en.wikipedia.org/wiki/Boyer%E2%80%93Moore%E2%80%93Horspool_algorithm)
/// and Knuth–Morris–Pratt (KMP)
/// (https://en.wikipedia.org/wiki/Knuth%E2%80%93Morris%E2%80%93Pratt_algorithm)
/// where BMH often has sub-linear performance by skipping (up to) needle-size
/// chunks when the last character doesn't match (but is worse-case O(n*m)) and
/// KMP runs in worst-case O(n) (with n being the length of [haystack] and m
/// being the length of [needle]).
int _combinedBmhAndKmp(
  List<int> bmhTable,
  List<int> kmpTable,
  String haystack,
  String needle,
  int offset,
) {
  int skip = offset;
  int lastNeedleChar = needle.codeUnitAt(needle.length - 1);
  outerLoop:
  while (haystack.length - skip >= needle.length) {
    // BMH: Try to match the last char: If it doesn't match we can skip
    // something.
    int haystackChar = haystack.codeUnitAt(skip + needle.length - 1);
    while (lastNeedleChar != haystackChar) {
      if (haystackChar < bmhTable.length) {
        skip += bmhTable[haystackChar];
      } else {
        skip += needle.length;
      }
      int nextIndex = skip + needle.length - 1;
      if (nextIndex >= haystack.length) return -1;
      haystackChar = haystack.codeUnitAt(nextIndex);
    }

    // Matches on the last char. We switch to KMP.
    int k = 0;
    while (skip < haystack.length) {
      if (needle.codeUnitAt(k) == haystack.codeUnitAt(skip)) {
        skip++;
        k++;
        if (k == needle.length) {
          return skip - k;
        }
      } else {
        k = kmpTable[k];
        if (k < 0) {
          skip++;
          // Here KMP would set k to 0 and thus start over searching from
          // scratch at position skip in haystack. We instead continue with BMH.
          continue outerLoop;
        }
      }
    }
  }
  return -1;
}

class DartdocDirectiveSearchHelper {
  // Don't instantiate.
  DartdocDirectiveSearchHelper._();

  @_GeneratedSearchData('{@endtemplate}', addNeedleLength: true)
  static int nextAtEndtemplate(String haystack, int offset) {
    const String needle = '{@endtemplate}';
    const List<int> bmhTable = [
      // Format hack.
      14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14,
      12, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14,
      14, 14, 14, 14, 14, 14, 14, 14,
      14, 3, 14, 14, 9, 1, 14, 14,
      14, 14, 14, 14, 4, 6, 10, 14,
      5, 14, 14, 14, 2, 14, 14, 14,
      14, 14, 14, 13, 14, 14, 14, 14,
    ];
    const List<int> kmpTable = [
      // Format hack.
      -1, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0,
    ];
    int result = _combinedBmhAndKmp(
      bmhTable,
      kmpTable,
      haystack,
      needle,
      offset,
    );
    if (result >= 0) result += needle.length;
    return result;
  }

  @_GeneratedSearchData('{@template', addNeedleLength: true)
  static int nextAtTemplate(String haystack, int offset) {
    const String needle = '{@template';
    const List<int> bmhTable = [
      // Format hack.
      10, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 10, 10, 10, 10,
      8, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 10, 10, 10, 10,
      10, 10, 10, 10, 10, 10, 10, 10,
      10, 2, 10, 10, 10, 6, 10, 10,
      10, 10, 10, 10, 3, 5, 10, 10,
      4, 10, 10, 10, 1, 10, 10, 10,
      10, 10, 10, 9, 10, 10, 10, 10,
    ];
    const List<int> kmpTable = [
      // Format hack.
      -1, 0, 0, 0, 0, 0, 0, 0,
      0, 0,
    ];
    int result = _combinedBmhAndKmp(
      bmhTable,
      kmpTable,
      haystack,
      needle,
      offset,
    );
    if (result >= 0) result += needle.length;
    return result;
  }
}

class _GeneratedSearchData {
  final String needle;
  final bool addNeedleLength;

  const _GeneratedSearchData(this.needle, {this.addNeedleLength = false});
}
