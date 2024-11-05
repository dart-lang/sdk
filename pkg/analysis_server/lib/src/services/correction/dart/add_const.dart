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
import 'package:analyzer/src/lint/linter.dart';
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
    AstNode? targetNode = node;
    if (targetNode is SimpleIdentifier) {
      targetNode = targetNode.parent;
    }
    if (targetNode is ConstructorDeclaration) {
      var node_final = targetNode;
      await builder.addDartFileEdit(file, (builder) {
        var offset = node_final.firstTokenAfterCommentAndMetadata.offset;
        builder.addSimpleInsertion(offset, 'const ');
      });
      return;
    }

    Future<void> addParensAndConst(AstNode node_final) async {
      var offset = node_final.offset;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(offset + node_final.length, ')');
        builder.addSimpleInsertion(offset, 'const (');
      });
    }

    if (targetNode is TypeArgumentList) {
      while (targetNode is! CompilationUnit && targetNode is! ConstantPattern) {
        targetNode = targetNode?.parent;
      }
    }
    if (targetNode is CompilationUnit) {
      return;
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
        var node_final = targetNode.parent;
        if (node_final is ParenthesizedPattern) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleInsertion(node_final.offset, 'const ');
          });
        } else {
          await addParensAndConst(node_final!);
        }
      }
      return;
    }
    if (targetNode is BinaryExpression || targetNode is PrefixExpression) {
      var node_final = targetNode?.parent;
      if (node_final?.parent is ParenthesizedPattern) {
        // add const
        var offset = node_final!.parent!.offset;
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(offset, 'const ');
        });
      } else {
        // add const and parenthesis
        await addParensAndConst(node_final!);
      }
      return;
    }

    bool isParentConstant(
        DartFileEditBuilderImpl builder, Expression targetNode) {
      var edits = builder.fileEdit.edits;
      var child = targetNode.parent;
      while (child is Expression ||
          child is ArgumentList ||
          child is VariableDeclaration ||
          child is VariableDeclarationList) {
        if (edits.any((element) =>
            element.replacement.startsWith('const') &&
            element.offset == child!.offset)) {
          return true;
        }
        child = child!.parent;
      }
      return false;
    }

    Future<void> insertAtOffset(Expression targetNode) async {
      var finder = _ConstRangeFinder();
      targetNode.accept(finder);
      await builder.addDartFileEdit(file, (builder) {
        if (builder is DartFileEditBuilderImpl &&
            isParentConstant(builder, targetNode)) {
          return;
        }
        builder.addSimpleInsertion(targetNode.offset, 'const ');
        for (var range in finder.ranges) {
          builder.addDeletion(range);
        }
      });
    }

    if (targetNode is ListLiteral) {
      await insertAtOffset(targetNode);
      return;
    }
    if (targetNode is SetOrMapLiteral) {
      await insertAtOffset(targetNode);
      return;
    }
    if (targetNode is NamedType) {
      targetNode = targetNode.parent;
    }
    if (targetNode is ConstructorName) {
      targetNode = targetNode.parent;
    }
    if (targetNode case InstanceCreationExpression(:var parent, :var keyword)) {
      var constDeclarations =
          getCodeStyleOptions(unitResult.file).preferConstDeclarations;

      if (parent is VariableDeclaration && constDeclarations) {
        if (parent.parent
            case VariableDeclarationList(:var finalKeyword?, :var variables)
            when _declarationListIsFullyConst(variables)) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleReplacement(range.token(finalKeyword), 'const');
          });
          return;
        }
      }
      if (keyword == null) {
        await insertAtOffset(targetNode);
        return;
      }
    }
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
    var errors = [
      ...unitResult.errors.where(
        (error) => error.errorCode == LinterLintCode.prefer_const_constructors,
      ),
    ];
    var errorsRanges = errors.map(range.error);
    var variablesRanges = variables.map((v) {
      var initializer = v.initializer;
      if (initializer == null) return range.node(v);
      return range.node(initializer);
    });
    // If each of the variable ranges is contained in the list of error ranges.
    return variablesRanges.every(errorsRanges.contains);
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
