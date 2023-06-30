// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';

/// A computer for LSP Inlay Hints.
///
/// Inlay hints are text labels used to show inferred labels such as type and
/// argument names where they are not already explicitly present in the source
/// but are being inferred.
class DartInlayHintComputer {
  final LineInfo _lineInfo;
  final CompilationUnit _unit;
  final bool _isNonNullableByDefault;
  final List<InlayHint> _hints = [];

  DartInlayHintComputer(ResolvedUnitResult result)
      : _unit = result.unit,
        _lineInfo = result.lineInfo,
        _isNonNullableByDefault = result.unit.isNonNullableByDefault;

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
      SyntacticEntity nodeOrToken, ParameterElement parameter) {
    final name = parameter.name;
    if (name.isEmpty) {
      return;
    }
    final offset = nodeOrToken.offset;
    final position = toPosition(_lineInfo.getLocation(offset));
    final labelParts = Either2<List<InlayHintLabelPart>, String>.t1([
      InlayHintLabelPart(
        value: '$name:',
        location: _locationForElement(parameter),
      ),
    ]);
    _hints.add(InlayHint(
      label: labelParts,
      position: position,
      kind: InlayHintKind.Parameter,
      paddingRight: true,
    ));
  }

  /// Adds a type hint before [node] showing a label for type arguments [types].
  ///
  /// If [types] is null or empty, no hints are added.
  void _addTypeArgumentsPrefix(
      SyntacticEntity nodeOrToken, List<DartType>? types) {
    if (types == null || types.isEmpty) {
      return;
    }

    final offset = nodeOrToken.offset;
    final position = toPosition(_lineInfo.getLocation(offset));
    final labelParts = <InlayHintLabelPart>[];
    _appendTypeArgumentParts(labelParts, types);

    _hints.add(InlayHint(
      label: Either2<List<InlayHintLabelPart>, String>.t1(labelParts.toList()),
      position: position,
      kind: InlayHintKind.Type,
    ));
  }

  /// Adds a type hint before [node] showing a label for the type [type].
  ///
  /// Padding will be added between the hint and [node] automatically.
  void _addTypePrefix(SyntacticEntity nodeOrToken, DartType type) {
    final offset = nodeOrToken.offset;
    final position = toPosition(_lineInfo.getLocation(offset));
    final labelParts = <InlayHintLabelPart>[];
    _appendTypePart(labelParts, type);
    _hints.add(InlayHint(
      label: Either2<List<InlayHintLabelPart>, String>.t1(labelParts),
      position: position,
      kind: InlayHintKind.Type,
      paddingRight: true,
    ));
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
      final isLast = i == types.length - 1;
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
    parts.add(InlayHintLabelPart(
      // Write type without type args or nullability suffix. Type args need
      // adding as their own parts, and the nullability suffix does after them.
      value:
          type.element?.name ?? type.getDisplayString(withNullability: false),
      location: _locationForElement(type.element),
    ));
    // Call recursively for any nested type arguments.
    if (type is InterfaceType && type.typeArguments.isNotEmpty) {
      _appendTypeArgumentParts(parts, type.typeArguments);
    }
    // Finally add any nullability suffix.
    if (_isNonNullableByDefault) {
      switch (type.nullabilitySuffix) {
        case NullabilitySuffix.question:
          parts.add(InlayHintLabelPart(value: '?'));
        case NullabilitySuffix.star:
          parts.add(InlayHintLabelPart(value: '*'));
        default:
      }
    }
  }

  Location? _locationForElement(Element? element) {
    if (element == null) {
      return null;
    }
    final compilationUnit =
        element.thisOrAncestorOfType<CompilationUnitElement>();
    final path = compilationUnit?.source.fullName;
    final lineInfo = compilationUnit?.lineInfo;
    if (path == null || lineInfo == null || element.nameOffset == -1) {
      return null;
    }
    return Location(
      uri: Uri.file(path),
      range: toRange(lineInfo, element.nameOffset, element.nameLength),
    );
  }

  /// Adds a Type hint for type arguments of [type] (if it has type arguments).
  void _maybeAddTypeArguments(Token token, DartType? type) {
    if (type is! ParameterizedType) {
      return;
    }

    final typeArgumentTypes = type.typeArguments;
    if (typeArgumentTypes.isEmpty) {
      return;
    }

    _addTypeArgumentsPrefix(token, typeArgumentTypes);
  }
}

/// An AST visitor for [DartInlayHintComputer].
class _DartInlayHintComputerVisitor extends GeneralizingAstVisitor<void> {
  final DartInlayHintComputer _computer;

  _DartInlayHintComputerVisitor(this._computer);

  @override
  void visitArgumentList(ArgumentList node) {
    for (final argument in node.arguments) {
      if (argument is! NamedExpression) {
        final parameter = argument.staticParameterElement;
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

    final declaration = node.declaredElement;
    if (declaration != null) {
      // For getters/setters, the type must come before the property keyword,
      // not the name.
      final token = node.propertyKeyword ?? node.name;
      _computer._addTypePrefix(token, declaration.returnType2);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);

    // Has explicit type arguments.
    if (node.constructorName.type.typeArguments != null) {
      return;
    }

    final token = node.argumentList.leftParenthesis;
    final type = node.staticType;
    _computer._maybeAddTypeArguments(token, type);
  }

  @override
  void visitInvocationExpression(InvocationExpression node) {
    super.visitInvocationExpression(node);

    // Has explicit type arguments.
    if (node.typeArguments != null) {
      return;
    }

    _computer._addTypeArgumentsPrefix(
        node.argumentList.leftParenthesis, node.typeArgumentTypes);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);

    // Has explicit type arguments.
    if (node.typeArguments != null) {
      return;
    }

    final token = node.leftBracket;
    final type = node.staticType;
    _computer._maybeAddTypeArguments(token, type);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);

    // Has explicit type.
    if (node.returnType != null) {
      return;
    }

    final declaration = node.declaredElement;
    if (declaration != null) {
      _computer._addTypePrefix(node.name, declaration.returnType2);
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    super.visitSetOrMapLiteral(node);

    // Has explicit type arguments.
    if (node.typeArguments != null) {
      return;
    }

    final token = node.leftBracket;
    final type = node.staticType;
    _computer._maybeAddTypeArguments(token, type);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    super.visitSimpleFormalParameter(node);

    // Has explicit type.
    if (node.isExplicitlyTyped) {
      return;
    }

    final declaration = node.declaredElement;
    if (declaration != null) {
      // Prefer to insert before `name` to avoid going before keywords like
      // `required`.
      _computer._addTypePrefix(node.name ?? node, declaration.type);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);

    final parent = node.parent;
    // Unexpected parent or has explicit type.
    if (parent is! VariableDeclarationList || parent.type != null) {
      return;
    }

    final declaration = node.declaredElement;
    if (declaration != null) {
      _computer._addTypePrefix(node, declaration.type);
    }
  }
}
