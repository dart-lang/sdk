// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:linter/src/lint_codes.dart';

class AddConst extends ResolvedCorrectionProducer {
  AddConst({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.ADD_CONST;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_CONST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetNode = _computeTargetNode();
    if (targetNode == null) {
      return;
    }

    if (targetNode is ConstructorDeclaration) {
      var offset = targetNode.firstTokenAfterCommentAndMetadata.offset;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(offset, 'const ');
      });
      return;
    }

    Future<void> addParensAndConst(AstNode parent) async {
      var offset = parent.offset;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(offset + parent.length, ')');
        builder.addSimpleInsertion(offset, 'const (');
      });
    }

    if (targetNode is ConstantPattern) {
      var expression = targetNode.expression;
      var canBeConst = expression.canBeConst;
      if (canBeConst) {
        await builder.addDartFileEdit(file, (builder) {
          var offset = expression.offset;
          builder.addSimpleInsertion(offset, 'const ');
        });
      } else if (expression is TypeLiteral) {
        var parent = targetNode.parent!;
        if (parent is ParenthesizedPattern) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleInsertion(parent.offset, 'const ');
          });
        } else {
          await addParensAndConst(parent);
        }
      }
      return;
    }
    if (targetNode case BinaryExpression() || PrefixExpression()) {
      var parent = targetNode.parent!;
      if (parent.parent is ParenthesizedPattern) {
        // Add `const`.
        var offset = parent.parent!.offset;
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(offset, 'const ');
        });
      } else {
        // Add `const` and parentheses.
        await addParensAndConst(parent);
      }
      return;
    }

    if (targetNode is ListLiteral) {
      await _insertBeforeNode(builder, targetNode);
      return;
    }
    if (targetNode is SetOrMapLiteral) {
      await _insertBeforeNode(builder, targetNode);
      return;
    }
    if (targetNode case InstanceCreationExpression(:var parent, :var keyword)) {
      var constDeclarations =
          getCodeStyleOptions(unitResult.file).preferConstDeclarations;

      if (parent is VariableDeclaration && constDeclarations) {
        if (parent.parent case VariableDeclarationList(
          :var finalKeyword?,
          :var variables,
        ) when _declarationListIsFullyConst(variables)) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleReplacement(range.token(finalKeyword), 'const');
          });
          return;
        }
      }
      if (keyword == null) {
        await _insertBeforeNode(builder, targetNode);
        return;
      }
    }
  }

  /// Computes the node which this correction should treat as the target.
  AstNode? _computeTargetNode() {
    AstNode? targetNode = node;
    if (targetNode is SimpleIdentifier) {
      targetNode = targetNode.parent;
    }
    if (targetNode is TypeArgumentList) {
      while (targetNode is! CompilationUnit && targetNode is! ConstantPattern) {
        targetNode = targetNode?.parent;
      }
    }
    if (targetNode is CompilationUnit) {
      return null;
    }
    if (targetNode is NamedType) {
      targetNode = targetNode.parent;
    }
    if (targetNode is ConstructorName) {
      targetNode = targetNode.parent;
    }
    return targetNode;
  }

  /// Considers if the given [variables] to be declared with `const` if all of
  /// them are contained in the list of errors that suggest using `const` (
  /// `prefer_const_constructors` triggers).
  ///
  /// This is used to determine if a `const` keyword should be added to a
  /// variable declaration list. E.g.:
  ///
  /// ```dart
  /// final a = 1, b = 2;
  /// ```
  ///
  /// Would then be transformed to:
  ///
  /// ```dart
  /// const a = 1, b = 2;
  /// ```
  ///
  /// If not all of the variables are contained in the list of errors that
  /// suggest using `const` then the `const` keyword should not be added. E.g.:
  ///
  /// ```dart
  /// class C {
  ///   const C();
  /// }
  /// final c = C(), d = Future.value(1);
  /// ```
  ///
  /// Would be transformed to:
  ///
  /// ```dart
  /// final c = const C(), d = Future.value(1);
  /// ```
  ///
  /// If other diagnostics are to be fixed with this CorrectionProducer the
  /// inner test for `prefer_const_constructors` will need to be amended.
  bool _declarationListIsFullyConst(NodeList<VariableDeclaration> variables) {
    var diagnostics = [
      ...unitResult.diagnostics.where(
        (error) =>
            error.diagnosticCode == LinterLintCode.prefer_const_constructors,
      ),
    ];
    var ranges = diagnostics.map(range.diagnostic);
    var variablesRanges = variables.map((v) {
      var initializer = v.initializer;
      if (initializer == null) return range.node(v);
      return range.node(initializer);
    });
    // If each of the variable ranges is contained in the list of error ranges.
    return variablesRanges.every(ranges.contains);
  }

  /// Inserts `const ` before [targetNode].
  Future<void> _insertBeforeNode(
    ChangeBuilder builder,
    Expression targetNode,
  ) async {
    var finder = _ConstRangeFinder();
    targetNode.accept(finder);
    await builder.addDartFileEdit(file, (builder) {
      if (builder is DartFileEditBuilderImpl &&
          _isAncestorConstant(builder.fileEdit.edits, targetNode)) {
        return;
      }
      builder.addSimpleInsertion(targetNode.offset, 'const ');
      for (var range in finder.ranges) {
        builder.addDeletion(range);
      }
    });
  }

  /// Returns whether any [edits] start with 'const' and have the same offset as
  /// one of [targetNode]s ancestors.
  bool _isAncestorConstant(List<SourceEdit> edits, Expression targetNode) {
    var child = targetNode.parent;
    var editsWhichStartWithConst =
        edits.where((e) => e.replacement.startsWith('const')).toList();
    if (editsWhichStartWithConst.isEmpty) {
      return false;
    }
    while (child is Expression ||
        child is ArgumentList ||
        child is VariableDeclaration ||
        child is VariableDeclarationList) {
      if (editsWhichStartWithConst.any((e) => e.offset == child!.offset)) {
        return true;
      }
      child = child!.parent;
    }
    return false;
  }
}

class _ConstRangeFinder extends RecursiveAstVisitor<void> {
  final List<SourceRange> ranges = [];

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Stop visiting when we get to a closure.
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _removeKeyword(node.keyword);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _removeKeyword(node.constKeyword);
    super.visitListLiteral(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _removeKeyword(node.constKeyword);
    super.visitSetOrMapLiteral(node);
  }

  void _removeKeyword(Token? keyword) {
    if (keyword != null && keyword.type == Keyword.CONST) {
      ranges.add(range.startStart(keyword, keyword.next!));
    }
  }
}
