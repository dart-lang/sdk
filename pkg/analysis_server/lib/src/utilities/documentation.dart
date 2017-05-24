// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String getDartDocSummary(String str) {
  if (str == null) {
    return null;
  }
  List<String> lines = str.split('\n');
  StringBuffer sb = new StringBuffer();
  bool firstLine = true;
  for (String line in lines) {
    if (sb.length != 0 && line.isEmpty) {
      return sb.toString();
    }
    if (!firstLine) {
      sb.write('\n');
    }
    firstLine = false;
    sb.write(line);
  }
  return sb.toString();
}

/**
 * Converts [str] from a Dart Doc string with slashes and stars to a plain text
 * representation of the comment.
 */
String removeDartDocDelimiters(String str) {
  if (str == null) {
    return null;
  }
  // remove /** */
  if (str.startsWith('/**')) {
    str = str.substring(3);
  }
  if (str.endsWith("*/")) {
    str = str.substring(0, str.length - 2);
  }
  str = str.trim();
  // remove leading '* ' and '/// '
  List<String> lines = str.split('\n');
  StringBuffer sb = new StringBuffer();
  bool firstLine = true;
  for (String line in lines) {
    line = line.trim();
    if (line.startsWith("*")) {
      line = line.substring(1);
      if (line.startsWith(" ")) {
        line = line.substring(1);
      }
    } else if (line.startsWith("///")) {
      line = line.substring(3);
      if (line.startsWith(" ")) {
        line = line.substring(1);
      }
    }
    if (!firstLine) {
      sb.write('\n');
    }
    firstLine = false;
    sb.write(line);
  }
  str = sb.toString();
  // done
  return str;
}
