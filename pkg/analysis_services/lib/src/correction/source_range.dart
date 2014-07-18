// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.src.correction.source_range_factory;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';


SourceRange rangeElementName(Element element) {
  return new SourceRange(element.nameOffset, element.name.length);
}

SourceRange rangeEndEnd(a, b) {
  int offset = a.end;
  var length = b.end - offset;
  return new SourceRange(offset, length);
}

SourceRange rangeEndLength(a, int length) {
  return new SourceRange(a.nameOffset, length);
}

SourceRange rangeEndStart(a, b) {
  int offset = a.end;
  var length = b.offset - offset;
  return new SourceRange(offset, length);
}

SourceRange rangeError(AnalysisError error) {
  return new SourceRange(error.offset, error.length);
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

SourceRange rangeStartEnd(a, b) {
  int offset = a is int ? a : a.offset;
  int end = b is int ? b : b.end;
  var length = end - offset;
  return new SourceRange(offset, length);
}

SourceRange rangeStartLength(a, int length) {
  int offset = a.offset;
  return new SourceRange(offset, length);
}

SourceRange rangeStartStart(a, b) {
  int offset = a.offset;
  var length = b.offset - offset;
  return new SourceRange(offset, length);
}

SourceRange rangeToken(Token node) {
  return new SourceRange(node.offset, node.length);
}
