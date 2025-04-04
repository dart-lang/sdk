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
  /// might point to an element:
  ///   - `0` if the element pointer is `null`;
  ///   - `1` if the element is an import prefix;
  ///   - otherwise `2 + ` the index of the element in [elements].
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
  static const int _importPrefixIndex = 1;

  final Map<Element2, int> map = Map.identity();
  final List<int> elementIndexList = [];

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
  }

  @override
  void visitAnnotation(Annotation node) {
    node.visitChildren(this);
    _addElement(node.element2);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    node.visitChildren(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    _addElement(node.element);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {}

  @override
  void visitConstructorName(ConstructorName node) {
    node.visitChildren(this);
    _addElement(node.element);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    node.visitChildren(this);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {}

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.visitChildren(this);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    node.visitChildren(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {}

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitInterpolationString(InterpolationString node) {}

  @override
  void visitIsExpression(IsExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    node.visitChildren(this);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    node.visitChildren(this);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    node.visitChildren(this);
    _addElement(node.element2);
  }

  @override
  void visitNullLiteral(NullLiteral node) {}

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    _addElement(node.element);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    _addElement(node.element);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.visitChildren(this);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    node.visitChildren(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.visitChildren(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _addElement(node.element);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {}

  @override
  void visitSpreadElement(SpreadElement node) {
    node.visitChildren(this);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.visitChildren(this);
  }

  void _addElement(Element2? element) {
    switch (element) {
      case null:
        elementIndexList.add(_nullIndex);
      case PrefixElement2():
        elementIndexList.add(_importPrefixIndex);
      default:
        var index = map[element] ??= 2 + map.length;
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
