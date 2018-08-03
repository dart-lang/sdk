// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Return the summary of the given DartDoc [string], which is the content of the
 * lines before the first blank line.
 */
String getDartDocSummary(String string) {
  if (string == null) {
    return null;
  }
  List<String> lines = string.split('\n');
  StringBuffer buffer = new StringBuffer();
  bool firstLine = true;
  for (String line in lines) {
    if (buffer.length != 0 && line.isEmpty) {
      return buffer.toString();
    }
    if (!firstLine) {
      buffer.write('\n');
    }
    firstLine = false;
    buffer.write(line);
  }
  return buffer.toString();
}

/**
 * Converts [string] from a DartDoc comment with slashes and stars to a plain
 * text representation of the comment.
 */
String removeDartDocDelimiters(String string) {
  if (string == null) {
    return null;
  }
  // remove /** */
  if (string.startsWith('/**')) {
    string = string.substring(3);
  }
  if (string.endsWith('*/')) {
    string = string.substring(0, string.length - 2);
  }
  string = string.trim();
  // remove leading '* ' and '/// '
  List<String> lines = string.split('\n');
  StringBuffer buffer = new StringBuffer();
  bool firstLine = true;
  for (String line in lines) {
    line = line.trim();
    if (line.startsWith('*')) {
      line = line.substring(1);
      if (line.startsWith(' ')) {
        line = line.substring(1);
      }
    } else if (line.startsWith('///')) {
      line = line.substring(3);
      if (line.startsWith(' ')) {
        line = line.substring(1);
      }
    }
    if (!firstLine) {
      buffer.write('\n');
    }
    firstLine = false;
    buffer.write(line);
  }
  string = buffer.toString();
  // done
  return string;
}
