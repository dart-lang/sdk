// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/front_end/scopes.dart';
import 'package:kernel/ast.dart' as ast;

/// Implementation of [Scopes] by computing scopes and contexts.
final class ComputedScopes implements Scopes {
  final ast.Member member;
  final bool enableAsserts;
  final Map<ast.TreeNode, ScopeDesc> _scopes = {};
  final Map<Variable, VarDesc> _vars = {};
  final Map<ast.TreeNode, FunctionDesc> _functions = {};
  Variable? thisVariable;

  ComputedScopes(this.member, {required this.enableAsserts}) {
    if (member.isInstanceMember || member is ast.Constructor) {
      thisVariable =
          member.function?.thisVariable ?? ast.VariableDeclaration('this');
    }
    final builder = _ScopeBuilder(this);
    member.accept(builder);
    builder.allocateContexts();
  }

  @override
  Scope? getScope(ast.TreeNode node) =>
      node is ast.FunctionNode ? _scopes[node.parent!] : _scopes[node];

  @override
  Context getVariableContext(Variable variable) => _vars[variable]!.context!;

  @override
  List<Context> getCapturedContexts(
    ast.FunctionNode function, {
    required bool enableAsserts,
  }) => _functions[function.parent]!.capturedContexts;

  @override
  Variable? getThisVariable(ast.Member member) {
    if (member != this.member) {
      throw '$member != ${this.member}';
    }
    return thisVariable;
  }
}

class VarDesc {
  final Variable declaration;
  ScopeDesc scope;
  bool isCaptured = false;
  ContextDesc? context;

  VarDesc(this.declaration, this.scope) {
    scope.vars.add(this);
  }

  FunctionDesc get function => scope.function;

  void capture() {
    assert(context == null);
    isCaptured = true;
  }
}

final class ContextDesc implements Context {
  final bool captured;

  @override
  final List<Variable> variables = [];

  ContextDesc({required this.captured});

  @override
  bool isCaptured({required bool enableAsserts}) => captured;

  @override
  String toString() =>
      'Context[captured: $captured, variables: ${variables.map((v) => v.name).join(', ')}]';
}

class ScopeDesc implements Scope {
  @override
  late final List<ContextDesc> contexts = [];

  final ScopeDesc? parent;
  final FunctionDesc function;
  final int loopDepth;
  final List<VarDesc> vars = <VarDesc>[];
  ContextDesc? capturedContext;
  bool allocated = false;

  ScopeDesc(this.parent, this.function, this.loopDepth);

  bool canOwnContextFor(ScopeDesc scope) =>
      function == scope.function && loopDepth == scope.loopDepth;
}

class FunctionDesc {
  final ast.TreeNode declaration;
  final FunctionDesc? parent;
  final Set<VarDesc> accessedCapturedVars = {};
  late final List<ContextDesc> capturedContexts;

  FunctionDesc(this.declaration, this.parent);
}

class _ScopeBuilder extends ast.RecursiveVisitor {
  final ComputedScopes scopes;

  ScopeDesc? _currentScopeInternal;
  ScopeDesc get _currentScope => _currentScopeInternal!;

  FunctionDesc? _currentFunctionInternal;
  FunctionDesc get _currentFunction => _currentFunctionInternal!;

  int _loopDepth = 0;

  _ScopeBuilder(this.scopes);

  void _visitFunction(ast.TreeNode node) {
    final savedLoopDepth = _loopDepth;
    _loopDepth = 0;

    _enterFunction(node);

    if (node is ast.Member && scopes.thisVariable != null) {
      _declareVariable(scopes.thisVariable!);
    }

    if (node is ast.Field) {
      node.initializer?.accept(this);
    } else {
      final function = switch (node) {
        ast.Procedure() => node.function,
        ast.Constructor() => node.function,
        ast.LocalFunction() => node.function,
        _ => throw 'Unexpected function ${node.runtimeType} $node',
      };

      ast.visitList(function.positionalParameters, this);
      ast.visitList(function.namedParameters, this);
      function.emittedValueType?.accept(this);

      if (node is ast.Constructor) {
        for (var field in node.enclosingClass.fields) {
          if (!field.isStatic && field.initializer != null) {
            field.initializer!.accept(this);
          }
        }
        ast.visitList(node.initializers, this);
      }

      function.body?.accept(this);
    }

    _leaveFunction();

    _loopDepth = savedLoopDepth;
  }

  void _enterFunction(ast.TreeNode node) {
    _currentFunctionInternal = FunctionDesc(node, _currentFunctionInternal);
    assert(scopes._functions[node] == null);
    scopes._functions[node] = _currentFunctionInternal!;
    _enterScope(node);
  }

  void _leaveFunction() {
    _leaveScope();
    _currentFunctionInternal = _currentFunction.parent;
  }

  void _enterScope(ast.TreeNode node) {
    _currentScopeInternal = ScopeDesc(
      _currentScopeInternal,
      _currentFunction,
      _loopDepth,
    );
    assert(scopes._scopes[node] == null);
    scopes._scopes[node] = _currentScope;
  }

  void _leaveScope() {
    _currentScopeInternal = _currentScope.parent;
  }

  void allocateContexts() {
    for (final scope in scopes._scopes.values) {
      assert(scope.contexts.isEmpty);
      assert(scope.capturedContext == null);
      assert(scope.parent == null || scope.parent!.allocated);

      ContextDesc? regularContext;
      ContextDesc? capturedContext;
      for (final v in scope.vars) {
        if (v.isCaptured) {
          if (capturedContext == null) {
            for (
              ScopeDesc? contextOwner = scope;
              contextOwner != null && contextOwner.canOwnContextFor(scope);
              contextOwner = contextOwner.parent
            ) {
              if (contextOwner.capturedContext != null) {
                capturedContext = scope.capturedContext =
                    contextOwner.capturedContext;
                break;
              }
            }
            if (capturedContext == null) {
              capturedContext = scope.capturedContext = ContextDesc(
                captured: true,
              );
              scope.contexts.add(capturedContext);
            }
          }
          v.context = capturedContext;
          capturedContext.variables.add(v.declaration);
        } else {
          if (regularContext == null) {
            regularContext = ContextDesc(captured: false);
            scope.contexts.add(regularContext);
          }
          v.context = regularContext;
          regularContext.variables.add(v.declaration);
        }
      }
      scope.allocated = true;
    }

    for (final f in scopes._functions.values) {
      f.capturedContexts = {
        for (final v in f.accessedCapturedVars) v.context!,
      }.toList();
    }
  }

  void _declareVariable(Variable variable) {
    final v = VarDesc(variable, _currentScope);
    assert(
      scopes._vars[variable] == null,
      'Double declaring variable ${variable}!',
    );
    scopes._vars[variable] = v;
  }

  void _useVariable(Variable variable) {
    final VarDesc? v = scopes._vars[variable];
    if (v == null) {
      throw 'Variable $variable is used before declared';
    }
    if (v.function != _currentFunction) {
      v.capture();
      for (var f = _currentFunction; f != v.function; f = f.parent!) {
        f.accessedCapturedVars.add(v);
      }
    }
  }

  void _useThis() {
    _useVariable(scopes.thisVariable!);
  }

  void _visitWithScope(ast.TreeNode node) {
    _enterScope(node);
    node.visitChildren(this);
    _leaveScope();
  }

  @override
  void defaultMember(ast.Member node) {
    _visitFunction(node);
  }

  @override
  void visitFunctionDeclaration(ast.FunctionDeclaration node) {
    if (scopes.thisVariable != null) {
      // Closure creation may load receiver to get instantiator type arguments.
      _useThis();
    }
    node.variable.accept(this);
    _visitFunction(node);
  }

  @override
  void visitFunctionExpression(ast.FunctionExpression node) {
    if (scopes.thisVariable != null) {
      // Closure creation may load receiver to get instantiator type arguments.
      _useThis();
    }
    _visitFunction(node);
  }

  @override
  void visitLocalFunctionInvocation(ast.LocalFunctionInvocation node) {
    _useVariable(node.variable);
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclaration(ast.VariableDeclaration node) {
    _declareVariable(node.variable);
    node.visitChildren(this);
  }

  @override
  void visitVariableGet(ast.VariableGet node) {
    _useVariable(node.variable);
  }

  @override
  void visitVariableSet(ast.VariableSet node) {
    _useVariable(node.variable);
    node.visitChildren(this);
  }

  @override
  void visitThisExpression(ast.ThisExpression node) {
    _useThis();
  }

  @override
  void visitSuperMethodInvocation(ast.SuperMethodInvocation node) {
    _useThis();
    node.visitChildren(this);
  }

  @override
  void visitSuperPropertyGet(ast.SuperPropertyGet node) {
    _useThis();
    node.visitChildren(this);
  }

  @override
  void visitSuperPropertySet(ast.SuperPropertySet node) {
    _useThis();
    node.visitChildren(this);
  }

  @override
  void visitTypeParameterType(ast.TypeParameterType node) {
    var parent = node.parameter.declaration;
    if (parent is ast.Class) {
      _useThis();
    }
    node.visitChildren(this);
  }

  @override
  void visitBlock(ast.Block node) {
    _visitWithScope(node);
  }

  @override
  void visitBlockExpression(ast.BlockExpression node) {
    // Not using _visitWithScope as Block inside BlockExpression does not have
    // a scope.
    _enterScope(node);
    ast.visitList(node.body.statements, this);
    node.value.accept(this);
    _leaveScope();
  }

  @override
  void visitAssertStatement(ast.AssertStatement node) {
    if (!scopes.enableAsserts) {
      return;
    }
    super.visitAssertStatement(node);
  }

  @override
  void visitAssertBlock(ast.AssertBlock node) {
    if (!scopes.enableAsserts) {
      return;
    }
    _visitWithScope(node);
  }

  @override
  void visitCatch(ast.Catch node) {
    _visitWithScope(node);
  }

  @override
  void visitLet(ast.Let node) {
    _visitWithScope(node);
  }

  @override
  void visitForStatement(ast.ForStatement node) {
    ++_loopDepth;
    _visitWithScope(node);
    --_loopDepth;
  }

  @override
  void visitWhileStatement(ast.WhileStatement node) {
    ++_loopDepth;
    node.visitChildren(this);
    --_loopDepth;
  }

  @override
  void visitDoStatement(ast.DoStatement node) {
    ++_loopDepth;
    node.visitChildren(this);
    --_loopDepth;
  }
}
