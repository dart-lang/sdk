// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// A local function or function expression.
class Lambda {
  final FunctionNode functionNode;
  final w.DefinedFunction function;

  Lambda(this.functionNode, this.function);
}

/// The context for one or more closures, containing their captured variables.
///
/// Contexts can be nested, corresponding to the scopes covered by the contexts.
/// Each local function, function expression or loop (`while`, `do`/`while` or
/// `for`) gives rise to its own context nested inside the context of its
/// surrounding scope. At runtime, each context has a reference to its parent
/// context.
///
/// Closures corresponding to local functions or function expressions in the
/// same scope share the same context. Thus, a closure can potentially keep more
/// values alive than the ones captured by the closure itself.
///
/// A context may be empty (containing no captured variables), in which case it
/// is skipped in the context parent chain and never allocated. A context can
/// also be skipped if it only contains variables that are not in scope for the
/// child context (and its descendants).
class Context {
  /// The node containing the scope covered by the context. This is either a
  /// [FunctionNode] (for members, local functions and function expressions),
  /// a [ForStatement], a [DoStatement] or a [WhileStatement].
  final TreeNode owner;

  /// The parent of this context, corresponding to the lexically enclosing
  /// owner. This is null if the context is a member context, or if all contexts
  /// in the parent chain are skipped.
  final Context? parent;

  /// The variables captured by this context.
  final List<VariableDeclaration> variables = [];

  /// Whether this context contains a captured `this`. Only member contexts can.
  bool containsThis = false;

  /// The Wasm struct representing this context at runtime.
  late final w.StructType struct;

  /// The local variable currently pointing to this context. Used during code
  /// generation.
  late w.Local currentLocal;

  bool get isEmpty => variables.isEmpty && !containsThis;

  int get parentFieldIndex {
    assert(parent != null);
    return 0;
  }

  int get thisFieldIndex {
    assert(containsThis);
    return 0;
  }

  Context(this.owner, this.parent);
}

/// A captured variable.
class Capture {
  final VariableDeclaration variable;
  late final Context context;
  late final int fieldIndex;
  bool written = false;

  Capture(this.variable);

  w.ValueType get type => context.struct.fields[fieldIndex].type.unpacked;
}

/// Compiler passes to find all captured variables and construct the context
/// tree for a member.
class Closures {
  final CodeGenerator codeGen;
  final Map<VariableDeclaration, Capture> captures = {};
  bool isThisCaptured = false;
  final Map<FunctionNode, Lambda> lambdas = {};
  final Map<TreeNode, Context> contexts = {};
  final Set<FunctionDeclaration> closurizedFunctions = {};

  Closures(this.codeGen);

  Translator get translator => codeGen.translator;

  void findCaptures(Member member) {
    var find = CaptureFinder(this, member);
    if (member is Constructor) {
      Class cls = member.enclosingClass;
      for (Field field in cls.fields) {
        if (field.isInstanceMember && field.initializer != null) {
          field.initializer!.accept(find);
        }
      }
    }
    member.accept(find);
  }

  void collectContexts(TreeNode node, {TreeNode? container}) {
    if (captures.isNotEmpty || isThisCaptured) {
      node.accept(ContextCollector(this, container));
    }
  }

  void buildContexts() {
    // Make struct definitions
    for (Context context in contexts.values) {
      if (!context.isEmpty) {
        context.struct = translator.structType("<context>");
      }
    }

    // Build object layouts
    for (Context context in contexts.values) {
      if (!context.isEmpty) {
        w.StructType struct = context.struct;
        if (context.parent != null) {
          assert(!context.containsThis);
          struct.fields.add(w.FieldType(
              w.RefType.def(context.parent!.struct, nullable: true)));
        }
        if (context.containsThis) {
          struct.fields.add(w.FieldType(
              codeGen.preciseThisLocal!.type.withNullability(true)));
        }
        for (VariableDeclaration variable in context.variables) {
          int index = struct.fields.length;
          struct.fields.add(w.FieldType(
              translator.translateType(variable.type).withNullability(true)));
          captures[variable]!.fieldIndex = index;
        }
      }
    }
  }
}

class CaptureFinder extends RecursiveVisitor {
  final Closures closures;
  final Member member;
  final Map<VariableDeclaration, int> variableDepth = {};
  int depth = 0;

  CaptureFinder(this.closures, this.member);

  Translator get translator => closures.translator;

  @override
  void visitAssertStatement(AssertStatement node) {}

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (depth > 0) {
      variableDepth[node] = depth;
    }
    super.visitVariableDeclaration(node);
  }

  void _visitVariableUse(VariableDeclaration variable) {
    int declDepth = variableDepth[variable] ?? 0;
    assert(declDepth <= depth);
    if (declDepth < depth) {
      closures.captures[variable] = Capture(variable);
    } else if (variable.parent is FunctionDeclaration) {
      closures.closurizedFunctions.add(variable.parent as FunctionDeclaration);
    }
  }

  @override
  void visitVariableGet(VariableGet node) {
    _visitVariableUse(node.variable);
    super.visitVariableGet(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    _visitVariableUse(node.variable);
    super.visitVariableSet(node);
  }

  void _visitThis() {
    if (depth > 0) {
      closures.isThisCaptured = true;
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _visitThis();
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    _visitThis();
    super.visitSuperMethodInvocation(node);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    if (node.parameter.parent == member.enclosingClass) {
      _visitThis();
    }
  }

  void _visitLambda(FunctionNode node) {
    if (node.positionalParameters.length != node.requiredParameterCount ||
        node.namedParameters.isNotEmpty) {
      throw "Not supported: Optional parameters for "
          "function expression or local function at ${node.location}";
    }
    int parameterCount = node.requiredParameterCount;
    w.FunctionType type = translator.closureFunctionType(parameterCount);
    w.DefinedFunction function =
        translator.m.addFunction(type, "$member (closure)");
    closures.lambdas[node] = Lambda(node, function);

    depth++;
    node.visitChildren(this);
    depth--;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _visitLambda(node.function);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Variable is in outer scope
    node.variable.accept(this);
    _visitLambda(node.function);
  }
}

class ContextCollector extends RecursiveVisitor {
  final Closures closures;
  Context? currentContext;

  ContextCollector(this.closures, TreeNode? container) {
    if (container != null) {
      currentContext = closures.contexts[container]!;
    }
  }

  @override
  void visitAssertStatement(AssertStatement node) {}

  void _newContext(TreeNode node) {
    bool outerMost = currentContext == null;
    Context? oldContext = currentContext;
    Context? parent = currentContext;
    while (parent != null && parent.isEmpty) parent = parent.parent;
    currentContext = Context(node, parent);
    if (closures.isThisCaptured && outerMost) {
      currentContext!.containsThis = true;
    }
    closures.contexts[node] = currentContext!;
    node.visitChildren(this);
    currentContext = oldContext;
  }

  @override
  void visitConstructor(Constructor node) {
    node.function.accept(this);
    currentContext = closures.contexts[node.function]!;
    visitList(node.initializers, this);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    _newContext(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _newContext(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _newContext(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _newContext(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    Capture? capture = closures.captures[node];
    if (capture != null) {
      currentContext!.variables.add(node);
      capture.context = currentContext!;
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    closures.captures[node.variable]?.written = true;
    super.visitVariableSet(node);
  }
}
