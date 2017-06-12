// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * An instance of [RangeFactory] made available for convenience.
 */
final RangeFactory range = new RangeFactory();

/**
 * A factory used to create instances of [SourceRange] based on various
 * syntactic and semantic entities.
 */
class RangeFactory {
  /**
   * Return a source range that covers the name of the given [element].
   */
  SourceRange elementName(Element element) {
    return new SourceRange(element.nameOffset, element.nameLength);
  }

  /**
   * Return a source range that starts at the end of [leftEntity] and ends at
   * the end of [rightEntity].
   */
  SourceRange endEnd(SyntacticEntity leftEntity, SyntacticEntity rightEntity) {
    int offset = leftEntity.end;
    int length = rightEntity.end - offset;
    return new SourceRange(offset, length);
  }

  /**
   * Return a source range that starts at the end of [entity] and has the given
   * [length].
   */
  SourceRange endLength(SyntacticEntity entity, int length) {
    return new SourceRange(entity.end, length);
  }

  /**
   * Return a source range that starts at the end of [leftEntity] and ends at
   * the start of [rightEntity].
   */
  SourceRange endStart(
      SyntacticEntity leftEntity, SyntacticEntity rightEntity) {
    int offset = leftEntity.end;
    int length = rightEntity.offset - offset;
    return new SourceRange(offset, length);
  }

  /**
   * Return a source range that covers the same range as the given [error].
   */
  SourceRange error(AnalysisError error) {
    return new SourceRange(error.offset, error.length);
  }

  /**
   * Return a source range that covers the same range as the given [node].
   */
  SourceRange node(AstNode node) {
    return new SourceRange(node.offset, node.length);
  }

  /**
   * Return a source range that covers all of the given [nodes] (that is, from
   * the start of the first node to the end of the last node.
   */
  SourceRange nodes(List<AstNode> nodes) {
    if (nodes.isEmpty) {
      return new SourceRange(0, 0);
    }
    return startEnd(nodes.first, nodes.last);
  }

  /**
   * Return a source range whose length is the same as the given [range], but
   * whose offset is the offset of the given [range] with [offset] added to it.
   */
  SourceRange offsetBy(SourceRange range, int offset) {
    return new SourceRange(range.offset + offset, range.length);
  }

  /**
   * Return a source range that starts at the start of [leftEntity] and ends at
   * the end of [rightEntity].
   */
  SourceRange startEnd(
      SyntacticEntity leftEntity, SyntacticEntity rightEntity) {
    int offset = leftEntity.offset;
    int length = rightEntity.end - offset;
    return new SourceRange(offset, length);
  }

  /**
   * Return a source range that starts at the start of [entity] and has a length of [length].
   */
  SourceRange startLength(SyntacticEntity entity, int length) {
    return new SourceRange(entity.offset, length);
  }

  /**
   * Return a source range that starts at the given [startOffset] and ends at
   * the given [endOffset].
   */
  SourceRange startOffsetEndOffset(int startOffset, int endOffset) {
    int length = endOffset - startOffset;
    return new SourceRange(startOffset, length);
  }

  /**
   * Return a source range that starts at the start of [leftEntity] and ends at
   * the start of [rightEntity].
   */
  SourceRange startStart(
      SyntacticEntity leftEntity, SyntacticEntity rightEntity) {
    int offset = leftEntity.offset;
    int length = rightEntity.offset - offset;
    return new SourceRange(offset, length);
  }

  /**
   * Return a source range that covers the same range as the given [token].
   */
  SourceRange token(Token token) {
    return new SourceRange(token.offset, token.length);
  }
}
