// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class RemoveConst extends _RemoveConst {
  RemoveConst({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.removeConst;
}

class RemoveUnnecessaryConst extends _RemoveConst {
  RemoveUnnecessaryConst({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeUnnecessaryConst;

  @override
  FixKind get multiFixKind => DartFixKind.removeUnnecessaryConstMulti;
}

class _ChildrenVisitor extends GeneralizingAstVisitor<AstNode?> {
  AstNode? _selectedNode;

  final int offset;
  final int end;

  _ChildrenVisitor(this.offset, this.end);

  AstNode get selectedNode => _selectedNode!;

  @override
  AstNode? visitNode(AstNode node) {
    if (node.offset > offset || node.end < end) {
      return null;
    }
    if (node.offset <= offset && node.end >= end) {
      var result = super.visitNode(node);
      if (result != null) {
        return _selectedNode ??= result;
      }
    }
    return _selectedNode ??= node;
  }
}

class _PushConstVisitor extends GeneralizingAstVisitor<void> {
  final DartFileEditBuilder builder;
  final List<AstNode> excluded;

  _PushConstVisitor(this.builder, this.excluded);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    _pushConstInConstructorInvocation(
      node,
      node.argumentList,
      node.constKeyword,
    );
  }

  @override
  void visitIfElement(IfElement node) {
    node.thenElement.accept(this);
    node.elseElement?.accept(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _pushConstInConstructorInvocation(node, node.argumentList, node.keyword);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    node.expression.accept(this);
  }

  @override
  void visitTypedLiteral(TypedLiteral node) {
    if (_containsExcluded(node)) {
      node.visitChildren(this);
    } else {
      if (node.constKeyword == null) {
        builder.addSimpleInsertion(node.offset, '${Keyword.CONST.lexeme} ');
      }
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    node.initializer?.accept(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    node.variables.accept(this);
  }

  bool _containsExcluded(AstNode node) {
    return {for (var e in excluded) ...e.withAncestors}.contains(node);
  }

  void _pushConstInConstructorInvocation(
    AstNode node,
    ArgumentList argumentList,
    Token? constKeyword,
  ) {
    if (_containsExcluded(node)) {
      argumentList.visitChildren(this);
    } else if (excluded.any(node.contains)) {
      // Don't speculate whether arguments can be const.
    } else if (constKeyword == null) {
      builder.addSimpleInsertion(node.offset, '${Keyword.CONST.lexeme} ');
    }
  }
}

abstract class _RemoveConst extends ParsedCorrectionProducer {
  _RemoveConst({required super.context});

  /// A map of all the error codes that this fix can be applied to and the
  /// generators that can be used to apply the fix.
  Set<DiagnosticCode> get _codesWhereThisIsValid {
    var constructors = [RemoveUnnecessaryConst.new, RemoveConst.new];
    var nonLintMultiProducers = registeredFixGenerators.warningProducers;
    return {
      for (var MapEntry(:key, :value) in nonLintMultiProducers.entries)
        if (value.containsAny(constructors)) key,
    };
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnostic = this.diagnostic;
    if (diagnostic is! Diagnostic) {
      return;
    }

    switch (node) {
      case ClassDeclaration declaration:
        var first = declaration.firstTokenAfterCommentAndMetadata;
        if (first.previous case var constKeyword?) {
          await _deleteConstKeyword(builder, constKeyword);
        }
        return;
      case CompilationUnit():
        await _deleteRangeFromError(builder);
        return;
      case ConstructorDeclaration declaration:
        var constKeyword = declaration.constKeyword;
        if (constKeyword != null) {
          await _deleteConstKeyword(builder, constKeyword);
        }
        return;
      case ExpressionImpl expression:
        var constantContext = expression.constantContext(includeSelf: true);
        if (constantContext case (var node, var constKeyword?)) {
          var validDiagnostics = [
            for (var e in unitResult.diagnostics)
              if (_codesWhereThisIsValid.contains(e.diagnosticCode)) e,
          ];
          switch (node) {
            case InstanceCreationExpression(:var argumentList) ||
                DotShorthandConstructorInvocation(:var argumentList):
              var (:constNodes, :nodesWithDiagnostic) = argumentList.arguments
                  .withDiagnosticCodeIn(validDiagnostics);
              await builder.addDartFileEdit(file, (builder) {
                _deleteToken(builder, constKeyword);
                node.accept(_PushConstVisitor(builder, nodesWithDiagnostic));
              });
            case TypedLiteral contextNode:
              var (:constNodes, :nodesWithDiagnostic) = switch (contextNode) {
                ListLiteral list => list.elements,
                SetOrMapLiteral set => set.elements,
              }.withDiagnosticCodeIn(validDiagnostics);
              await builder.addDartFileEdit(file, (builder) {
                _deleteToken(builder, constKeyword);
                contextNode.accept(
                  _PushConstVisitor(builder, nodesWithDiagnostic),
                );
              });
            case VariableDeclarationList contextNode:
              var (:constNodes, :nodesWithDiagnostic) = contextNode.variables
                  .withDiagnosticCodeIn(validDiagnostics);
              await builder.addDartFileEdit(file, (builder) {
                builder.addSimpleReplacement(
                  range.token(constKeyword),
                  Keyword.FINAL.lexeme,
                );
                contextNode.accept(
                  _PushConstVisitor(builder, nodesWithDiagnostic),
                );
              });
          }
        }
    }
  }

  Future<void> _deleteConstKeyword(
    ChangeBuilder builder,
    Token constKeyword,
  ) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(constKeyword, constKeyword.next!));
    });
  }

  Future<void> _deleteRangeFromError(ChangeBuilder builder) async {
    // In the case of a `const class` declaration, the `const` keyword is
    // not part of the class so we have to use the diagnostic offset.
    var diagnostic = this.diagnostic;
    if (diagnostic is! Diagnostic) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
        // TODO(pq): consider ensuring that any extra whitespace is removed.
        SourceRange(diagnostic.offset, diagnostic.length + 1),
      );
    });
  }

  void _deleteToken(DartFileEditBuilder builder, Token token) {
    builder.addDeletion(range.startStart(token, token.next!));
  }
}

extension on Diagnostic {
  int get end => offset + length;

  bool isWithin(AstNode node) {
    return node.offset <= offset && node.end >= end;
  }
}

extension on AstNode {
  bool contains(AstNode node) {
    return offset <= node.offset && end >= node.end;
  }
}

extension on List<AstNode> {
  ({List<AstNode> nodesWithDiagnostic, List<AstNode> constNodes})
  withDiagnosticCodeIn(List<Diagnostic> diagnostics) {
    if (diagnostics.isEmpty) {
      return (constNodes: toList(), nodesWithDiagnostic: const []);
    }
    var invalidNodes = <AstNode>[];
    var constNodes = <AstNode>[];
    for (var node in this) {
      // If no diagnostic spans this node, it is valid.
      if (diagnostics.none((d) => d.isWithin(node))) {
        constNodes.add(node);
        continue;
      }
      var diagnostic = diagnostics.firstWhere((d) => d.isWithin(node));
      var visitor = _ChildrenVisitor(diagnostic.offset, diagnostic.end);
      node.accept(visitor);
      invalidNodes.add(visitor.selectedNode);
    }
    return (nodesWithDiagnostic: invalidNodes, constNodes: constNodes);
  }
}

extension<T> on Iterable<T> {
  bool containsAny(Iterable<T> values) {
    return values.any((v) => contains(v));
  }
}
