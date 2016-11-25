// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.checks;

import 'ast.dart';
import 'transformations/flags.dart';

void runSanityChecks(Program program) {
  SanityCheck.check(program);
}

/// Checks that references refer to something in scope.
///
/// Currently only checks member, class, and type parameter references.
class SanityCheck extends RecursiveVisitor {
  final Set<Class> classes = new Set<Class>();
  final Set<TypeParameter> typeParameters = new Set<TypeParameter>();

  Member currentMember;
  Class currentClass;
  TreeNode currentParent;

  TreeNode get context => currentMember ?? currentClass;

  static void check(Program program) {
    program.accept(new SanityCheck());
  }

  defaultTreeNode(TreeNode node) {
    visitChildren(node);
  }

  void visitChildren(TreeNode node) {
    if (!identical(node.parent, currentParent)) {
      throw 'Parent pointer on ${node.runtimeType} '
          'is ${node.parent.runtimeType} '
          'but should be ${currentParent.runtimeType}';
    }
    var oldParent = currentParent;
    currentParent = node;
    node.visitChildren(this);
    currentParent = oldParent;
  }

  void declareMember(Member member) {
    if (member.transformerFlags & TransformerFlag.seenBySanityCheck != 0) {
      throw '$member has been declared more than once';
    }
    member.transformerFlags |= TransformerFlag.seenBySanityCheck;
  }

  void undeclareMember(Member member) {
    member.transformerFlags &= ~TransformerFlag.seenBySanityCheck;
  }

  visitProgram(Program program) {
    for (var library in program.libraries) {
      classes.addAll(library.classes);
      library.members.forEach(declareMember);
      for (var class_ in library.classes) {
        class_.members.forEach(declareMember);
      }
    }
    visitChildren(program);
    for (var library in program.libraries) {
      library.members.forEach(undeclareMember);
      for (var class_ in library.classes) {
        class_.members.forEach(undeclareMember);
      }
    }
  }

  defaultMember(Member node) {
    currentMember = node;
    visitChildren(node);
    currentMember = null;
  }

  visitClass(Class node) {
    currentClass = node;
    typeParameters.addAll(node.typeParameters);
    visitChildren(node);
    typeParameters.removeAll(node.typeParameters);
    currentClass = null;
  }

  visitFunctionNode(FunctionNode node) {
    typeParameters.addAll(node.typeParameters);
    visitChildren(node);
    typeParameters.removeAll(node.typeParameters);
  }

  visitFunctionType(FunctionType node) {
    for (int i = 1; i < node.namedParameters.length; ++i) {
      if (node.namedParameters[i - 1].compareTo(node.namedParameters[i]) >= 0) {
        throw 'Named parameters are not sorted on function type found in '
            '$context';
      }
    }
    typeParameters.addAll(node.typeParameters);
    for (var typeParameter in node.typeParameters) {
      typeParameter.bound?.accept(this);
    }
    visitList(node.positionalParameters, this);
    visitList(node.namedParameters, this);
    node.returnType.accept(this);
    typeParameters.removeAll(node.typeParameters);
  }

  @override
  defaultMemberReference(Member node) {
    if (node.transformerFlags & TransformerFlag.seenBySanityCheck == 0) {
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
