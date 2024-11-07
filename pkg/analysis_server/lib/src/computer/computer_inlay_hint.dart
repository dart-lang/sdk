// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as path;

/// A computer for LSP Inlay Hints.
///
/// Inlay hints are text labels used to show inferred labels such as type and
/// argument names where they are not already explicitly present in the source
/// but are being inferred.
class DartInlayHintComputer {
  final path.Context pathContext;
  final LineInfo _lineInfo;
  final CompilationUnit _unit;
  final List<InlayHint> _hints = [];

  DartInlayHintComputer(this.pathContext, ResolvedUnitResult result)
    : _unit = result.unit,
      _lineInfo = result.lineInfo;

  List<InlayHint> compute() {
    _unit.accept(_DartInlayHintComputerVisitor(this));
    return _hints;
  }

  /// Adds a parameter name hint before [node] showing a the name for
  /// [parameter].
  ///
  /// If the parameter has no name, no hint will be added.
  ///
  /// A colon and padding will be added between the hint and [node]
  /// automatically.
  void _addParameterNamePrefix(
    SyntacticEntity nodeOrToken,
    ParameterElement parameter,
  ) {
    var name = parameter.name;
    if (name.isEmpty) {
      return;
    }
    var offset = nodeOrToken.offset;
    var position = toPosition(_lineInfo.getLocation(offset));
    var labelParts = Either2<List<InlayHintLabelPart>, String>.t1([
      InlayHintLabelPart(
        value: '$name:',
        location: _locationForElement(parameter),
      ),
    ]);
    _hints.add(
      InlayHint(
        label: labelParts,
        position: position,
        kind: InlayHintKind.Parameter,
        paddingRight: true,
      ),
    );
  }

  /// Adds a type hint for [node] showing a label for type arguments [types].
  ///
  /// Hints will be added before the node unless [suffix] is `true`.
  ///
  /// If [types] is null or empty, no hints are added.
  void _addTypeArguments(
    SyntacticEntity nodeOrToken,
    List<DartType>? types, {
    bool suffix = false,
  }) {
    if (types == null || types.isEmpty) {
      return;
    }

    var offset = suffix ? nodeOrToken.end : nodeOrToken.offset;
    var position = toPosition(_lineInfo.getLocation(offset));
    var labelParts = <InlayHintLabelPart>[];
    _appendTypeArgumentParts(labelParts, types);

    _hints.add(
      InlayHint(
        label: Either2<List<InlayHintLabelPart>, String>.t1(
          labelParts.toList(),
        ),
        position: position,
        kind: InlayHintKind.Type,
      ),
    );
  }

  /// Adds a type hint before [node] showing a label for the type [type].
  ///
  /// Padding will be added between the hint and [node] automatically.
  void _addTypePrefix(SyntacticEntity nodeOrToken, DartType type) {
    var offset = nodeOrToken.offset;
    var position = toPosition(_lineInfo.getLocation(offset));
    var labelParts = <InlayHintLabelPart>[];
    _appendTypePart(labelParts, type);
    _hints.add(
      InlayHint(
        label: Either2<List<InlayHintLabelPart>, String>.t1(labelParts),
        position: position,
        kind: InlayHintKind.Type,
        paddingRight: true,
      ),
    );
  }

  /// Adds labels to [parts] for each element of [type], formatted as
  /// a record type.
  void _appendRecordParts(List<InlayHintLabelPart> parts, RecordType type) {
    parts.add(InlayHintLabelPart(value: '('));

    var positionalFields = type.positionalFields;
    var namedFields = type.namedFields;
    var fieldCount = positionalFields.length + namedFields.length;
    var index = 0;

    for (var field in positionalFields) {
      _appendTypePart(parts, field.type);
      var isLast = index++ == fieldCount - 1;
      if (!isLast) {
        parts.add(InlayHintLabelPart(value: ', '));
      }
    }
    if (namedFields.isNotEmpty) {
      parts.add(InlayHintLabelPart(value: '{'));
      for (var field in namedFields) {
        _appendTypePart(parts, field.type);
        parts.add(InlayHintLabelPart(value: ' ${field.name}'));
        var isLast = index++ == fieldCount - 1;
        if (!isLast) {
          parts.add(InlayHintLabelPart(value: ', '));
        }
      }
      parts.add(InlayHintLabelPart(value: '}'));
    }

    // Add trailing comma for record types with only one position field.
    if (positionalFields.length == 1 && namedFields.isEmpty) {
      parts.add(InlayHintLabelPart(value: ','));
    }

    parts.add(InlayHintLabelPart(value: ')'));
  }

  /// Adds labels to [parts] for each of [types], formatted as type arguments.
  ///
  /// If any of [types] have their own type arguments, will run recursively.
  ///
  /// `<x1, x2, x...>`
  void _appendTypeArgumentParts(
    List<InlayHintLabelPart> parts,
    List<DartType> types,
  ) {
    parts.add(InlayHintLabelPart(value: '<'));
    for (int i = 0; i < types.length; i++) {
      _appendTypePart(parts, types[i]);
      var isLast = i == types.length - 1;
      if (!isLast) {
        parts.add(InlayHintLabelPart(value: ', '));
      }
    }
    parts.add(InlayHintLabelPart(value: '>'));
  }

  /// Adds a label to [parts] for [type].
  ///
  /// If [type] has type arguments, will run recursively.
  void _appendTypePart(List<InlayHintLabelPart> parts, DartType type) {
    if (type is RecordType) {
      _appendRecordParts(parts, type);
    } else {
      parts.add(
        InlayHintLabelPart(
          // Write type without type args or nullability suffix. Type args need
          // adding as their own parts, and the nullability suffix does after them.
          value: type.element?.name ?? type.getDisplayString(),
          location: _locationForElement(type.element),
        ),
      );
      // Call recursively for any nested type arguments.
      if (type is InterfaceType && type.typeArguments.isNotEmpty) {
        _appendTypeArgumentParts(parts, type.typeArguments);
      }
    }
    // Finally add any nullability suffix.
    switch (type.nullabilitySuffix) {
      case NullabilitySuffix.question:
        parts.add(InlayHintLabelPart(value: '?'));
      default:
    }
  }

  Location? _locationForElement(Element? element) {
    if (element == null) {
      return null;
    }
    var compilationUnit =
        element.thisOrAncestorOfType<CompilationUnitElement>();
    var path = compilationUnit?.source.fullName;
    var lineInfo = compilationUnit?.lineInfo;
    if (path == null || lineInfo == null || element.nameOffset == -1) {
      return null;
    }
    return Location(
      uri: pathContext.toUri(path),
      range: toRange(lineInfo, element.nameOffset, element.nameLength),
    );
  }

  /// Adds a Type hint for type arguments of [type] (if it has type arguments).
  void _maybeAddTypeArguments(
    Token token,
    DartType? type, {
    bool suffix = false,
  }) {
    if (type is! ParameterizedType) {
      return;
    }

    var typeArgumentTypes = type.typeArguments;
    if (typeArgumentTypes.isEmpty) {
      return;
    }

    _addTypeArguments(token, typeArgumentTypes, suffix: suffix);
  }
}

/// An AST visitor for [DartInlayHintComputer].
class _DartInlayHintComputerVisitor extends GeneralizingAstVisitor<void> {
  final DartInlayHintComputer _computer;

  _DartInlayHintComputerVisitor(this._computer);

  @override
  void visitArgumentList(ArgumentList node) {
    for (var argument in node.arguments) {
      if (argument is! NamedExpression) {
        var parameter = argument.staticParameterElement;
        if (parameter != null) {
          _computer._addParameterNamePrefix(argument, parameter);
        }
      }
    }

    // Call super last, to ensure parameter names are always added before
    // any other hints that may be produced (such as list literal Type hints).
    super.visitArgumentList(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    super.visitDeclaredIdentifier(node);

    // Has explicit type.
    if (node.type != null) {
      return;
    }

    var declaration = node.declaredElement;
    if (declaration != null) {
      _computer._addTypePrefix(node.name, declaration.type);
    }
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    super.visitDeclaredVariablePattern(node);

    // Has explicit type.
    if (node.type != null) {
      return;
    }

    var declaration = node.declaredElement;
    if (declaration != null) {
      _computer._addTypePrefix(node.name, declaration.type);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);

    // Has explicit type.
    if (node.returnType != null) {
      return;
    }

    // Don't add "void" for setters.
    if (node.isSetter) {
      return;
    }

    var declaration = node.declaredElement;
    if (declaration != null) {
      // For getters/setters, the type must come before the property keyword,
      // not the name.
      var token = node.propertyKeyword ?? node.name;
      _computer._addTypePrefix(token, declaration.returnType);
    }
  }

  @override
  void visitInvocationExpression(InvocationExpression node) {
    super.visitInvocationExpression(node);

    // Has explicit type arguments.
    if (node.typeArguments != null) {
      return;
    }

    _computer._addTypeArguments(
      node.argumentList.leftParenthesis,
      node.typeArgumentTypes,
    );
  }

  @override
  void visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);

    // Has explicit type arguments.
    if (node.typeArguments != null) {
      return;
    }

    var token = node.leftBracket;
    var type = node.staticType;
    _computer._maybeAddTypeArguments(token, type);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);

    // Has explicit type.
    if (node.returnType != null) {
      return;
    }

    var declaration = node.declaredElement;
    if (declaration != null) {
      _computer._addTypePrefix(node.name, declaration.returnType);
    }
  }

  @override
  void visitNamedType(NamedType node) {
    super.visitNamedType(node);

    // Has explicit type arguments.
    if (node.typeArguments != null) {
      return;
    }

    var token = node.endToken;
    var type = node.type;
    _computer._maybeAddTypeArguments(token, type, suffix: true);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    super.visitSetOrMapLiteral(node);

    // Has explicit type arguments.
    if (node.typeArguments != null) {
      return;
    }

    var token = node.leftBracket;
    var type = node.staticType;
    _computer._maybeAddTypeArguments(token, type);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    super.visitSimpleFormalParameter(node);

    // Has explicit type.
    if (node.isExplicitlyTyped) {
      return;
    }

    var declaration = node.declaredElement;
    if (declaration != null) {
      // Prefer to insert before `name` to avoid going before keywords like
      // `required`.
      _computer._addTypePrefix(node.name ?? node, declaration.type);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);

    var parent = node.parent;
    // Unexpected parent or has explicit type.
    if (parent is! VariableDeclarationList || parent.type != null) {
      return;
    }

    var declaration = node.declaredElement;
    if (declaration != null) {
      _computer._addTypePrefix(node, declaration.type);
    }
  }
}
