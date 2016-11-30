// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.checks;

import 'ast.dart';
import 'transformations/flags.dart';

void verifyProgram(Program program) {
  VerifyingVisitor.check(program);
}

/// Checks that a kernel program is well-formed.
///
/// This does not include any kind of type checking.
class VerifyingVisitor extends RecursiveVisitor {
  final Set<Class> classes = new Set<Class>();
  final Set<TypeParameter> typeParameters = new Set<TypeParameter>();
  final List<VariableDeclaration> variableStack = <VariableDeclaration>[];
  bool classTypeParametersAreInScope = false;

  Member currentMember;
  Class currentClass;
  TreeNode currentParent;

  TreeNode get context => currentMember ?? currentClass;

  static void check(Program program) {
    program.accept(new VerifyingVisitor());
  }

  defaultTreeNode(TreeNode node) {
    visitChildren(node);
  }

  TreeNode enterParent(TreeNode node) {
    if (!identical(node.parent, currentParent)) {
      throw 'Incorrect parent pointer on ${node.runtimeType} in $context. '
          'Parent pointer is ${node.parent.runtimeType}, '
          'actual parent is ${currentParent.runtimeType}.';
    }
    var oldParent = currentParent;
    currentParent = node;
    return oldParent;
  }

  void exitParent(TreeNode oldParent) {
    currentParent = oldParent;
  }

  int enterLocalScope() => variableStack.length;

  void exitLocalScope(int stackHeight) {
    for (int i = stackHeight; i < variableStack.length; ++i) {
      undeclareVariable(variableStack[i]);
    }
    variableStack.length = stackHeight;
  }

  void visitChildren(TreeNode node) {
    var oldParent = enterParent(node);
    node.visitChildren(this);
    exitParent(oldParent);
  }

  void visitWithLocalScope(TreeNode node) {
    int stackHeight = enterLocalScope();
    visitChildren(node);
    exitLocalScope(stackHeight);
  }

  void declareMember(Member member) {
    if (member.transformerFlags & TransformerFlag.seenByVerifier != 0) {
      throw '$member has been declared more than once (${member.location})';
    }
    member.transformerFlags |= TransformerFlag.seenByVerifier;
  }

  void undeclareMember(Member member) {
    member.transformerFlags &= ~TransformerFlag.seenByVerifier;
  }

  void declareVariable(VariableDeclaration variable) {
    if (variable.flags & VariableDeclaration.FlagInScope != 0) {
      throw '$variable declared more than once (${variable.location})';
    }
    variable.flags |= VariableDeclaration.FlagInScope;
    variableStack.add(variable);
  }

  void undeclareVariable(VariableDeclaration variable) {
    variable.flags &= ~VariableDeclaration.FlagInScope;
  }

  void declareTypeParameters(List<TypeParameter> parameters) {
    for (int i = 0; i < parameters.length; ++i) {
      var parameter = parameters[i];
      if (!typeParameters.add(parameter)) {
        throw 'Type parameter $parameter redeclared in $context';
      }
    }
  }

  void undeclareTypeParameters(List<TypeParameter> parameters) {
    typeParameters.removeAll(parameters);
  }

  void checkVariableInScope(VariableDeclaration variable, TreeNode where) {
    if (variable.flags & VariableDeclaration.FlagInScope == 0) {
      throw 'Variable $variable used out of scope in $context '
          '(${where.location})';
    }
  }

  visitProgram(Program program) {
    for (var library in program.libraries) {
      for (var class_ in library.classes) {
        if (!classes.add(class_)) {
          throw 'Class $class_ declared more than once';
        }
      }
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

  visitField(Field node) {
    currentMember = node;
    var oldParent = enterParent(node);
    classTypeParametersAreInScope = !node.isStatic;
    node.initializer?.accept(this);
    classTypeParametersAreInScope = false;
    visitList(node.annotations, this);
    exitParent(oldParent);
    currentMember = null;
  }

  visitProcedure(Procedure node) {
    currentMember = node;
    var oldParent = enterParent(node);
    classTypeParametersAreInScope = !node.isStatic;
    node.function.accept(this);
    classTypeParametersAreInScope = false;
    visitList(node.annotations, this);
    exitParent(oldParent);
    currentMember = null;
  }

  visitConstructor(Constructor node) {
    currentMember = node;
    classTypeParametersAreInScope = true;
    // The constructor member needs special treatment due to parameters being
    // in scope in the initializer list.
    var oldParent = enterParent(node);
    int stackHeight = enterLocalScope();
    visitChildren(node.function);
    visitList(node.initializers, this);
    exitLocalScope(stackHeight);
    classTypeParametersAreInScope = false;
    visitList(node.annotations, this);
    exitParent(oldParent);
    classTypeParametersAreInScope = false;
    currentMember = null;
  }

  visitClass(Class node) {
    currentClass = node;
    declareTypeParameters(node.typeParameters);
    var oldParent = enterParent(node);
    classTypeParametersAreInScope = false;
    visitList(node.annotations, this);
    classTypeParametersAreInScope = true;
    visitList(node.typeParameters, this);
    visitList(node.fields, this);
    visitList(node.constructors, this);
    visitList(node.procedures, this);
    exitParent(oldParent);
    undeclareTypeParameters(node.typeParameters);
    currentClass = null;
  }

  visitFunctionNode(FunctionNode node) {
    declareTypeParameters(node.typeParameters);
    visitWithLocalScope(node);
    undeclareTypeParameters(node.typeParameters);
  }

  visitFunctionType(FunctionType node) {
    for (int i = 1; i < node.namedParameters.length; ++i) {
      if (node.namedParameters[i - 1].compareTo(node.namedParameters[i]) >= 0) {
        throw 'Named parameters are not sorted on function type found in '
            '$context';
      }
    }
    declareTypeParameters(node.typeParameters);
    for (var typeParameter in node.typeParameters) {
      typeParameter.bound?.accept(this);
    }
    visitList(node.positionalParameters, this);
    visitList(node.namedParameters, this);
    node.returnType.accept(this);
    undeclareTypeParameters(node.typeParameters);
  }

  visitBlock(Block node) {
    visitWithLocalScope(node);
  }

  visitForStatement(ForStatement node) {
    visitWithLocalScope(node);
  }

  visitForInStatement(ForInStatement node) {
    visitWithLocalScope(node);
  }

  visitLet(Let node) {
    visitWithLocalScope(node);
  }

  visitCatch(Catch node) {
    visitWithLocalScope(node);
  }

  visitVariableDeclaration(VariableDeclaration node) {
    visitChildren(node);
    declareVariable(node);
  }

  visitVariableGet(VariableGet node) {
    checkVariableInScope(node.variable, node);
  }

  visitVariableSet(VariableSet node) {
    checkVariableInScope(node.variable, node);
    visitChildren(node);
  }

  @override
  visitStaticGet(StaticGet node) {
    visitChildren(node);
    if (node.target == null) {
      throw 'StaticGet without target found in $context.';
    }
    if (!node.target.hasGetter) {
      throw 'StaticGet to ${node.target} without getter found in $context';
    }
    if (node.target.isInstanceMember) {
      throw 'StaticGet to ${node.target} that is not static found in $context';
    }
  }

  @override
  visitStaticSet(StaticSet node) {
    visitChildren(node);
    if (node.target == null) {
      throw 'StaticSet without target found in $context.';
    }
    if (!node.target.hasSetter) {
      throw 'StaticSet to ${node.target} without setter found in $context';
    }
    if (node.target.isInstanceMember) {
      throw 'StaticSet to ${node.target} that is not static found in $context';
    }
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    visitChildren(node);
    if (node.target == null) {
      throw 'StaticInvocation without target found in $context.';
    }
    if (node.target.isInstanceMember) {
      throw 'StaticInvocation to ${node.target} that is not static found in '
          '$context';
    }
    if (!areArgumentsCompatible(node.arguments, node.target.function)) {
      throw 'StaticInvocation with incompatible arguments to '
          '${node.target} found in $context';
    }
    if (node.arguments.types.length !=
        node.target.function.typeParameters.length) {
      throw 'Wrong number of type arguments provided in StaticInvocation '
          'to ${node.target} found in $context';
    }
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    visitChildren(node);
    if (node.target == null) {
      throw 'DirectPropertyGet without target found in $context.';
    }
    if (!node.target.hasGetter) {
      throw 'DirectPropertyGet to ${node.target} without getter found in '
          '$context';
    }
    if (!node.target.isInstanceMember) {
      throw 'DirectPropertyGet to ${node.target} that is static found in '
          '$context';
    }
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    visitChildren(node);
    if (node.target == null) {
      throw 'DirectPropertySet without target found in $context.';
    }
    if (!node.target.hasSetter) {
      throw 'DirectPropertyGet to ${node.target} without setter found in '
          '$context';
    }
    if (!node.target.isInstanceMember) {
      throw 'DirectPropertySet to ${node.target} that is static found in '
          '$context';
    }
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    visitChildren(node);
    if (node.target == null) {
      throw 'DirectMethodInvocation without target found in $context.';
    }
    if (!node.target.isInstanceMember) {
      throw 'DirectMethodInvocation to ${node.target} that is static found in '
          '$context';
    }
    if (!areArgumentsCompatible(node.arguments, node.target.function)) {
      throw 'DirectMethodInvocation with incompatible arguments to '
          '${node.target} found in $context';
    }
    if (node.arguments.types.length !=
        node.target.function.typeParameters.length) {
      throw 'Wrong number of type arguments provided in DirectMethodInvocation '
          'to ${node.target} found in $context';
    }
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    visitChildren(node);
    if (node.target == null) {
      throw 'ConstructorInvocation without target found in $context.';
    }
    if (node.target.enclosingClass.isAbstract) {
      throw 'ConstructorInvocation to abstract class found in $context';
    }
    if (!areArgumentsCompatible(node.arguments, node.target.function)) {
      throw 'ConstructorInvocation with incompatible arguments to '
          '${node.target} found in $context';
    }
    if (node.arguments.types.length !=
        node.target.enclosingClass.typeParameters.length) {
      throw 'Wrong number of type arguments provided in ConstructorInvocation '
          'to ${node.target} found in $context';
    }
  }

  bool areArgumentsCompatible(Arguments arguments, FunctionNode function) {
    if (arguments.positional.length < function.requiredParameterCount) {
      return false;
    }
    if (arguments.positional.length > function.positionalParameters.length) {
      return false;
    }
    namedLoop:
    for (int i = 0; i < arguments.named.length; ++i) {
      var argument = arguments.named[i];
      String name = argument.name;
      for (int j = 0; j < function.namedParameters.length; ++j) {
        if (function.namedParameters[j].name == name) continue namedLoop;
      }
      return false;
    }
    return true;
  }

  @override
  defaultMemberReference(Member node) {
    if (node.transformerFlags & TransformerFlag.seenByVerifier == 0) {
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
    var parameter = node.parameter;
    if (!typeParameters.contains(parameter)) {
      throw 'Type parameter $parameter referenced out of scope in $context.\n'
          'Parent pointer is set to ${parameter.parent}';
    }
    if (parameter.parent is Class && !classTypeParametersAreInScope) {
      throw 'Type parameter $parameter referenced from static context '
          'in $context.\n'
          'Parent pointer is set to ${parameter.parent}';
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
