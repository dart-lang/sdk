library levenshtein;

import 'dart:math';

/// Levenshtein algorithm implementation based on:
/// http://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows
///
/// Implementation: https://github.com/conradkleinespel/levenshtein-dart
int getLevenshteinDistance(String s, String t, {bool caseSensitive: true}) {
  if (!caseSensitive) {
    s = s.toLowerCase();
    t = t.toLowerCase();
  }

  if (s == t) {
    return 0;
  }
  if (s.length == 0) {
    return t.length;
  }
  if (t.length == 0) {
    return s.length;
  }

  List<int> v0 = new List<int>.filled(t.length + 1, 0);
  List<int> v1 = new List<int>.filled(t.length + 1, 0);

  for (int i = 0; i < t.length + 1; i < i++) {
    v0[i] = i;
  }

  for (int i = 0; i < s.length; i++) {
    v1[0] = i + 1;

    for (int j = 0; j < t.length; j++) {
      int cost = (s[i] == t[j]) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }

    for (int j = 0; j < t.length + 1; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[t.length];
}
