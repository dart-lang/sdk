// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartCatchBlock;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartClassMember;
import com.google.dart.compiler.ast.DartContext;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartForInStatement;
import com.google.dart.compiler.ast.DartForStatement;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionObjectInvocation;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartInitializer;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartThisExpression;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.backend.js.ast.JsName;
import com.google.dart.compiler.backend.js.ast.JsScope;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.Element;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Deque;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Information relating to a methods scope, symbols, and closures
 */
class ScopeRootInfo {
  /**
   * Defines a relationship between a DartSymbol and a scope.
   */
  static class DartScope {
    /**
     * A simple class for storing information about a symbol, specifically
     * whether the symbol is referenced by a closure.
     */
    static class DartSymbolInfo {
      private final DartScope owningScope;
      private boolean referencedFromClosure = false;

      public DartSymbolInfo(DartScope owningScope) {
        this.owningScope = owningScope;
      }

      public DartScope getOwningScope() {
        return owningScope;
      }

      public boolean isReferencedFromClosure() {
        return referencedFromClosure;
      }

      public void setReferencedFromClosure(boolean referencedFromClosure) {
        this.referencedFromClosure = referencedFromClosure;
      }
    }

    private final DartScope parent;
    private Map<Symbol, DartScope.DartSymbolInfo> symbols = Maps.newLinkedHashMap();
    private Map<JsScope, JsName> jsAliasNames = Maps.newHashMap();
    // The scope's depth from the initial method definition scope.
    private final int depth;

    public DartScope(DartScope parent) {
      this.parent = parent;
      this.depth = (parent != null) ? parent.getDepth() + 1 : 0;
    }

    public void declare(Symbol symbol) {
      symbols.put(symbol, new DartSymbolInfo(this));
    }

    public int getDepth() {
      return depth;
    }

    public DartScope getParent() {
      return parent;
    }

    public DartScope findSymbolScope(Symbol symbol) {
      DartScope current = this;
      while (current != null) {
        DartScope.DartSymbolInfo info = current.getSymbolInfo(symbol);
        if (info != null) {
          return current;
        }
        current = current.getParent();
      }
      return null;
    }

    public DartScope.DartSymbolInfo getSymbolInfo(Symbol symbol) {
      return this.symbols.get(symbol);
    }
    
    public Map<Symbol, DartScope.DartSymbolInfo> getSymbols() {
      return symbols;
    }

    public boolean definesClosureReferencedSymbols() {
      for (DartScope.DartSymbolInfo symbol : symbols.values()) {
        if (symbol.isReferencedFromClosure()) {
          return true;
        }
      }
      return false;
    }

    private String getScopeAliasName() {
      return "dartc_scp$" + depth;
    }

    /**
     * Returns the alias-object-JsName of this DartScope in the given JsScope. If none exists yet,
     * creates a new one.
     *
     * @param jsScope
     * @return the JsName representing the alias object for this DartScope.
     */
    public JsName getAliasForJsScope(JsScope jsScope) {
      JsName result = findAliasForJsScope(jsScope);
      if (result == null) {
        result = jsScope.declareFreshName(getScopeAliasName());
        jsAliasNames.put(jsScope, result);
      }
      return result;
    }

    /**
     * Returns the alias-object-JsName of this DartScope in the given JsScope. If none exists yet,
     * null is returned.
     *
     * @param jsScope
     * @return the JsName representing the alias object for this DartScope.
     */
    public JsName findAliasForJsScope(JsScope jsScope) {
      return jsAliasNames.get(jsScope);
    }
  }
  
  /**
   * A simple class to keep track of the scope referenced by a closure,
   * also whether the closure references "this".
   */
  public static class ClosureInfo {
    final Set<DartScope> referencedScopes = Sets.newHashSet();

    boolean referencesThis = false;

    public List<DartScope> getSortedReferencedScopeList() {
      ArrayList<DartScope> sortedScopes = Lists.newArrayList(
          referencedScopes);
      Collections.sort(sortedScopes, new Comparator<DartScope>(){
        @Override
        public int compare(DartScope s1, DartScope s2) {
          return s1.getDepth() - s2.getDepth();
        }});
      return sortedScopes;
    }
  }

  /**
   * A generic helper class for visiting DartScope definitions.
   */
  static private abstract class DartScopesVisitor extends NormalizedVisitor {

    // A place to store the constructor initializer list to the initializers
    // can be visited within the scope of the constructor's parameters.
    private List<DartInitializer> pendingConstructorInitList = null;

    @Override
    public boolean visit(DartUnit x, DartContext ctx) {
      return enterScope(x, ctx);
    }

    @Override
    public boolean visit(DartClass x, DartContext ctx) {
      return enterScope(x, ctx);
    }

    @Override
    public boolean visit(DartMethodDefinition x, DartContext ctx) {
      this.pendingConstructorInitList = x.getInitializers();
      accept(x.getFunction());
      return false;
    }

    @Override
    public void endVisit(DartMethodDefinition x, DartContext ctx) {
      assert this.pendingConstructorInitList == null;
    }

    @Override
    public boolean visit(DartFunctionExpression x, DartContext ctx) {
      // For function statements, the function's name belong in the outer scope.
      // For function expressions, it is part of the function's own scope.
      if (!x.isStatement()) {
        return enterScope(x, ctx);
      }
      return true;
    }

    @Override
    public boolean visit(DartFunction x, DartContext ctx) {
      boolean enter = enterScope(x, ctx);
      if (enter) {
        // Save and clear the cached init lists before processing
        // any function as default parameters or in init list.
        List<DartInitializer> inits = pendingConstructorInitList;
        pendingConstructorInitList = null;
        acceptList(x.getParams());
        if (inits != null) {
          acceptList(inits);
        }
        if (x.getBody() != null) {
          accept(x.getBody());
        }
      }
      return false;
    }

    @Override
    public boolean visit(DartBlock x, DartContext ctx) {
      return enterScope(x, ctx);
    }

    @Override
    public boolean visit(DartCatchBlock x, DartContext ctx) {
      return enterScope(x, ctx);
    }

    @Override
    public boolean visit(DartForInStatement x, DartContext ctx) {
      return enterScope(x, ctx);
    }

    @Override
    public boolean visit(DartForStatement x, DartContext ctx) {
      return enterScope(x, ctx);
    }

    @Override
    public void endVisit(DartUnit x, DartContext ctx) {
      exitScope(x, ctx);
    }

    @Override
    public void endVisit(DartClass x, DartContext ctx) {
      exitScope(x, ctx);
    }

    @Override
    public void endVisit(DartFunctionExpression x, DartContext ctx) {
      if (!x.isStatement()) {
        exitScope(x, ctx);
      }
    }

    @Override
    public void endVisit(DartFunction x, DartContext ctx) {
      exitScope(x, ctx);
    }

    @Override
    public void endVisit(DartBlock x, DartContext ctx) {
      exitScope(x, ctx);
    }

    @Override
    public void endVisit(DartCatchBlock x, DartContext ctx) {
      exitScope(x, ctx);
    }

    @Override
    public void endVisit(DartForStatement x, DartContext ctx) {
      exitScope(x, ctx);
    }

    abstract boolean enterScope(DartNode x, DartContext ctx);
    abstract void exitScope(DartNode x, DartContext ctx);
  }

  /**
   * Build a set of ClosureInfo objects for the method,
   * find and mark any variable referenced by a closure.
   */
  private static class ClosureRefenceMapBuilder extends ScopeRootInfo.DartScopesVisitor {
    private final Map<DartNode, DartScope> scopes;
    private Deque<DartScope> scopeStack = Lists.newLinkedList();
    private final Map<DartFunction, ScopeRootInfo.ClosureInfo> closures = Maps.newHashMap();
    private Deque<DartFunction> closureStack = Lists.newLinkedList();
    private final boolean respectInlinableModifier;
    
    ClosureRefenceMapBuilder(Map<DartNode, DartScope> scopes, boolean respectInlinableModifier) {
      this.scopes = scopes;
      this.respectInlinableModifier = respectInlinableModifier;
    }

    @Override
    boolean enterScope(DartNode x, DartContext ctx) {
      scopeStack.push(scopes.get(x));
      return true;
    }

    @Override
    void exitScope(DartNode x, DartContext ctx) {
      scopeStack.pop();
    }

    @Override
    public boolean visit(DartFunctionObjectInvocation x, DartContext ctx) {
      DartExpression target = x.getTarget();
      if (target instanceof DartFunctionExpression) {
        DartFunctionExpression functionExpression = (DartFunctionExpression) target;
        if (respectInlinableModifier && 
            functionExpression.getSymbol().getModifiers().isInlinable()) {
          acceptList(x.getArgs());
          return traverseFunction(functionExpression.getFunction(), ctx);
        }
      }
      return super.visit(x, ctx);
    }

    // Inlined from DartFunction#traverse(DartVisitor, DartContext).
    private boolean traverseFunction(DartFunction function, DartContext ctx) {
      for (DartParameter parameter : function.getParams()) {
        doTraverse(parameter, ctx);
      }
      if (function.getBody() != null) {
        doTraverse(function.getBody(), ctx);
      }
      // Ignore the return type.
      return false;
    }

    @Override
    public boolean visit(DartFunction x, DartContext ctx) {
      this.closures.put(x, new ClosureInfo());
      this.closureStack.push(x);
      return super.visit(x, ctx);
    }

    @Override
    public void endVisit(DartFunction x, DartContext ctx) {
      closureStack.pop();
      super.endVisit(x, ctx);
    }

    @Override
    public void endVisit(DartIdentifier x, DartContext ctx) {
      processSymbol(x.getTargetSymbol());
      super.endVisit(x, ctx);
    }

    @Override
    public void endVisit(DartThisExpression x, DartContext ctx) {
      for (DartFunction closure : closureStack) {
        ScopeRootInfo.ClosureInfo info = closures.get(closure);
        info.referencesThis = true;
      }
    }

    private void processSymbol(Symbol targetSymbol) {
      if (targetSymbol != null) {
        DartNode node = targetSymbol.getNode();
        if (node instanceof DartClassMember<?>) {
          // Special case: implicit instance/static member references.
          DartClassMember<?> member = (DartClassMember<?>) node;
          if (!member.getModifiers().isStatic()) {
            // A member reference implies a reference to the current "this"
            // object, the closure will need to pass it through.
            for (DartFunction closure : closureStack) {
              ScopeRootInfo.ClosureInfo info = closures.get(closure);
              info.referencesThis = true;
            }
          }
        }

        if (closureStack.size() > 0) {
          DartScope currentScope = this.scopeStack.peek();
          DartScope symbolScope = currentScope.findSymbolScope(targetSymbol);
          if (symbolScope != null) {
            boolean referencedFromClosure = false;
            for (DartFunction closure : closureStack) {
              DartScope closureScope = scopes.get(closure);
              // For each of the closures, determine if the value is defined
              // outside outside the current closure, if so record its use.
              if (symbolScope.getDepth() < closureScope.getDepth()) {
                ScopeRootInfo.ClosureInfo info = closures.get(closure);
                info.referencedScopes.add(symbolScope);
                referencedFromClosure = true;
              }
            }
            if (referencedFromClosure) {
              symbolScope.getSymbolInfo(targetSymbol)
                  .setReferencedFromClosure(true);
            }
          }
        }
      }
    }
  }

  /**
   * Build the DartScope objects for a method.
   */
  static private class MethodScopeMapBuilder extends ScopeRootInfo.DartScopesVisitor {
    private Map<DartNode, DartScope> scopes = Maps.newLinkedHashMap();
    private Deque<DartScope> scopeStack = Lists.newLinkedList();

    @Override
    boolean enterScope(DartNode x, DartContext ctx) {
      scopeStack.push(new DartScope(scopeStack.peek()));
      scopes.put(x, scopeStack.peek());
      return true;
    }

    @Override
    void exitScope(DartNode x, DartContext ctx) {
      scopeStack.pop();
    }

    // TODO(johnlenz): Handle catch exception declarations.

    @Override
    public void endVisit(DartParameter x, DartContext ctx) {
      DartScope currentScope = scopeStack.peek();
      currentScope.declare(x.getSymbol());
      super.endVisit(x, ctx);
    }

    @Override
    public void endVisit(DartVariable x, DartContext ctx) {
      DartScope currentScope = scopeStack.peek();
      currentScope.declare(x.getSymbol());
      super.endVisit(x, ctx);
    }

    @Override
    public boolean visit(DartFunctionExpression x, DartContext ctx) {
      DartScope currentScope = scopeStack.peek();
      boolean visit = super.visit(x, ctx);
      if (!x.isStatement()) {
        // Declare the symbol in the new scope
        currentScope = scopeStack.peek();
      }
      currentScope.declare(x.getSymbol());
      return visit;
    }
  }

  private final DartClassMember<?> classMember;
  private final Map<Symbol, DartScope.DartSymbolInfo> symbols = Maps.newHashMap();
  private final Map<DartFunction, ScopeRootInfo.ClosureInfo> closures;
  private final Map<DartNode, DartScope> scopes;
  private int closureIds = 0;

  static ScopeRootInfo makeScopeInfo(DartMethodDefinition x, boolean respectInlinableModifier) {
    return makeScopeInfoImpl(x, respectInlinableModifier);
  }

  static ScopeRootInfo makeScopeInfo(DartField x, boolean respectInlinableModifier) {
    return makeScopeInfoImpl(x, respectInlinableModifier);
  }

  private static ScopeRootInfo makeScopeInfoImpl(DartClassMember<?> x, 
      boolean respectInlinableModifier) {
    ScopeRootInfo.MethodScopeMapBuilder scopeBuilder = new MethodScopeMapBuilder();
    scopeBuilder.accept(x);
    ScopeRootInfo.ClosureRefenceMapBuilder closureBuilder = new ClosureRefenceMapBuilder(
        scopeBuilder.scopes, respectInlinableModifier);
    closureBuilder.accept(x);
    return new ScopeRootInfo(x, scopeBuilder.scopes, closureBuilder.closures);
  }

  ScopeRootInfo(
      DartClassMember<?> x, Map<DartNode, DartScope> scopes,
      Map<DartFunction, ScopeRootInfo.ClosureInfo> closures) {
    this.classMember = x;
    this.closures = closures;
    this.scopes = scopes;
    for (DartScope scope : scopes.values()) {
      this.symbols.putAll(scope.getSymbols());
    }
  }

  Element getContainingElement() {
    return classMember.getSymbol();
  }

  DartClassMember<?> getContainingClassMember() {
    return classMember;
  }

  DartScope.DartSymbolInfo getSymbolInfo(Symbol targetSymbol) {
    return symbols.get(targetSymbol);
  }

  public ScopeRootInfo.ClosureInfo getClosureInfo(DartFunction x) {
    return closures.get(x);
  }

  public DartScope getScope(DartNode x) {
    return scopes.get(x);
  }

  /**
   * @return A name for a closure unique within this method.
   */
  public String getNextClosureName() {
    return "c" + closureIds++;
  }
}
