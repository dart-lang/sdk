// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';

String categorize(StackTrace st) {
  List<StackTraceLine> lines = parseStackTrace(st);
  List<StackTraceLine> notSdk = lines
      .where((l) => l.uri.scheme != "dart")
      .toList();
  return "${notSdk.first.uri.pathSegments.last}/${notSdk.first.line}";
}

List<StackTraceLine> parseStackTrace(StackTrace st) {
  List<StackTraceLine> result = [];
  List<String> lines = st.toString().split("\n");
  for (int i = 0; i < lines.length; i++) {
    String s = lines[i];
    if (s == "") continue;
    if (s == "...") continue;
    if (s == "<asynchronous suspension>") continue;
    if (s.startsWith("#")) {
      int j = 1;
      for (; j < s.length; j++) {
        int c = s.codeUnitAt(j);
        if (c >= $0 && c <= $9) {
          // #numGoesHere
        } else {
          break;
        }
      }
      s = s.substring(j).trim();
      int indexOfParen = s.indexOf("(");
      String method = s.substring(0, indexOfParen).trim();
      if (s[s.length - 1] != ")") throw "s";
      String uriEtc = s.substring(indexOfParen + 1, s.length - 1);
      List<String> colonSplit = uriEtc.split(":");
      int column = -1;
      int line = -1;
      // If last two are numbers it's line and column --- the rest is uri;
      // if last is number it's line --- the rest is uri
      // else its all uri.
      if (uriEtc.length >= 2) {
        column = int.tryParse(colonSplit[colonSplit.length - 1]) ?? -1;
        line = int.tryParse(colonSplit[colonSplit.length - 2]) ?? -1;
      }
      String uriPart;
      if (line > -1 && column > -1) {
        uriPart = colonSplit.take(colonSplit.length - 2).join(":");
      } else if (column > -1) {
        line = column;
        column = -1;
        uriPart = colonSplit.take(colonSplit.length - 1).join(":");
      } else {
        uriPart = uriEtc;
      }
      StackTraceLine stLine = new StackTraceLine(
        method,
        Uri.parse(uriPart),
        line,
        column,
        lines[i],
      );
      result.add(stLine);
    } else {
      throw "Unexpected line: '$s' in stacktrace: $st";
    }
  }

  return result;
}

class StackTraceLine {
  final String method;
  final Uri uri;
  final int line;
  final int column;
  final String orgLine;

  StackTraceLine(this.method, this.uri, this.line, this.column, this.orgLine);
}
