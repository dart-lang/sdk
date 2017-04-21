// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.checks;

import 'ast.dart';
import 'transformations/flags.dart';

void verifyProgram(Program program) {
  VerifyingVisitor.check(program);
}

class VerificationError {
  final TreeNode context;

  final TreeNode node;

  final String details;

  VerificationError(this.context, this.node, this.details);

  toString() {
    Location location;
    try {
      location = node?.location ?? context?.location;
    } catch (_) {
      // TODO(ahe): Fix the compiler instead.
    }
    if (location != null) {
      String file = location.file ?? "";
      return "$file:${location.line}:${location.column}: Verification error:"
          " $details";
    } else {
      return "Verification error: $details\n"
          "Context: '$context'.\n"
          "Node: '$node'.";
    }
  }
}

/// Checks that a kernel program is well-formed.
///
/// This does not include any kind of type checking.
class VerifyingVisitor extends RecursiveVisitor {
  final Set<Class> classes = new Set<Class>();
  final Set<TypeParameter> typeParameters = new Set<TypeParameter>();
  final List<VariableDeclaration> variableStack = <VariableDeclaration>[];
  bool classTypeParametersAreInScope = false;

  /// If true, relax certain checks for *outline* mode. For example, don't
  /// attempt to validate constructor initializers.
  bool isOutline = false;

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

  problem(TreeNode node, String details) {
    throw new VerificationError(context, node, details);
  }

  TreeNode enterParent(TreeNode node) {
    if (!identical(node.parent, currentParent)) {
      problem(
          node,
          "Incorrect parent pointer: expected '${node.parent.runtimeType}',"
          " but found: '${currentParent.runtimeType}'.");
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
      problem(member.function,
          "Member '$member' has been declared more than once.");
    }
    member.transformerFlags |= TransformerFlag.seenByVerifier;
  }

  void undeclareMember(Member member) {
    member.transformerFlags &= ~TransformerFlag.seenByVerifier;
  }

  void declareVariable(VariableDeclaration variable) {
    if (variable.flags & VariableDeclaration.FlagInScope != 0) {
      problem(variable, "Variable '$variable' declared more than once.");
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
        problem(parameter, "Type parameter '$parameter' redeclared.");
      }
    }
  }

  void undeclareTypeParameters(List<TypeParameter> parameters) {
    typeParameters.removeAll(parameters);
  }

  void checkVariableInScope(VariableDeclaration variable, TreeNode where) {
    if (variable.flags & VariableDeclaration.FlagInScope == 0) {
      problem(where, "Variable '$variable' used out of scope.");
    }
  }

  visitProgram(Program program) {
    try {
      for (var library in program.libraries) {
        for (var class_ in library.classes) {
          if (!classes.add(class_)) {
            problem(class_, "Class '$class_' declared more than once.");
          }
        }
        library.members.forEach(declareMember);
        for (var class_ in library.classes) {
          class_.members.forEach(declareMember);
        }
      }
      visitChildren(program);
    } finally {
      for (var library in program.libraries) {
        library.members.forEach(undeclareMember);
        for (var class_ in library.classes) {
          class_.members.forEach(undeclareMember);
        }
      }
      variableStack.forEach(undeclareVariable);
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
    if (!isOutline) {
      checkInitializers(node);
    }
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
        problem(currentParent,
            "Named parameters are not sorted on function type ($node).");
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
    visitChildren(node);
  }

  visitVariableSet(VariableSet node) {
    checkVariableInScope(node.variable, node);
    visitChildren(node);
  }

  @override
  visitStaticGet(StaticGet node) {
    visitChildren(node);
    if (node.target == null) {
      problem(node, "StaticGet without target.");
    }
    if (!node.target.hasGetter) {
      problem(node, "StaticGet of '${node.target}' without getter.");
    }
    if (node.target.isInstanceMember) {
      problem(node, "StaticGet of '${node.target}' that's an instance member.");
    }
  }

  @override
  visitStaticSet(StaticSet node) {
    visitChildren(node);
    if (node.target == null) {
      problem(node, "StaticSet without target.");
    }
    if (!node.target.hasSetter) {
      problem(node, "StaticSet to '${node.target}' without setter.");
    }
    if (node.target.isInstanceMember) {
      problem(node, "StaticSet to '${node.target}' that's an instance member.");
    }
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    checkTargetedInvocation(node.target, node);
    if (node.target.isInstanceMember) {
      problem(node,
          "StaticInvocation of '${node.target}' that's an instance member.");
    }
    if (node.isConst &&
        (!node.target.isConst ||
            !node.target.isExternal ||
            node.target.kind != ProcedureKind.Factory)) {
      problem(
          node,
          "Constant StaticInvocation of '${node.target}' that isn't"
          " a const external factory.");
    }
  }

  void checkTargetedInvocation(Member target, InvocationExpression node) {
    visitChildren(node);
    if (target == null) {
      problem(node, "${node.runtimeType} without target.");
    }
    if (target.function == null) {
      problem(node, "${node.runtimeType} without function.");
    }
    if (!areArgumentsCompatible(node.arguments, target.function)) {
      problem(node,
          "${node.runtimeType} with incompatible arguments for '${target}'.");
    }
    int expectedTypeParameters = target is Constructor
        ? target.enclosingClass.typeParameters.length
        : target.function.typeParameters.length;
    if (node.arguments.types.length != expectedTypeParameters) {
      problem(
          node,
          "${node.runtimeType} with wrong number of type arguments"
          " for '${target}'.");
    }
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    visitChildren(node);
    if (node.target == null) {
      problem(node, "DirectPropertyGet without target.");
    }
    if (!node.target.hasGetter) {
      problem(node, "DirectPropertyGet of '${node.target}' without getter.");
    }
    if (!node.target.isInstanceMember) {
      problem(
          node,
          "DirectPropertyGet of '${node.target}' that isn't an"
          " instance member.");
    }
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    visitChildren(node);
    if (node.target == null) {
      problem(node, "DirectPropertySet without target.");
    }
    if (!node.target.hasSetter) {
      problem(node, "DirectPropertySet of '${node.target}' without setter.");
    }
    if (!node.target.isInstanceMember) {
      problem(node, "DirectPropertySet of '${node.target}' that is static.");
    }
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    checkTargetedInvocation(node.target, node);
    if (node.receiver == null) {
      problem(node, "DirectMethodInvocation without receiver.");
    }
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    checkTargetedInvocation(node.target, node);
    if (node.target.enclosingClass.isAbstract) {
      problem(node, "ConstructorInvocation of abstract class.");
    }
    if (node.isConst && !node.target.isConst) {
      problem(
          node,
          "Constant ConstructorInvocation fo '${node.target}' that"
          " isn't const.");
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
  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    if (node.target == null) {
      problem(node, "No target.");
    } else if (node.target.parent == null) {
      problem(node, "Target has no parent.");
    } else {
      SwitchStatement statement = node.target.parent;
      for (SwitchCase switchCase in statement.cases) {
        if (switchCase == node.target) return;
      }
      problem(node, "Switch case isn't child of parent.");
    }
  }

  @override
  defaultMemberReference(Member node) {
    if (node.transformerFlags & TransformerFlag.seenByVerifier == 0) {
      problem(
          node, "Dangling reference to '$node', parent is: '${node.parent}'.");
    }
  }

  @override
  visitClassReference(Class node) {
    if (!classes.contains(node)) {
      problem(
          node, "Dangling reference to '$node', parent is: '${node.parent}'.");
    }
  }

  @override
  visitTypeParameterType(TypeParameterType node) {
    var parameter = node.parameter;
    if (!typeParameters.contains(parameter)) {
      problem(
          currentParent,
          "Type parameter '$parameter' referenced out of"
          " scope, parent is: '${parameter.parent}'.");
    }
    if (parameter.parent is Class && !classTypeParametersAreInScope) {
      problem(
          currentParent,
          "Type parameter '$parameter' referenced from"
          " static context, parent is '${parameter.parent}'.");
    }
  }

  @override
  visitInterfaceType(InterfaceType node) {
    node.visitChildren(this);
    if (node.typeArguments.length != node.classNode.typeParameters.length) {
      problem(
          currentParent,
          "Type $node provides ${node.typeArguments.length}"
          " type arguments but the class declares"
          " ${node.classNode.typeParameters.length} parameters.");
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
      throw new VerificationError(
          parent,
          node,
          "Parent pointer on '${node.runtimeType}' "
          "is '${node.parent.runtimeType}' "
          "but should be '${parent.runtimeType}'.");
    }
    var oldParent = parent;
    parent = node;
    node.visitChildren(this);
    parent = oldParent;
  }
}

void checkInitializers(Constructor constructor) {
  // TODO(ahe): I'll add more here in other CLs.
}
