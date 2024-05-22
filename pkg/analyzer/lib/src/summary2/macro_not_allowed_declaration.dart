// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/visitor.dart' as ast;
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:macros/src/executor.dart' as macro;

List<ast.Declaration> findDeclarationsNotAllowedAtPhase({
  required ast.CompilationUnit unit,
  required macro.Phase phase,
}) {
  var visitor = _NotAllowedDeclarationsVisitor(phase);
  unit.accept(visitor);
  return visitor.notAllowed;
}

class _NotAllowedDeclarationsVisitor extends ast.RecursiveAstVisitor<void> {
  final macro.Phase phase;
  final List<ast.Declaration> notAllowed = [];

  _NotAllowedDeclarationsVisitor(this.phase);

  @override
  void visitClassDeclaration(ast.ClassDeclaration node) {
    switch (phase) {
      case macro.Phase.types:
        break;
      case macro.Phase.declarations:
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }

    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ast.ConstructorDeclaration node) {
    switch (phase) {
      case macro.Phase.types:
      case macro.Phase.declarations:
        break;
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }
  }

  @override
  void visitEnumConstantDeclaration(ast.EnumConstantDeclaration node) {
    switch (phase) {
      case macro.Phase.types:
        break;
      case macro.Phase.declarations:
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }
  }

  @override
  void visitEnumDeclaration(ast.EnumDeclaration node) {
    switch (phase) {
      case macro.Phase.types:
        break;
      case macro.Phase.declarations:
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }

    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ast.ExtensionDeclaration node) {
    switch (phase) {
      case macro.Phase.types:
      case macro.Phase.declarations:
        break;
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }

    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionTypeDeclaration(ast.ExtensionTypeDeclaration node) {
    switch (phase) {
      case macro.Phase.types:
        break;
      case macro.Phase.declarations:
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }

    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFieldDeclaration(ast.FieldDeclaration node) {
    switch (phase) {
      case macro.Phase.types:
      case macro.Phase.declarations:
        break;
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }
  }

  @override
  void visitFunctionDeclaration(ast.FunctionDeclaration node) {
    if (node.parent is! ast.CompilationUnit) {
      return;
    }

    switch (phase) {
      case macro.Phase.types:
      case macro.Phase.declarations:
        break;
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }
  }

  @override
  void visitGenericTypeAlias(ast.GenericTypeAlias node) {
    switch (phase) {
      case macro.Phase.types:
        break;
      case macro.Phase.declarations:
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }

    super.visitGenericTypeAlias(node);
  }

  @override
  void visitMethodDeclaration(ast.MethodDeclaration node) {
    switch (phase) {
      case macro.Phase.types:
      case macro.Phase.declarations:
        break;
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }
  }

  @override
  void visitMixinDeclaration(ast.MixinDeclaration node) {
    switch (phase) {
      case macro.Phase.types:
        break;
      case macro.Phase.declarations:
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }

    super.visitMixinDeclaration(node);
  }

  @override
  void visitTopLevelVariableDeclaration(ast.TopLevelVariableDeclaration node) {
    switch (phase) {
      case macro.Phase.types:
      case macro.Phase.declarations:
        break;
      case macro.Phase.definitions:
        if (node.augmentKeyword == null) {
          notAllowed.add(node);
          return;
        }
    }
  }
}
