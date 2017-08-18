// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure.info;

import '../../ast.dart'
    show
        Class,
        Constructor,
        Field,
        FunctionDeclaration,
        FunctionNode,
        Member,
        Procedure,
        ThisExpression,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VariableGet,
        VariableSet,
        visitList;

import '../../visitor.dart' show RecursiveVisitor;

class ClosureInfo extends RecursiveVisitor {
  FunctionNode currentFunction;

  final Set<VariableDeclaration> variables = new Set<VariableDeclaration>();

  // For captured constructor parameters, we need to distinquish the following
  // states:
  //
  // - only used inside initializers (INSIDE_INITIALIZER)
  // - only used in body (OUTSIDE_INITIALIZER)
  // - used in body and initializers (OUTSIDE_INITIALIZER | INSIDE_INITIALIZER)
  static const int OUTSIDE_INITIALIZER = 1;
  static const int INSIDE_INITIALIZER = 2;
  int captureFlags = OUTSIDE_INITIALIZER;
  final Map<VariableDeclaration, int> parameterUses =
      <VariableDeclaration, int>{};

  final Map<VariableDeclaration, FunctionNode> function =
      <VariableDeclaration, FunctionNode>{};

  /// Map from functions to set of type variables captured within them.
  final Map<FunctionNode, Set<TypeParameter>> typeVariables =
      <FunctionNode, Set<TypeParameter>>{};

  /// Map from members to synthetic variables for accessing `this` in a local
  /// function.
  final Map<FunctionNode, VariableDeclaration> thisAccess =
      <FunctionNode, VariableDeclaration>{};

  final Set<String> currentMemberLocalNames = new Set<String>();

  final Map<FunctionNode, String> localNames = <FunctionNode, String>{};

  Class currentClass;

  Member currentMember;

  FunctionNode currentMemberFunction;

  bool get isOuterMostContext {
    return currentFunction == null || currentMemberFunction == currentFunction;
  }

  void beginMember(Member member, [FunctionNode function]) {
    currentMemberLocalNames.clear();
    if (function != null) {
      localNames[function] = computeUniqueLocalName(member.name.name);
    }
    currentMember = member;
    currentMemberFunction = function;
  }

  void endMember() {
    currentMember = null;
    currentMemberFunction = null;
  }

  visitClass(Class node) {
    currentClass = node;
    super.visitClass(node);
    currentClass = null;
  }

  visitConstructor(Constructor node) {
    /// [currentFunction] should be set to [currentMemberFunction] before
    /// visiting the [FunctionNode] of the constructor, because initializers may
    /// use constructor parameters and it shouldn't be treated as capturing
    /// them.  Consider the following code:
    ///
    ///     class A {
    ///       int x;
    ///       A(int x)  /* [x] is visible in initializers and body. */
    ///         : this.x = x {  /* Initializer. */
    ///         /* Constructor body. */
    ///       }
    ///     }
    ///
    /// Here the parameter shouldn't be captured into a context in the
    /// initializer.  However, [currentFunction] is `null` if not set, and
    /// `function[node.variable]` in this case points to the [FunctionNode] of
    /// the constructor (which is not `null`).  It leads to `x` being treated as
    /// captured, because it's seen as used outside of the function where it is
    /// declared.  In turn, it leads to unnecessary context creation and usage.
    ///
    /// Another consideration is the order of visiting children of the
    /// constructor: [node.function] should be visited before
    /// [node.initializers], because [node.function] contains declarations of
    /// the parameters that may be used in the initializers.  If the nodes are
    /// visited in another order, the encountered parameters in initializers
    /// are treated as captured, because they are not yet associated with the
    /// function.
    beginMember(node, node.function);
    saveCurrentFunction(() {
      currentFunction = currentMemberFunction;

      visitList(node.annotations, this);
      node.name?.accept(this);

      visitList(node.function.typeParameters, this);
      visitList(node.function.positionalParameters, this);
      visitList(node.function.namedParameters, this);

      assert(captureFlags == OUTSIDE_INITIALIZER);
      captureFlags = INSIDE_INITIALIZER;
      visitList(node.initializers, this);
      captureFlags = OUTSIDE_INITIALIZER;

      for (var decl in node.function.positionalParameters) {
        var use = parameterUses[decl];
        if (use == 0) parameterUses.remove(decl);
      }
      for (var decl in node.function.namedParameters) {
        var use = parameterUses[decl];
        if (use == 0) parameterUses.remove(decl);
      }

      node.function.accept(this);
    });
    endMember();
  }

  visitProcedure(Procedure node) {
    beginMember(node, node.function);
    super.visitProcedure(node);
    endMember();
  }

  visitField(Field node) {
    beginMember(node);
    super.visitField(node);
    endMember();
  }

  String computeUniqueLocalName([String name]) {
    if (name == null || name.isEmpty) {
      name = "function";
    }
    if (currentFunction == null) {
      if (currentMember != null) {
        name = "${currentMember.name.name}#$name";
      }
      if (currentClass != null) {
        name = "${currentClass.name}#$name";
      }
    } else {
      name = "${localNames[currentFunction]}#$name";
    }
    int count = 1;
    String candidate = name;
    while (currentMemberLocalNames.contains(candidate)) {
      candidate = "$name#${count++}";
    }
    currentMemberLocalNames.add(candidate);
    return candidate;
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    assert(!localNames.containsKey(node));
    localNames[node.function] = computeUniqueLocalName(node.variable.name);
    return super.visitFunctionDeclaration(node);
  }

  visitFunctionNode(FunctionNode node) {
    localNames.putIfAbsent(node, computeUniqueLocalName);

    saveCurrentFunction(() {
      currentFunction = node;
      node.visitChildren(this);
    });

    Set<TypeParameter> capturedTypeVariables = typeVariables[node];
    if (capturedTypeVariables != null && !isOuterMostContext) {
      // Propagate captured type variables to enclosing function.
      typeVariables
          .putIfAbsent(currentFunction, () => new Set<TypeParameter>())
          .addAll(
              // 't.parent == currentFunction' will be true if the type variable
              // is defined by one of our type parameters.
              capturedTypeVariables.where((t) => t.parent != currentFunction));
    }
  }

  visitVariableDeclaration(VariableDeclaration node) {
    function[node] = currentFunction;
    node.visitChildren(this);
  }

  visitVariableGet(VariableGet node) {
    if (function[node.variable] != currentFunction) {
      variables.add(node.variable);
    }
    if (node.variable.parent.parent is Constructor) {
      parameterUses.putIfAbsent(node.variable, () => 0);
      parameterUses[node.variable] |= captureFlags;
    }
    node.visitChildren(this);
  }

  visitVariableSet(VariableSet node) {
    if (function[node.variable] != currentFunction) {
      variables.add(node.variable);
    }
    if (node.variable.parent.parent is Constructor) {
      parameterUses.putIfAbsent(node.variable, () => 0);
      parameterUses[node.variable] |= captureFlags;
    }
    node.visitChildren(this);
  }

  visitTypeParameterType(TypeParameterType node) {
    if (!isOuterMostContext && node.parameter.parent != currentFunction) {
      typeVariables
          .putIfAbsent(currentFunction, () => new Set<TypeParameter>())
          .add(node.parameter);
    }
  }

  visitThisExpression(ThisExpression node) {
    if (!isOuterMostContext) {
      thisAccess.putIfAbsent(
          currentMemberFunction, () => new VariableDeclaration("#self"));
    }
  }

  saveCurrentFunction(void f()) {
    var saved = currentFunction;
    try {
      f();
    } finally {
      currentFunction = saved;
    }
  }
}
