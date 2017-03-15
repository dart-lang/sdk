// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Split [text] using [infixes] as infix markers.
List<String> split(String text, List<String> infixes) {
  List<String> result = <String>[];
  int start = 0;
  for (String infix in infixes) {
    int index = text.indexOf(infix, start);
    if (index == -1)
      throw "'$infix' not found in '$text' from offset ${start}.";
    result.add(text.substring(start, index));
    start = index + infix.length;
  }
  result.add(text.substring(start));
  return result;
}

/// Pad [text] with spaces to the right to fit [length].
String padRight(String text, int length) {
  if (text.length < length) return '${text}${' ' * (length - text.length)}';
  return text;
}

const bool LOG = const bool.fromEnvironment('LOG', defaultValue: false);

void log(String text) {
  if (LOG) print(text);
}
