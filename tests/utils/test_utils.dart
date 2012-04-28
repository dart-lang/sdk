// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('test_utils');

/**
 * Removes eight spaces of leading indentation from a multiline string.
 *
 * Note that this is very sensitive to how the literals are styled. They should
 * be:
 *     '''
 *     Text starts on own line. Lines up with subsequent lines.
 *     Lines are indented exactly 8 characters from the left margin.
 *     Close is on the same line.'''
 *
 * This does nothing if text is only a single line.
 */
// TODO(nweiz): Make this auto-detect the indentation level from the first
// non-whitespace line.
String cleanUpLiteral(String text) {
  var lines = text.split('\n');
  if (lines.length <= 1) return text;

  for (var j = 0; j < lines.length; j++) {
    if (lines[j].length > 8) {
      lines[j] = lines[j].substring(8, lines[j].length);
    } else {
      lines[j] = '';
    }
  }

  return Strings.join(lines, '\n');
}

/**
 * Indents each line of [text] so that, when passed to [cleanUpLiteral], it will
 * produce output identical to [text].
 *
 * This is useful for literals that need to include newlines but can't be
 * conveniently represented as multi-line strings.
 */
// TODO(nweiz): Once cleanUpLiteral is fixed, get rid of this.
String indentLiteral(String text) {
  var lines = text.split('\n');
  if (lines.length <= 1) return text;

  for (var i = 0; i < lines.length; i++) {
    lines[i] = "        ${lines[i]}";
  }

  return Strings.join(lines, "\n");
}
