// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveConst extends _RemoveConst {
  RemoveConst({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_CONST;
}

class RemoveUnnecessaryConst extends _RemoveConst {
  RemoveUnnecessaryConst({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_CONST;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_UNNECESSARY_CONST_MULTI;
}

class _PushConstVisitor extends GeneralizingAstVisitor<void> {
  final DartFileEditBuilder builder;
  final AstNode excluded;

  _PushConstVisitor(this.builder, this.excluded);

  @override
  void visitIfElement(IfElement node) {
    node.thenElement.accept(this);
    node.elseElement?.accept(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node == excluded) {
      // Don't speculate whether arguments can be const.
    } else if (_containsExcluded(node)) {
      node.argumentList.visitChildren(this);
    } else {
      if (node.keyword == null) {
        builder.addSimpleInsertion(node.offset, 'const ');
      }
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitNode(AstNode node) {}

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
        builder.addSimpleInsertion(node.offset, 'const ');
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
    return excluded.withParents.contains(node);
  }
}

abstract class _RemoveConst extends ParsedCorrectionProducer {
  _RemoveConst({required super.context});

  @override
  Future<void> compute(ChangeBuilder builder) async {
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
        var constantContext = expression.constantContext(
          includeSelf: true,
        );
        if (constantContext != null) {
          var constKeyword = constantContext.$2;
          if (constKeyword != null) {
            switch (constantContext.$1) {
              case InstanceCreationExpression contextNode:
                await builder.addDartFileEdit(file, (builder) async {
                  _deleteToken(builder, constKeyword);
                  contextNode.accept(
                    _PushConstVisitor(builder, expression),
                  );
                });
              case TypedLiteral contextNode:
                await builder.addDartFileEdit(file, (builder) async {
                  _deleteToken(builder, constKeyword);
                  contextNode.accept(
                    _PushConstVisitor(builder, expression),
                  );
                });
              case VariableDeclarationList contextNode:
                await builder.addDartFileEdit(file, (builder) {
                  if (contextNode.type != null) {
                    _deleteToken(builder, constKeyword);
                  } else {
                    builder.addSimpleReplacement(
                      range.token(constKeyword),
                      'var',
                    );
                  }
                  contextNode.accept(
                    _PushConstVisitor(builder, expression),
                  );
                });
            }
          }
        }
    }
  }

  Future<void> _deleteConstKeyword(
    ChangeBuilder builder,
    Token constKeyword,
  ) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
        range.startStart(
          constKeyword,
          constKeyword.next!,
        ),
      );
    });
  }

  Future<void> _deleteRangeFromError(ChangeBuilder builder) async {
    // In the case of a `const class` declaration, the `const` keyword is
    // not part of the class so we have to use the diagnostic offset.
    var diagnostic = this.diagnostic;
    if (diagnostic is! AnalysisError) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
          // TODO(pq): consider ensuring that any extra whitespace is removed.
          SourceRange(diagnostic.offset, diagnostic.length + 1));
    });
  }

  void _deleteToken(DartFileEditBuilder builder, Token token) {
    builder.addDeletion(
      range.startStart(token, token.next!),
    );
  }
}
