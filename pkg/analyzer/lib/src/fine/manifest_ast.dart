// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:collection/collection.dart';

/// Enough information to decide if the node is the same.
///
/// We don't store ASTs, instead we rely on the fact that the same tokens
/// are parsed into the same AST (when the same language features, which is
/// ensured outside).
///
/// In addition we record all referenced elements.
class ManifestNode {
  /// The concatenated lexemes of all tokens.
  final String tokenBuffer;

  /// The length of each token in [tokenBuffer].
  final Uint32List tokenLengthList;

  /// All unique elements referenced by this node.
  final List<ManifestElement> elements;

  /// For each property in the AST structure summarized by this manifest that
  /// might point to an element, `0` if the element pointer is `null`; otherwise
  /// one plus the index of the associated manifest element in [elements].
  ///
  /// The order of this list reflects the AST structure, according to the
  /// behavior of [_ElementCollector].
  final Uint32List elementIndexList;

  factory ManifestNode.encode(EncodeContext context, AstNode node) {
    var buffer = StringBuffer();
    var lengthList = <int>[];

    var token = node.beginToken;
    while (true) {
      buffer.write(token.lexeme);
      lengthList.add(token.lexeme.length);
      if (token == node.endToken) {
        break;
      }
      token = token.next ?? (throw StateError('endToken not found'));
    }

    var collector = _ElementCollector();
    node.accept(collector);

    return ManifestNode._(
      tokenBuffer: buffer.toString(),
      tokenLengthList: Uint32List.fromList(lengthList),
      elements: collector.map.keys
          .map((element) => ManifestElement.encode(context, element))
          .toFixedList(),
      elementIndexList: Uint32List.fromList(collector.elementIndexList),
    );
  }

  factory ManifestNode.read(SummaryDataReader reader) {
    return ManifestNode._(
      tokenBuffer: reader.readStringUtf8(),
      tokenLengthList: reader.readUInt30List(),
      elements: ManifestElement.readList(reader),
      elementIndexList: reader.readUInt30List(),
    );
  }

  ManifestNode._({
    required this.tokenBuffer,
    required this.tokenLengthList,
    required this.elements,
    required this.elementIndexList,
  });

  bool match(MatchContext context, AstNode node) {
    var tokenIndex = 0;
    var tokenOffset = 0;
    var token = node.beginToken;
    while (true) {
      var tokenLength = token.lexeme.length;
      if (tokenLengthList[tokenIndex++] != tokenLength) {
        return false;
      }

      if (!tokenBuffer.startsWith(token.lexeme, tokenOffset)) {
        return false;
      }
      tokenOffset += tokenLength;

      if (token == node.endToken) {
        break;
      }
      token = token.next ?? (throw StateError('endToken not found'));
    }

    var collector = _ElementCollector();
    node.accept(collector);

    // Must reference the same elements.
    if (collector.map.length != elements.length) {
      return false;
    }
    for (var (index, element) in collector.map.keys.indexed) {
      if (!elements[index].match(context, element)) {
        return false;
      }
    }

    // Must reference elements in the same order.
    if (!const ListEquality<int>().equals(
      collector.elementIndexList,
      elementIndexList,
    )) {
      return false;
    }

    return true;
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(tokenBuffer);
    sink.writeUint30List(tokenLengthList);
    sink.writeList(elements, (e) => e.write(sink));
    sink.writeUint30List(elementIndexList);
  }

  static ManifestNode? readOptional(SummaryDataReader reader) {
    return reader.readOptionalObject(() => ManifestNode.read(reader));
  }
}

class _ElementCollector extends ThrowingAstVisitor<void> {
  static const int _nullIndex = 0;

  final Map<Element2, int> map = Map.identity();
  final List<int> elementIndexList = [];

  @override
  void visitAnnotation(Annotation node) {
    // TODO(scheglov): implement visitAnnotation
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand.accept(this);
    _addElement(node.element);
    node.rightOperand.accept(this);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {}

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _addElement(node.element);
  }

  void _addElement(Element2? element) {
    if (element == null) {
      elementIndexList.add(_nullIndex);
    } else {
      var index = map[element] ??= 1 + map.length;
      elementIndexList.add(index);
    }
  }
}

extension ManifestNodeOrNullExtension on ManifestNode? {
  bool match(MatchContext context, AstNode? node) {
    var self = this;
    if (self != null && node != null) {
      return self.match(context, node);
    } else {
      return self == null && node == null;
    }
  }

  void writeOptional(BufferedSink sink) {
    sink.writeOptionalObject(this, (it) => it.write(sink));
  }
}
