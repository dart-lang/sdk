// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9
// @dart = 2.9

void test2() {
  String string = null;
  if (string?.isNotEmpty) ;
}

void main() {
  try {
    test2();
  } catch (e, s) {
    checkFirstLineHasPosition(s);
  }
}

void checkFirstLineHasPosition(StackTrace stackTrace) {
  String firstLine = '$stackTrace'
      .split('\n')
      .firstWhere((String line) => line.startsWith('#0'));
  int lastParen = firstLine.lastIndexOf(')');
  if (lastParen != -1) {
    int secondColon = firstLine.lastIndexOf(':', lastParen - 1);
    if (secondColon != -1) {
      int firstColon = firstLine.lastIndexOf(':', secondColon - 1);
      String lineText = firstLine.substring(firstColon + 1, secondColon);
      String posText = firstLine.substring(secondColon + 1, lastParen);
      int line = int.tryParse(lineText);
      int pos = int.tryParse(posText);
      if (line != null && pos != null) {
        print('Found position $line:$pos');
        return;
      }
    }
  }
  throw 'No position found in "$firstLine"';
}
