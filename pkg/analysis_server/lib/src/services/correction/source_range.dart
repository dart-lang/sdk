// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
library services.src.correction.source_range_factory;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';

SourceRange rangeElementName(Element element) {
  return new SourceRange(element.nameOffset, element.nameLength);
}

SourceRange rangeEndEnd(a, b) {
  int offset = a.end;
  var length = b.end - offset;
  return new SourceRange(offset, length);
}

SourceRange rangeEndLength(a, int length) {
  int offset = a is int ? a : a.end;
  return new SourceRange(offset, length);
}

SourceRange rangeEndStart(a, b) {
  int offset = a.end;
  var length = (b is int ? b : b.offset) - offset;
  return new SourceRange(offset, length);
}

SourceRange rangeError(AnalysisError error) {
  return new SourceRange(error.offset, error.length);
}

/**
 * Returns the [SourceRange] of [r] with offset from the given [base].
 */
SourceRange rangeFromBase(SourceRange r, int base) {
  int start = r.offset - base;
  int length = r.length;
  return rangeStartLength(start, length);
}

SourceRange rangeNode(AstNode node) {
  return new SourceRange(node.offset, node.length);
}

SourceRange rangeNodes(List<AstNode> nodes) {
  if (nodes.isEmpty) {
    return new SourceRange(0, 0);
  }
  AstNode first = nodes.first;
  AstNode last = nodes.last;
  return rangeStartEnd(first, last);
}

SourceRange rangeOffsetEnd(o) {
  int offset = o.offset;
  int length = o.end - offset;
  return new SourceRange(offset, length);
}

SourceRange rangeStartEnd(a, b) {
  int offset = a is int ? a : a.offset;
  int end = b is int ? b : b.end;
  var length = end - offset;
  return new SourceRange(offset, length);
}

SourceRange rangeStartLength(a, int length) {
  int offset = a is int ? a : a.offset;
  return new SourceRange(offset, length);
}

SourceRange rangeStartStart(a, b) {
  int offset = a is int ? a : a.offset;
  var length = (b is int ? b : b.offset) - offset;
  return new SourceRange(offset, length);
}

SourceRange rangeToken(Token token) {
  return new SourceRange(token.offset, token.length);
}
