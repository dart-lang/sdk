// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.checks;

import 'ast.dart';

void runSanityChecks(Program program) {
  CheckParentPointers.check(program);
  CheckReferences.check(program);
}

class CheckParentPointers extends Visitor {
  static void check(TreeNode node) {
    node.accept(new CheckParentPointers(node.parent));
  }

  TreeNode parent;

  CheckParentPointers([this.parent]);

  defaultTreeNode(TreeNode node) {
    if (node.parent != parent) {
      throw 'Parent pointer on ${node.runtimeType} '
          'is ${node.parent.runtimeType} '
          'but should be ${parent.runtimeType}';
    }
    var oldParent = parent;
    parent = node;
    node.visitChildren(this);
    parent = oldParent;
  }
}

/// Checks that references refer to something in scope.
///
/// Currently only checks member, class, and type parameter references.
class CheckReferences extends RecursiveVisitor {
  final Set<Member> members = new Set<Member>();
  final Set<Class> classes = new Set<Class>();
  final Set<TypeParameter> typeParameters = new Set<TypeParameter>();

  Member currentMember;
  Class currentClass;

  TreeNode get context => currentMember ?? currentClass;

  static void check(Program program) {
    program.accept(new CheckReferences());
  }

  visitProgram(Program program) {
    for (var library in program.libraries) {
      classes.addAll(library.classes);
      members.addAll(library.members);
      for (var class_ in library.classes) {
        members.addAll(class_.members);
      }
    }
    program.visitChildren(this);
  }

  defaultMember(Member node) {
    currentMember = node;
    node.visitChildren(this);
    currentMember = null;
  }

  visitClass(Class node) {
    currentClass = node;
    typeParameters.addAll(node.typeParameters);
    node.visitChildren(this);
    typeParameters.removeAll(node.typeParameters);
    currentClass = null;
  }

  visitFunctionNode(FunctionNode node) {
    for (int i = 1; i < node.namedParameters.length; ++i) {
      if (node.namedParameters[i - 1].compareTo(node.namedParameters[i]) >= 0) {
        throw 'Named parameters are not sorted on function found in $context';
      }
    }
    typeParameters.addAll(node.typeParameters);
    node.visitChildren(this);
    typeParameters.removeAll(node.typeParameters);
  }

  visitFunctionType(FunctionType node) {
    for (int i = 1; i < node.namedParameters.length; ++i) {
      if (node.namedParameters[i - 1].compareTo(node.namedParameters[i]) >= 0) {
        throw 'Named parameters are not sorted on function type found in '
            '$context';
      }
    }
    node.visitChildren(this);
  }

  @override
  defaultMemberReference(Member node) {
    if (!members.contains(node)) {
      throw 'Dangling reference to $node found in $context.\n'
          'Parent pointer is set to ${node.parent}';
    }
  }

  @override
  visitClassReference(Class node) {
    if (!classes.contains(node)) {
      throw 'Dangling reference to $node found in $context.\n'
          'Parent pointer is set to ${node.parent}';
    }
  }

  @override
  visitTypeParameterType(TypeParameterType node) {
    if (!typeParameters.contains(node.parameter)) {
      throw 'Type parameter ${node.parameter} referenced out of scope '
          'in $context.\n'
          'Parent pointer is set to ${node.parameter.parent}';
    }
  }

  @override
  visitInterfaceType(InterfaceType node) {
    node.visitChildren(this);
    if (node.typeArguments.length != node.classNode.typeParameters.length) {
      throw 'Type $node provides ${node.typeArguments.length} type arguments '
          'but the class declares ${node.classNode.typeParameters.length} '
          'parameters. Found in $context.';
    }
  }
}

class SizeCounter extends RecursiveVisitor {
  int size = 0;
  int emptyArguments = 0;

  void visit(TreeNode node) => node.accept(this);

  visitArguments(Arguments node) {
    super.visitArguments(node);
    if (node.positional.isEmpty &&
        node.positional.isEmpty &&
        node.types.isEmpty) {
      ++emptyArguments;
    }
  }

  defaultNode(Node node) {
    ++size;
    node.visitChildren(this);
  }
}
