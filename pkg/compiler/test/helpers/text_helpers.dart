// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Compares [text1] and [text2] line-by-line. If a mismatch is found, a diff
/// of the [windowSize] lines before and after are printed and the mismatch line
/// number is returned. If identical, nothing is printed and `null` is returned.
int checkEqualContentAndShowDiff(String text1, String text2,
    {int windowSize: 20,
    bool Function(int, List<String>, List<String>) filter}) {
  List<String> lines1 = text1.split('\n');
  List<String> lines2 = text2.split('\n');
  for (int i = 0; i < lines1.length && i < lines2.length; i++) {
    if (i >= lines1.length || i >= lines2.length || lines1[i] != lines2[i]) {
      if (filter != null && filter(i, lines1, lines2)) {
        String line1 = 0 <= i && i < lines1.length ? lines1[i] : null;
        String line2 = 0 <= i && i < lines2.length ? lines2[i] : null;
        String text = line1 == null ? '<eof>' : line1;
        String newText = line2 == null ? '<eof>' : line2;
        print('(skipped) - $i ${text}');
        print('(skipped) + $i ${newText}');
      } else {
        List<String> pendingLines = <String>[];

        void flushPendingLines() {
          if (pendingLines.isNotEmpty) {
            print(pendingLines.join('\n'));
            pendingLines.clear();
          }
        }

        for (int j = i - windowSize; j < i + windowSize; j++) {
          if (j < 0) continue;
          String line1 = 0 <= j && j < lines1.length ? lines1[j] : null;
          String line2 = 0 <= j && j < lines2.length ? lines2[j] : null;
          if (line1 == line2) {
            flushPendingLines();
            if (line1 != null) {
              print('  $j $line1');
            }
          } else {
            String text = line1 == null ? '<eof>' : line1;
            String newText = line2 == null ? '<eof>' : line2;

            if (text.length > 80 && newText.length > 80) {
              flushPendingLines();
              print('- $j ${text}');
              print('+ $j ${newText}');
              assert(text != newText);
              StringBuffer diff = new StringBuffer();
              diff.write('  $j ');
              for (int k = 0; k < text.length && k < newText.length; k++) {
                int char1 = k < text.length ? text.codeUnitAt(k) : null;
                int char2 = k < newText.length ? newText.codeUnitAt(k) : null;
                if (char1 != char2) {
                  diff.write('^');
                } else {
                  diff.write(' ');
                }
              }
              print(diff);
            } else {
              print('- $j ${text}');
              pendingLines.add('+ $j ${newText}');
            }
          }
        }
        flushPendingLines();
        return i;
      }
    }
  }
  return null;
}
