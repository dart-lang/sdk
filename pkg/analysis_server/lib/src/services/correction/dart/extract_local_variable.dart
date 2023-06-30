// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ExtractLocalVariable extends ResolvedCorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.EXTRACT_LOCAL_VARIABLE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! SimpleIdentifier) {
      return;
    }

    var parent = node.parent;

    if (parent is MethodInvocation && parent.methodName == node) {
      await _rewrite(
        builder: builder,
        target: parent.target,
      );
    }

    if (parent is PrefixedIdentifier && parent.identifier == node) {
      await _rewrite(
        builder: builder,
        target: parent.prefix,
      );
    }

    if (parent is PropertyAccess && parent.propertyName == node) {
      await _rewrite(
        builder: builder,
        target: parent.target,
      );
    }
  }

  Future<void> _rewrite({
    required ChangeBuilder builder,
    required Expression? target,
  }) async {
    if (target is PrefixedIdentifier) {
      await _rewriteProperty(
        builder: builder,
        target: target,
        targetProperty: target.staticElement,
      );
    }

    if (target is PropertyAccess) {
      await _rewriteProperty(
        builder: builder,
        target: target,
        targetProperty: target.propertyName.staticElement,
      );
    }

    if (target is SimpleIdentifier) {
      await _rewriteProperty(
        builder: builder,
        target: target,
        targetProperty: target.staticElement,
      );
    }
  }

  Future<void> _rewriteProperty({
    required ChangeBuilder builder,
    required Expression target,
    required Element? targetProperty,
  }) async {
    if (targetProperty is PropertyAccessorElement &&
        targetProperty.isGetter &&
        typeSystem.isPotentiallyNullable(targetProperty.returnType2)) {
      AstNode? enclosingNode = target;
      while (true) {
        if (enclosingNode == null || enclosingNode is FunctionBody) {
          return;
        }
        if (enclosingNode is IfStatement) {
          var condition = enclosingNode.expression;
          if (condition is BinaryExpression &&
              condition.rightOperand is NullLiteral &&
              condition.operator.type == TokenType.BANG_EQ) {
            var encoder = _ExpressionEncoder();
            var leftCode = encoder.encode(condition.leftOperand);
            var targetCode = encoder.encode(target);
            if (leftCode == targetCode) {
              var occurrences = <SourceRange>[];
              enclosingNode.accept(
                _OccurrencesVisitor(encoder, occurrences, leftCode),
              );

              var ifOffset = enclosingNode.offset;
              var ifLineOffset = utils.getLineContentStart(ifOffset);
              var prefix = utils.getLinePrefix(ifOffset);

              var initializerCode = utils.getNodeText(target);
              if (target is SimpleIdentifier) {
                initializerCode = 'this.$initializerCode';
              }

              await builder.addDartFileEdit(file, (builder) {
                var propertyName = targetProperty.name;
                builder.addInsertion(ifLineOffset, (builder) {
                  builder.write(prefix);
                  builder.writeln('final $propertyName = $initializerCode;');
                });
                for (var occurrence in occurrences) {
                  builder.addSimpleReplacement(occurrence, propertyName);
                }
              });
              return;
            }
          }
          break;
        }
        enclosingNode = enclosingNode.parent;
      }
    }
  }
}

class _ExpressionEncoder {
  final Map<Element, int> _elementIds = {};

  String encode(Expression node) {
    var tokens = TokenUtils.getNodeTokens(node);

    var tokenToElementMap = Map<Token, Element>.identity();
    node.accept(
      _FunctionAstVisitor(
        simpleIdentifier: (node) {
          var element = node.staticElement;
          if (element != null) {
            tokenToElementMap[node.token] = element;
          }
        },
      ),
    );

    var tokensWithId = tokens.map((token) {
      var tokenString = token.lexeme;
      var element = tokenToElementMap[token];
      if (element != null) {
        var elementId = _elementIds.putIfAbsent(
          element,
          () => _elementIds.length,
        );
        tokenString += '#$elementId';
      }
      return tokenString;
    });

    const separator = '\uFFFF';
    return tokensWithId.join(separator) + separator;
  }
}

/// [RecursiveAstVisitor] that delegates visit methods to functions.
class _FunctionAstVisitor extends RecursiveAstVisitor<void> {
  final void Function(SimpleIdentifier)? simpleIdentifier;

  _FunctionAstVisitor({
    this.simpleIdentifier,
  });

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (simpleIdentifier != null) {
      simpleIdentifier!(node);
    }
    super.visitSimpleIdentifier(node);
  }
}

class _OccurrencesVisitor extends GeneralizingAstVisitor<void> {
  final _ExpressionEncoder encoder;
  final List<SourceRange> occurrences;
  final String searchCode;

  _OccurrencesVisitor(this.encoder, this.occurrences, this.searchCode);

  @override
  void visitExpression(Expression node) {
    var nodeCode = encoder.encode(node);
    if (nodeCode == searchCode) {
      occurrences.add(range.node(node));
    }
    super.visitExpression(node);
  }
}
