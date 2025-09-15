// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@visibleForTesting
enum ManifestAstElementKind {
  null_,
  dynamic_,
  formalParameter,
  importPrefix,
  never_,
  typeParameter,
  regular,
  multiplyDefined;

  static final _bitCount = values.length.bitLength;
  static final _bitMask = (1 << _bitCount) - 1;

  int encodeRawIndex(int rawIndex) {
    assert(rawIndex < (1 << 16));
    return (rawIndex << _bitCount) | index;
  }

  static (ManifestAstElementKind, int) decode(int index) {
    var kindIndex = index & _bitMask;
    var kind = ManifestAstElementKind.values[kindIndex];
    var rawIndex = index >> _bitCount;
    return (kind, rawIndex);
  }
}

/// Enough information to decide if the node is the same.
///
/// We used it to store information AST nodes exposed through the element
/// model: constant initializers, constructor initializers, and annotations.
///
/// We don't store ASTs, instead we rely on the fact that the same tokens
/// are parsed into the same AST (when the same language features, which is
/// ensured outside).
///
/// In addition we record all referenced elements.
class ManifestNode {
  /// Whether the encoded AST node has only nodes that we support.
  final bool isValid;

  /// The concatenated lexemes of all tokens.
  final String tokenBuffer;

  /// The length of each token in [tokenBuffer].
  final Uint32List tokenLengthList;

  /// All unique elements referenced by this node.
  final List<ManifestElement> elements;

  /// For each property in the AST structure summarized by this manifest that
  /// might point to an element, [ManifestAstElementKind.encodeRawIndex]
  /// produces the corresponding value.
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

    var collector = _ElementCollector(
      indexOfTypeParameter: context.indexOfTypeParameter,
      indexOfFormalParameter: context.indexOfFormalParameter,
    );
    node.accept(collector);

    if (collector.isValid) {
      return ManifestNode._(
        isValid: true,
        tokenBuffer: buffer.toString(),
        tokenLengthList: Uint32List.fromList(lengthList),
        elements: collector.map.keys
            .map((element) => ManifestElement.encode(context, element))
            .toFixedList(),
        elementIndexList: Uint32List.fromList(collector.elementIndexList),
      );
    } else {
      return ManifestNode._(
        isValid: false,
        tokenBuffer: '',
        tokenLengthList: Uint32List(0),
        elements: const [],
        elementIndexList: Uint32List(0),
      );
    }
  }

  factory ManifestNode.read(SummaryDataReader reader) {
    return ManifestNode._(
      isValid: reader.readBool(),
      tokenBuffer: reader.readStringUtf8(),
      tokenLengthList: reader.readUint30List(),
      elements: ManifestElement.readList(reader),
      elementIndexList: reader.readUint30List(),
    );
  }

  ManifestNode._({
    required this.isValid,
    required this.tokenBuffer,
    required this.tokenLengthList,
    required this.elements,
    required this.elementIndexList,
  });

  bool match(MatchContext context, AstNode node) {
    if (!isValid) {
      return false;
    }

    var tokenIndex = 0;
    var tokenOffset = 0;
    var token = node.beginToken;
    while (true) {
      if (tokenIndex >= tokenLengthList.length) {
        return false;
      }

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

    if (tokenIndex != tokenLengthList.length) {
      return false;
    }

    var collector = _ElementCollector(
      indexOfTypeParameter: context.indexOfTypeParameter,
      indexOfFormalParameter: context.indexOfFormalParameter,
    );
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
    sink.writeBool(isValid);
    sink.writeStringUtf8(tokenBuffer);
    sink.writeUint30List(tokenLengthList);
    sink.writeList(elements, (e) => e.write(sink));
    sink.writeUint30List(elementIndexList);
  }

  static List<ManifestNode> readList(SummaryDataReader reader) {
    return reader.readTypedList(() => ManifestNode.read(reader));
  }

  static ManifestNode? readOptional(SummaryDataReader reader) {
    return reader.readOptionalObject(() => ManifestNode.read(reader));
  }
}

class _ElementCollector extends GeneralizingAstVisitor<void> {
  bool isValid = true;
  final int Function(TypeParameterElementImpl) indexOfTypeParameter;
  final int Function(FormalParameterElementImpl) indexOfFormalParameter;
  final Map<Element, int> map = Map.identity();
  final List<int> elementIndexList = [];

  _ElementCollector({
    required this.indexOfTypeParameter,
    required this.indexOfFormalParameter,
  });

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
  }

  @override
  void visitAnnotation(Annotation node) {
    node.visitChildren(this);
    _addElement(node.element);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    node.visitChildren(this);
  }

  @override
  void visitAsExpression(AsExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
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
  void visitConditionalExpression(ConditionalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    node.visitChildren(this);
  }

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
  void visitImportPrefixReference(ImportPrefixReference node) {
    _addElement(node.element);
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
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.element case TopLevelFunctionElement element) {
      if (element.isDartCoreIdentical) {
        node.visitChildren(this);
        return;
      }
    }
    isValid = false;
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitNamedType(NamedType node) {
    node.visitChildren(this);
    _addElement(node.element);
  }

  @override
  void visitNode(AstNode node) {
    isValid = false;
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
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
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
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.visitChildren(this);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {}

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.visitChildren(this);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    node.visitChildren(this);
  }

  void _addElement(Element? element) {
    ManifestAstElementKind kind;
    int rawIndex;
    switch (element) {
      case null:
        kind = ManifestAstElementKind.null_;
        rawIndex = 0;
      case DynamicElementImpl():
        kind = ManifestAstElementKind.dynamic_;
        rawIndex = 0;
      case NeverElementImpl():
        kind = ManifestAstElementKind.never_;
        rawIndex = 0;
      case MultiplyDefinedElementImpl():
        kind = ManifestAstElementKind.multiplyDefined;
        rawIndex = 0;
      case FormalParameterElementImpl():
        kind = ManifestAstElementKind.formalParameter;
        rawIndex = indexOfFormalParameter(element);
      case TypeParameterElementImpl():
        kind = ManifestAstElementKind.typeParameter;
        rawIndex = indexOfTypeParameter(element);
      case PrefixElement():
        kind = ManifestAstElementKind.importPrefix;
        rawIndex = 0;
      default:
        kind = ManifestAstElementKind.regular;
        rawIndex = map[element] ??= map.length;
    }

    var index = kind.encodeRawIndex(rawIndex);
    elementIndexList.add(index);

    // We resolve `a` in `const b = a;` as a getter. But during constant
    // evaluation we will access the corresponding constant variable for
    // its initializer. So, we also depend on the variable.
    if (element is GetterElementImpl) {
      _addElement(element.variable);
    }
  }
}

extension ListOfManifestNodeExtension on List<ManifestNode> {
  bool match(MatchContext context, List<AstNode> nodes) {
    if (nodes.length != length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (!this[i].match(context, nodes[i])) {
        return false;
      }
    }
    return true;
  }

  void writeList(BufferedSink sink) {
    sink.writeList(this, (x) => x.write(sink));
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
