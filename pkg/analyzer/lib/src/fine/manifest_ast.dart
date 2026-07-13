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
import 'package:analyzer/src/utilities/growable_type_data.dart';
import 'package:meta/meta.dart';

@visibleForTesting
enum ManifestAstElementKind {
  null_,
  dynamic_,
  formalParameter,
  importPrefix,
  methodOfUnnamedExtension,
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
    var lengthList = GrowableUint32List();

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
    node.accept2(collector);

    if (collector.isValid) {
      return ManifestNode._(
        isValid: true,
        tokenBuffer: buffer.toString(),
        tokenLengthList: lengthList.takeAndReset(),
        elements: collector.map.keys
            .map((element) => ManifestElement.encode(context, element))
            .toFixedList(),
        elementIndexList: collector.elementIndexList.takeAndReset(),
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

  factory ManifestNode.read(BinaryReader reader) {
    return ManifestNode._(
      isValid: reader.readBool(),
      tokenBuffer: reader.readStringReference(),
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
    node.accept2(collector);

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
    if (!collector.elementIndexList.equalToUint32List(elementIndexList)) {
      return false;
    }

    return true;
  }

  void write(BinaryWriter writer) {
    writer.writeBool(isValid);
    writer.writeStringReference(tokenBuffer);
    writer.writeUint30List(tokenLengthList);
    writer.writeList(elements, (e) => e.write(writer));
    writer.writeUint30List(elementIndexList);
  }

  static List<ManifestNode> readList(BinaryReader reader) {
    return reader.readTypedList(() => ManifestNode.read(reader));
  }

  static List<ManifestNode?> readListOfOptional(BinaryReader reader) {
    return reader.readTypedList(() => ManifestNode.readOptional(reader));
  }

  static ManifestNode? readOptional(BinaryReader reader) {
    return reader.readOptionalObject(() => ManifestNode.read(reader));
  }
}

class _ElementCollector extends GeneralizingAstVisitor2<void> {
  bool isValid = true;
  final int Function(TypeParameterElementImpl) indexOfTypeParameter;
  final int Function(FormalParameterElementImpl) indexOfFormalParameter;
  final List<TypeParameterElement> _localTypeParameters = [];
  final Map<Element, int> map = Map.identity();
  final GrowableUint32List elementIndexList = GrowableUint32List();

  _ElementCollector({
    required this.indexOfTypeParameter,
    required this.indexOfFormalParameter,
  });

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren2(this);
  }

  @override
  void visitAnnotation(Annotation node) {
    node.visitChildren2(this);
    _addElement(node.element);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    node.visitChildren2(this);
  }

  @override
  void visitAsExpression(AsExpression node) {
    node.visitChildren2(this);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    node.visitChildren2(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.visitChildren2(this);
    _addElement(node.element);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {}

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.visitChildren2(this);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    node.visitChildren2(this);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    node.visitChildren2(this);
    _addElement(node.element);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    node.visitChildren2(this);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {}

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.visitChildren2(this);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var localTypeParameters = <TypeParameterElement>[];
    if (node.typeParameters case var typeParameters?) {
      for (var typeParameter in typeParameters.typeParameters) {
        var element = typeParameter.declaredFragment!.element;
        localTypeParameters.add(element);
      }
    }

    _localTypeParameters.addAll(localTypeParameters);
    try {
      node.visitChildren2(this);
    } finally {
      for (var i = 0; i < localTypeParameters.length; i++) {
        _localTypeParameters.removeLast();
      }
    }
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _addElement(node.element);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.visitChildren2(this);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {}

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    node.visitChildren2(this);
  }

  @override
  void visitInterpolationString(InterpolationString node) {}

  @override
  void visitIsExpression(IsExpression node) {
    node.visitChildren2(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    node.visitChildren2(this);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    node.visitChildren2(this);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.element case TopLevelFunctionElement element) {
      if (element.isDartCoreIdentical) {
        node.visitChildren2(this);
        return;
      }
    }
    isValid = false;
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    node.argumentExpression.accept2(this);
  }

  @override
  void visitNamedType(NamedType node) {
    node.visitChildren2(this);
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
    node.visitChildren2(this);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept2(this);
    _addElement(node.element);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    node.visitChildren2(this);
    _addElement(node.element);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.visitChildren2(this);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    node.visitChildren2(this);
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    node.visitChildren2(this);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    node.visitChildren2(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _addElement(node.element);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {}

  @override
  void visitSpreadElement(SpreadElement node) {
    node.visitChildren2(this);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    node.visitChildren2(this);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.visitChildren2(this);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {}

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.visitChildren2(this);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    node.visitChildren2(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    node.visitChildren2(this);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.visitChildren2(this);
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
        var localIndex = _localTypeParameters.lastIndexOf(element);
        if (localIndex != -1) {
          rawIndex = _localTypeParameters.length - 1 - localIndex;
        } else {
          rawIndex =
              _localTypeParameters.length + indexOfTypeParameter(element);
        }
      case PrefixElement():
        kind = ManifestAstElementKind.importPrefix;
        rawIndex = 0;
      default:
        if (element.isMethodOfUnnamedExtension) {
          kind = ManifestAstElementKind.methodOfUnnamedExtension;
          rawIndex = 0;
        } else {
          kind = ManifestAstElementKind.regular;
          rawIndex = map[element] ??= map.length;
        }
    }

    var index = kind.encodeRawIndex(rawIndex);
    elementIndexList.add(index);

    // We resolve `a` in `const b = a;` as a getter. But during constant
    // evaluation we will access the corresponding constant variable for
    // its initializer. So, we also depend on the variable.
    if (kind == ManifestAstElementKind.regular) {
      if (element is GetterElementImpl) {
        _addElement(element.variable);
      }
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

  void writeList(BinaryWriter writer) {
    writer.writeList(this, (x) => x.write(writer));
  }
}

extension ListOfManifestNodeOrNullExtension on List<ManifestNode?> {
  bool match(MatchContext context, List<AstNode?> nodes) {
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

  void writeList(BinaryWriter writer) {
    writer.writeList(this, (node) {
      node.writeOptional(writer);
    });
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

  void writeOptional(BinaryWriter writer) {
    writer.writeOptionalObject(this, (it) => it.write(writer));
  }
}

extension _ElementExtension on Element? {
  bool get isMethodOfUnnamedExtension {
    var self = this;
    return self is ExecutableElement &&
        self.enclosingElement.isUnnamedExtension;
  }

  bool get isUnnamedExtension {
    var self = this;
    return self is ExtensionElement && self.name == null;
  }
}
