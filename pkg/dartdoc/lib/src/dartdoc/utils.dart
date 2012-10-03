// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generic utility functions.

/** Turns [name] into something that's safe to use as a file name. */
String sanitize(String name) => name.replaceAll(':', '_').replaceAll('/', '_');

/** Returns the number of times [search] occurs in [text]. */
int countOccurrences(String text, String search) {
  int start = 0;
  int count = 0;

  while (true) {
    start = text.indexOf(search, start);
    if (start == -1) break;
    count++;
    // Offsetting by search length means overlapping results are not counted.
    start += search.length;
  }

  return count;
}

/** Repeats [text] [count] times, separated by [separator] if given. */
String repeat(String text, int count, [String separator]) {
  // TODO(rnystrom): Should be in corelib.
  final buffer = new StringBuffer();
  for (int i = 0; i < count; i++) {
    buffer.add(text);
    if ((i < count - 1) && (separator !== null)) buffer.add(separator);
  }

  return buffer.toString();
}

/** Removes up to [indentation] leading whitespace characters from [text]. */
String unindent(String text, int indentation) {
  var start;
  for (start = 0; start < min(indentation, text.length); start++) {
    // Stop if we hit a non-whitespace character.
    if (text[start] != ' ') break;
  }

  return text.substring(start);
}

/** Sorts the map by the key, doing a case-insensitive comparison. */
List<Mirror> orderByName(Collection<Mirror> list) {
  final elements = new List<Mirror>.from(list);
  elements.sort((a,b) {
    String aName = a.simpleName.toLowerCase();
    String bName = b.simpleName.toLowerCase();
    bool doma = aName.startsWith(r"$dom");
    bool domb = bName.startsWith(r"$dom");
    return doma == domb ? aName.compareTo(bName) : doma ? 1 : -1;
  });
  return elements;
}

/**
 * Joins [items] into a single, comma-separated string using [conjunction].
 * E.g. `['A', 'B', 'C']` becomes `"A, B, and C"`.
 */
String joinWithCommas(List<String> items, [String conjunction = 'and']) {
  if (items.length == 1) return items[0];
  if (items.length == 2) return "${items[0]} $conjunction ${items[1]}";
  return '${Strings.join(items.getRange(0, items.length - 1), ', ')}'
    ', $conjunction ${items[items.length - 1]}';
}

void writeString(File file, String text) {
  var randomAccessFile = file.openSync(FileMode.WRITE);
  randomAccessFile.writeStringSync(text);
  randomAccessFile.closeSync();
}
