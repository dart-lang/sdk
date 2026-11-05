// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';

import '../../models.dart';
import '../api.dart';
import '../kinds.dart';

class RenameLocalVariableMutation extends Mutation {
  final String localName;
  final int localOffset;

  RenameLocalVariableMutation({
    required super.path,
    required this.localName,
    required this.localOffset,
  });

  @override
  MutationKind get kind => MutationKind.renameLocalVariable;

  @override
  MutationResult apply(CompilationUnit unit, String content) {
    var declaration = unit.nodeCovering2(offset: localOffset);
    if (declaration is! VariableDeclaration ||
        declaration.name.lexeme != localName) {
      throw StateError('Did not find expected local variable.');
    }

    var declarationElement = declaration.declaredFragment!.element;

    var block = declaration.thisOrAncestorOfType2<Block>();
    if (block == null) {
      throw StateError('Did not find enclosing block.');
    }

    var oldName = declaration.name.lexeme;
    var newName = _freshLocalName(block, oldName);

    var edits = <MutationEdit>[];
    edits.add(
      MutationEdit(declaration.name.offset, declaration.name.length, newName),
    );

    // Update all references in the same block.
    for (var (name, element) in _UnqualifiedReferences.of(block)) {
      if (identical(element, declarationElement)) {
        edits.add(MutationEdit(name.offset, name.length, newName));
      }
    }

    // Apply from end to start.
    edits.sort((a, b) => b.offset.compareTo(a.offset));
    var out = content;
    for (var e in edits) {
      out = out.replaceRange(e.offset, e.offset + e.length, e.replacement);
    }
    return MutationResult(MutationEdit(0, content.length, out), {
      'old': oldName,
      'new': newName,
      'refs': edits.length,
    });
  }

  @override
  Map<String, Object?> toJson() {
    return {'local_name': localName, 'local_offset': localOffset};
  }

  String _freshLocalName(Block block, String base) {
    var used = {
      for (var (name, _) in _UnqualifiedReferences.of(block)) name.lexeme,
    };
    for (var i = 1; i < 10000; i++) {
      var candidate = '${base}_$i';
      if (!used.contains(candidate)) return candidate;
    }
    return '${base}_renamed';
  }

  static List<Mutation> discover(String filePath, CompilationUnit unit) {
    var mutations = <Mutation>[];

    var bodies = <FunctionBody>[];
    unit.visitChildren2(
      FunctionAstVisitor(
        functionDeclaration: (node) {
          bodies.add(node.functionExpression.body);
        },
        methodDeclaration: (node) {
          bodies.add(node.body);
        },
      ),
    );

    // Collect locals in all function/method bodies.
    for (var body in bodies) {
      var locals = <VariableDeclaration>[];
      body.visitChildren2(
        FunctionAstVisitor(
          variableDeclaration: (node) {
            // Only locals inside block statements.
            if (node.parent2?.parent2 is VariableDeclarationStatement) {
              locals.add(node);
            }
          },
        ),
      );

      for (var variableDeclaration in locals) {
        var offset = variableDeclaration.name.offset;
        mutations.add(
          RenameLocalVariableMutation(
            path: filePath,
            localName: variableDeclaration.name.lexeme,
            localOffset: offset,
          ),
        );
      }
    }
    return mutations;
  }
}

/// Collects the names written as unqualified references, with the elements
/// they resolve to.
///
/// A local variable is referenced only through these nodes; an invocation
/// `f()` of a local variable `f` is a call on an [UnqualifiedNameExpression].
class _UnqualifiedReferences extends RecursiveAstVisitor2<void> {
  final List<(Token, Element?)> _references = [];

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    _add(node.name, node);
    super.visitAssignedVariablePattern(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _add(node.identifier2, node);
    super.visitForEachPartsWithIdentifier(node);
  }

  @override
  void visitUnqualifiedFunctionInvocation(UnqualifiedFunctionInvocation node) {
    _add(node.name, node);
    super.visitUnqualifiedFunctionInvocation(node);
  }

  @override
  void visitUnqualifiedNameAssignmentTarget(
    UnqualifiedNameAssignmentTarget node,
  ) {
    _add(node.name, node);
    super.visitUnqualifiedNameAssignmentTarget(node);
  }

  @override
  void visitUnqualifiedNameExpression(UnqualifiedNameExpression node) {
    _add(node.name, node);
    super.visitUnqualifiedNameExpression(node);
  }

  void _add(Token name, AstNode node) {
    _references.add((name, ElementLocatorV2.locate(node)));
  }

  static List<(Token, Element?)> of(AstNode node) {
    var collector = _UnqualifiedReferences();
    node.visitChildren2(collector);
    return collector._references;
  }
}
