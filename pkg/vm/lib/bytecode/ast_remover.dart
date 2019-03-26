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
  final stashes = <Node, _Stash>{};

  ASTRemover(Component component)
      : metadata = component.metadata[new BytecodeMetadataRepository().tag] {
    stashes[component] = new _ComponentStash(component.mainMethod);
    component.mainMethod = null;
  }

  @override
  visitLibrary(Library node) {
    stashes[node] = new _LibraryStash(
        new List<Expression>.from(node.annotations),
        new List<Field>.from(node.fields),
        new List<Procedure>.from(node.procedures),
        new List<Reference>.from(node.additionalExports));

    node.annotations.clear();
    node.fields.clear();
    node.procedures.clear();
    node.additionalExports.clear();

    super.visitLibrary(node);

    return node;
  }

  @override
  visitLibraryDependency(LibraryDependency node) {
    stashes[node] = new _LibraryDependencyStash(
        new List<Expression>.from(node.annotations));

    node.annotations.clear();

    super.visitLibraryDependency(node);

    return node;
  }

  // Still referenced from function types which may appear in class supertypes.
  @override
  visitTypedef(Typedef node) {
    stashes[node] = new _TypedefStash(node.annotations);

    node.annotations = const <Expression>[];

    super.visitTypedef(node);

    // TODO(alexmarkov): fix Typedef visitor to visit these fields.
    transformList(node.positionalParameters, this, node);
    transformList(node.namedParameters, this, node);

    return node;
  }

  // May appear in typedefs.
  @override
  visitVariableDeclaration(VariableDeclaration node) {
    stashes[node] = new _VariableDeclarationStash(node.annotations);

    node.annotations = const <Expression>[];

    super.visitVariableDeclaration(node);

    return node;
  }

  @override
  visitClass(Class node) {
    stashes[node] = new _ClassStash(
        node.annotations,
        new List<Field>.from(node.fields),
        new List<Procedure>.from(node.procedures),
        new List<Constructor>.from(node.constructors));

    node.annotations = const <Expression>[];
    node.fields.clear();
    node.procedures.clear();
    node.constructors.clear();

    super.visitClass(node);

    return node;
  }

  void restoreAST() {
    stashes.forEach((Node node, _Stash stash) {
      if (node is Component) {
        _ComponentStash componentStash = stash as _ComponentStash;
        node.mainMethod = componentStash.mainMethod;
      } else if (node is Library) {
        _LibraryStash libraryStash = stash as _LibraryStash;
        node.annotations.addAll(libraryStash.annotations);
        node.fields.addAll(libraryStash.fields);
        node.procedures.addAll(libraryStash.procedures);
        node.additionalExports.addAll(libraryStash.additionalExports);
      } else if (node is LibraryDependency) {
        _LibraryDependencyStash libraryDependencyStash =
            stash as _LibraryDependencyStash;
        node.annotations.addAll(libraryDependencyStash.annotations);
      } else if (node is Typedef) {
        _TypedefStash typedefStash = stash as _TypedefStash;
        node.annotations = typedefStash.annotations;
      } else if (node is VariableDeclaration) {
        _VariableDeclarationStash variableDeclarationStash =
            stash as _VariableDeclarationStash;
        node.annotations = variableDeclarationStash.annotations;
      } else if (node is Class) {
        _ClassStash classStash = stash as _ClassStash;
        node.annotations = classStash.annotations;
        node.fields.addAll(classStash.fields);
        node.procedures.addAll(classStash.procedures);
        node.constructors.addAll(classStash.constructors);
      } else {
        throw 'Unexpected ${node.runtimeType} $node';
      }
    });
  }
}

abstract class _Stash {}

class _ClassStash extends _Stash {
  final List<Expression> annotations;
  final List<Field> fields;
  final List<Procedure> procedures;
  final List<Constructor> constructors;

  _ClassStash(
      this.annotations, this.fields, this.procedures, this.constructors);
}

class _LibraryStash extends _Stash {
  final List<Expression> annotations;
  final List<Field> fields;
  final List<Procedure> procedures;
  final List<Reference> additionalExports;

  _LibraryStash(
      this.annotations, this.fields, this.procedures, this.additionalExports);
}

class _LibraryDependencyStash extends _Stash {
  final List<Expression> annotations;

  _LibraryDependencyStash(this.annotations);
}

class _TypedefStash extends _Stash {
  final List<Expression> annotations;

  _TypedefStash(this.annotations);
}

class _VariableDeclarationStash extends _Stash {
  final List<Expression> annotations;

  _VariableDeclarationStash(this.annotations);
}

class _ComponentStash extends _Stash {
  final Procedure mainMethod;

  _ComponentStash(this.mainMethod);
}
