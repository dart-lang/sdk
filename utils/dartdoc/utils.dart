// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generic utility functions.

/** Invokes [callback] and returns how long it took to execute in ms. */
num time(callback()) {
  final watch = new Stopwatch();
  watch.start();
  callback();
  watch.stop();
  return watch.elapsedInMs();
}

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
  for (start = 0; start < Math.min(indentation, text.length); start++) {
    // Stop if we hit a non-whitespace character.
    if (text[start] != ' ') break;
  }

  return text.substring(start);
}
