// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure.info;

import '../../ast.dart'
    show
        Class,
        Constructor,
        Field,
        FieldInitializer,
        FunctionDeclaration,
        FunctionNode,
        LocalInitializer,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        PropertyGet,
        RedirectingInitializer,
        SuperInitializer,
        ThisExpression,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VariableGet,
        VariableSet;

import '../../visitor.dart' show RecursiveVisitor;

class ClosureInfo extends RecursiveVisitor {
  FunctionNode currentFunction;
  final Map<VariableDeclaration, FunctionNode> function =
      <VariableDeclaration, FunctionNode>{};

  final Set<VariableDeclaration> variables = new Set<VariableDeclaration>();

  final Map<FunctionNode, Set<TypeParameter>> typeVariables =
      <FunctionNode, Set<TypeParameter>>{};

  /// Map from members to synthetic variables for accessing `this` in a local
  /// function.
  final Map<FunctionNode, VariableDeclaration> thisAccess =
      <FunctionNode, VariableDeclaration>{};

  final Set<String> currentMemberLocalNames = new Set<String>();

  final Map<FunctionNode, String> localNames = <FunctionNode, String>{};

  /// Contains all names used as getter through a [PropertyGet].
  final Set<Name> invokedGetters = new Set<Name>();

  /// Contains all names of declared regular instance methods (not including
  /// accessors and operators).
  final Set<Name> declaredInstanceMethodNames = new Set<Name>();

  Class currentClass;

  Member currentMember;

  FunctionNode currentMemberFunction;

  bool get isOuterMostContext {
    return currentFunction == null || currentMemberFunction == currentFunction;
  }

  /// Maps the names of all instance methods that may be torn off (aka
  /// implicitly closurized) to `${name.name}#get`.
  Map<Name, Name> get tearOffGetterNames {
    // TODO(dmitryas): Add support for tear-offs. When added, uncomment this.
    //
    // Map<Name, Name> result = <Name, Name>{};
    // for (Name name in declaredInstanceMethodNames) {
    //   if (invokedGetters.contains(name)) {
    //     result[name] = new Name("${name.name}#get", name.library);
    //   }
    // }
    // return result;
    //
    // Currently an empty map is returned, so no tear-offs supporting functions
    // and getters are generated, and no property-get targets are renamed.
    return <Name, Name>{};
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
    beginMember(node, node.function);
    saveCurrentFunction(() {
      currentFunction = currentMemberFunction;
      super.visitConstructor(node);
    });
    endMember();
  }

  visitProcedure(Procedure node) {
    beginMember(node, node.function);
    if (node.isInstanceMember && node.kind == ProcedureKind.Method) {
      // Ignore the `length` method of [File] subclasses for now, as they
      // will force us to rename the `length` getter (kernel issue #43).
      // TODO(ahe): remove this condition.
      Class parent = node.parent;
      if (node.name.name != "length" ||
          parent.enclosingLibrary.importUri.toString() != "dart:io") {
        declaredInstanceMethodNames.add(node.name);
      }
    }
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
          .addAll(capturedTypeVariables);
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
    node.visitChildren(this);
  }

  visitVariableSet(VariableSet node) {
    if (function[node.variable] != currentFunction) {
      variables.add(node.variable);
    }
    node.visitChildren(this);
  }

  visitTypeParameterType(TypeParameterType node) {
    if (!isOuterMostContext) {
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

  visitPropertyGet(PropertyGet node) {
    invokedGetters.add(node.name);
    super.visitPropertyGet(node);
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
