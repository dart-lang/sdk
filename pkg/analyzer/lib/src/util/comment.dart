// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// Return the raw text of the given comment node.
String getCommentNodeRawText(Comment node) {
  if (node == null) return null;

  return node.tokens
      .map((token) => token.lexeme)
      .join('\n')
      .replaceAll('\r\n', '\n');
}

/// Return the plain text from the given DartDoc [rawText], without delimiters.
String getDartDocPlainText(String rawText) {
  if (rawText == null) return null;

  // Remove /** */.
  if (rawText.startsWith('/**')) {
    rawText = rawText.substring(3);
  }
  if (rawText.endsWith('*/')) {
    rawText = rawText.substring(0, rawText.length - 2);
  }
  rawText = rawText.trim();

  // Remove leading '* ' and '/// '.
  var result = StringBuffer();
  var lines = rawText.split('\n');
  for (var line in lines) {
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
    if (result.isNotEmpty) {
      result.write('\n');
    }
    result.write(line);
  }

  return result.toString();
}

/// Return the DartDoc summary, i.e. the portion before the first empty line.
String getDartDocSummary(String completeText) {
  if (completeText == null) return null;

  var result = StringBuffer();
  var lines = completeText.split('\n');
  for (var line in lines) {
    if (result.isNotEmpty) {
      if (line.isEmpty) {
        return result.toString();
      }
      result.write('\n');
    }
    result.write(line);
  }
  return result.toString();
}
