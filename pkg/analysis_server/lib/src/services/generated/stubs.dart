// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library service.correction.stubs;

import 'package:analyzer/src/generated/ast.dart' show AstNode;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';


abstract class SearchFilter {
  bool passes(SearchMatch match);
}

class SearchMatch {
  final Element element = null;
  final SourceRange sourceRange = null;
}


class SearchEngine {
}


class SourceRangeFactory {
  static SourceRange rangeElementName(Element element) {
    return new SourceRange(element.nameOffset, element.name.length);
  }

  static SourceRange rangeEndEnd(a, b) {
    int offset = a.end;
    var length = b.end - offset;
    return new SourceRange(offset, length);
  }

  static SourceRange rangeEndLength(a, int length) {
    return new SourceRange(a.nameOffset, length);
  }

  static SourceRange rangeEndStart(a, b) {
    int offset = a.end;
    var length = b.offset - offset;
    return new SourceRange(offset, length);
  }

  static SourceRange rangeNode(AstNode node) {
    return new SourceRange(node.offset, node.length);
  }

  static SourceRange rangeNodes(List<AstNode> nodes) {
    if (nodes.isEmpty) {
      return new SourceRange(0, 0);
    }
    AstNode first = nodes.first;
    AstNode last = nodes.last;
    return rangeStartEnd(first, last);
  }

  static SourceRange rangeStartEnd(a, b) {
    int offset = a.offset;
    var length = b.end - offset;
    return new SourceRange(offset, length);
  }

  static SourceRange rangeStartLength(a, int length) {
    int offset = a.offset;
    return new SourceRange(offset, length);
  }

  static SourceRange rangeStartStart(a, b) {
    int offset = a.offset;
    var length = b.offset - offset;
    return new SourceRange(offset, length);
  }

  static SourceRange rangeToken(Token node) {
    return new SourceRange(node.offset, node.length);
  }
}


class StringUtils {
  static String capitalize(String str) {
    if (isEmpty(str)) {
      return str;
    }
    return str.substring(0, 1).toUpperCase() + str.substring(1);
  }

  static bool equals(String cs1, String cs2) {
    if (cs1 == cs2) {
      return true;
    }
    if (cs1 == null || cs2 == null) {
      return false;
    }
    return cs1 == cs2;
  }

  static bool isEmpty(String str) {
    return str == null || str.isEmpty;
  }

  static String join(Iterable iter, [String separator = ' ', int start = 0, int
      end = -1]) {
    if (start != 0) {
      iter = iter.skip(start);
    }
    if (end != -1) {
      iter = iter.take(end - start);
    }
    return iter.join(separator);
  }

  static String remove(String str, String remove) {
    if (isEmpty(str) || isEmpty(remove)) {
      return str;
    }
    return str.replaceAll(remove, '');
  }

  static String removeStart(String str, String remove) {
    if (isEmpty(str) || isEmpty(remove)) {
      return str;
    }
    if (str.startsWith(remove)) {
      return str.substring(remove.length);
    }
    return str;
  }

  static String repeat(String s, int n) {
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < n; i++) {
      sb.write(s);
    }
    return sb.toString();
  }

  static List<String> split(String s, [String pattern = '']) {
    return s.split(pattern);
  }

  static List<String> splitByWholeSeparatorPreserveAllTokens(String s, String
      pattern) {
    return s.split(pattern);
  }
}
