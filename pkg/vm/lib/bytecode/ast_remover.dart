// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.ast_remover;

import 'package:kernel/ast.dart' hide MapEntry;
import '../metadata/bytecode.dart';

/// Drops kernel AST for members with bytecode.
/// Can preserve removed AST and restore it if needed.
class ASTRemover extends Transformer {
  final BytecodeMetadataRepository metadata;
  final droppedAST = <Member, dynamic>{};

  ASTRemover(Component component)
      : metadata = component.metadata[new BytecodeMetadataRepository().tag];

  @override
  TreeNode defaultMember(Member node) {
    if (_hasBytecode(node)) {
      if (node is Field) {
        droppedAST[node] = node.initializer;
        node.initializer = null;
      } else if (node is Constructor) {
        droppedAST[node] =
            new _DroppedConstructor(node.initializers, node.function.body);
        node.initializers = <Initializer>[];
        node.function.body = null;
      } else if (node.function != null) {
        droppedAST[node] = node.function.body;
        node.function.body = null;
      }
    }

    // Instance field initializers do not form separate functions, and bytecode
    // is not attached to instance fields (it is included into constructors).
    // When VM reads a constructor from kernel, it also reads and translates
    // instance field initializers. So, their ASTs can be dropped only if
    // bytecode was generated for all generative constructors.
    if (node is Field && !node.isStatic && node.initializer != null) {
      if (node.enclosingClass.constructors.every(_hasBytecode)) {
        droppedAST[node] = node.initializer;
        node.initializer = null;
      }
    }

    return node;
  }

  bool _hasBytecode(Member node) =>
      metadata != null && metadata.mapping.containsKey(node);

  void restoreAST() {
    droppedAST.forEach((Member node, dynamic dropped) {
      if (node is Field) {
        node.initializer = dropped;
      } else if (node is Constructor) {
        _DroppedConstructor droppedConstructor = dropped;
        node.initializers = droppedConstructor.initializers;
        node.function.body = droppedConstructor.body;
      } else {
        node.function.body = dropped;
      }
    });
  }
}

class _DroppedConstructor {
  final List<Initializer> initializers;
  final Statement body;

  _DroppedConstructor(this.initializers, this.body);
}
