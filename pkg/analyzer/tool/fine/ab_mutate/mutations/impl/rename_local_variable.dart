// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
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
    var declaration = unit.nodeCovering(offset: localOffset);
    if (declaration is! VariableDeclaration ||
        declaration.name.lexeme != localName) {
      throw StateError('Did not find expected local variable.');
    }

    var declarationElement = declaration.declaredFragment!.element;

    var block = declaration.thisOrAncestorOfType<Block>();
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
    block.visitChildren(
      FunctionAstVisitor(
        simpleIdentifier: (node) {
          if (identical(node.element, declarationElement)) {
            edits.add(MutationEdit(node.offset, node.length, newName));
          }
        },
      ),
    );

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
    var used = <String>{};
    block.visitChildren(
      FunctionAstVisitor(
        simpleIdentifier: (node) {
          used.add(node.name);
        },
      ),
    );
    for (var i = 1; i < 10000; i++) {
      var candidate = '${base}_$i';
      if (!used.contains(candidate)) return candidate;
    }
    return '${base}_renamed';
  }

  static List<Mutation> discover(String filePath, CompilationUnit unit) {
    var mutations = <Mutation>[];

    var bodies = <FunctionBody>[];
    unit.visitChildren(
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
      body.visitChildren(
        FunctionAstVisitor(
          variableDeclaration: (node) {
            // Only locals inside block statements.
            if (node.parent?.parent is VariableDeclarationStatement) {
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
