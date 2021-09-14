// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.12

library dart2js.util.command_line;

/// The accepted escapes in the input of the --batch processor.
///
/// Contrary to Dart strings it does not contain hex escapes (\u or \x).
const Map<String, String> ESCAPE_MAPPING = {
  'n': '\n',
  'r': '\r',
  't': '\t',
  'b': '\b',
  'f': '\f',
  'v': '\v',
  '\\': '\\',
};

/// Splits the [line] similar to how a shell would split arguments. If [windows]
/// is `true` escapes will be handled like on the Windows command-line.
///
/// Example:
///
///     splitLine("""--args "ab"c 'with " \'spaces'""").forEach(print);
///     // --args
///     // abc
///     // with " 'spaces
List<String> splitLine(String line, {bool windows = false}) {
  List<String> result = [];
  bool inQuotes = false;
  String? openingQuote;
  StringBuffer buffer = StringBuffer();
  for (int i = 0; i < line.length; i++) {
    String c = line[i];
    if (inQuotes && c == openingQuote) {
      inQuotes = false;
      continue;
    }
    if (!inQuotes && (c == '"' || (c == "'" && !windows))) {
      inQuotes = true;
      openingQuote = c;
      continue;
    }
    if (c == '\\') {
      if (i == line.length - 1) {
        throw FormatException('Unfinished escape: $line');
      }
      if (windows) {
        String next = line[i + 1];
        if (next == '"' || next == r'\') {
          buffer.write(next);
          i++;
          continue;
        }
      } else {
        i++;

        c = line[i];
        String mapped = ESCAPE_MAPPING[c] ?? c;
        buffer.write(mapped);
        continue;
      }
    }
    if (!inQuotes && c == ' ') {
      if (buffer.isNotEmpty) {
        result.add(buffer.toString());
        buffer.clear();
      }
      continue;
    }
    buffer.write(c);
  }
  if (inQuotes) throw FormatException('Unclosed quotes: $line');
  if (buffer.isNotEmpty) result.add(buffer.toString());
  return result;
}
