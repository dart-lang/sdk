// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartContext;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.backend.js.ast.JsFunction;
import com.google.dart.compiler.backend.js.ast.JsName;
import com.google.dart.compiler.backend.js.ast.JsScope;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.ConstructorElement;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MethodElement;

import java.util.Deque;
import java.util.LinkedList;

/**
 * This visitor generates Javascript scopes and names for all the Dart nodes, filling in the
 * node->name map in 'names'.
 */
class GenerateNamesAndScopes extends NormalizedVisitor {

  /**
   * A JsScope used to manage fields and methods. A MemberJsScope can become
   * parentless.
   */
  private static class MemberJsScope extends JsScope {
    private MemberJsScope(JsScope parent, String description) {
      super(parent, description);
    }

    @Override
    protected void detachFromParent() {
      super.detachFromParent();
    }
  }

  private final Deque<JsScope> scopes = new LinkedList<JsScope>();
  private DartClass currentClass = null;
  private int labelUniqifier = 0; // to resolve label name collisions.
  private int varUniqifier = 0; // to resolve variable name collisions.

  private final TranslationContext translationContext;
  private final LibraryElement unitLibrary;

  private JsScope getGlobalScope() {
    return translationContext.getProgram().getScope();
  }

  public GenerateNamesAndScopes(TranslationContext data, LibraryElement unitLibrary) {
    this.translationContext = data;
    this.unitLibrary = unitLibrary;
    scopes.push(getGlobalScope());
  }

  @Override
  public boolean visit(DartClass x, DartContext ctx) {
    assert currentClass == null;
    // Global variables are declared lazily. We don't declare the class now.
    currentClass = x;
    // We add the member scope into the hierarchy, so that the resolution works on unqualified
    // identifiers. Once the resolution is done, we can rip out the scope from the hierarchy.
    scopes.push(new MemberJsScope(scopes.peek(), x.getClassName()));
    return true;
  }

  @Override
  public boolean visit(DartField x, DartContext ctx) {
    FieldElement element = x.getSymbol();
    String mangledFieldName = translationContext.getMangler().mangleField(element, unitLibrary);
    JsName fieldName = declare(x.getSymbol(), mangledFieldName, element.getName());
    fieldName.setObfuscatable(false);
    return true;
  }

  public boolean generateConstructorName(DartMethodDefinition x) {
    ConstructorElement element = (ConstructorElement) x.getSymbol();
    String name = translationContext.getMangler().mangleConstructor(element.getName(), unitLibrary);
    JsName jsName = function(x.getSymbol(), name, element.getName(), x.getFunction());
    // Constructors are globally accessible.
    jsName.setObfuscatable(false);
    return true;
  }

  @Override
  public boolean visit(DartMethodDefinition x, DartContext ctx) {
    MethodElement element = x.getSymbol();
    if (Elements.isNonFactoryConstructor(element)) {
      return generateConstructorName(x);
    }
    if (x.getModifiers().isFactory()) {
      String className = ((ConstructorElement) element).getConstructorType().getName();
      String name = translationContext.getMangler().createFactorySyntax(className, element.getName(), unitLibrary);
      JsName jsName = function(x.getSymbol(), name, element.getName(), x.getFunction());
      // Factories are globally accessible.
      jsName.setObfuscatable(false);
      return true;
    }

    String mangledName = translationContext.getMangler().mangleMethod(element, unitLibrary);
    JsName methodName = function(x.getSymbol(), mangledName, element.getName(), x.getFunction());
    methodName.setObfuscatable(false);
    return true;
  }

  @Override
  public boolean visit(DartFunctionExpression x, DartContext ctx) {
    function(x.getSymbol(), x.getFunctionName(), x.getFunctionName(), x.getFunction());
    return true;
  }

  @Override
  public boolean visit(DartParameter x, DartContext ctx) {
    // TODO(ngeoffray): A parameter in a function type does not have a symbol.
    if (x.getSymbol() != null) {
      declareExclusively(x.getSymbol(), x.getParameterName());
    }
    return true;
  }

  @Override
  public boolean visit(DartVariable x, DartContext ctx) {
    declareExclusively(x.getSymbol(), x.getVariableName());
    return true;
  }

  @Override
  public boolean visit(DartLabel x, DartContext ctx) {
    declareExclusively(x.getSymbol(), String.format("L%X", labelUniqifier++));
    return true;
  }

  @Override
  public void endVisit(DartMethodDefinition x, DartContext ctx) {
    scopes.pop();
  }

  @Override
  public void endVisit(DartFunctionExpression x, DartContext ctx) {
    scopes.pop();
  }

  @Override
  public void endVisit(DartClass x, DartContext ctx) {
    currentClass = null;
    // Rip out the member scope. Members are always accessed through an object and don't clash
    // with other variables.
    GenerateNamesAndScopes.MemberJsScope memberScope = (GenerateNamesAndScopes.MemberJsScope) scopes.pop();
    memberScope.rebaseChildScopes(memberScope.getParent());
    memberScope.detachFromParent();
    translationContext.getMemberScopes().put(x.getSymbol(), memberScope);
  }

  private JsName function(Symbol symbol, String name, String originalName, DartFunction func) {
    JsName jsName = name != null ? declareExclusively(symbol, name, originalName) : null;
    JsFunction jsFunc = new JsFunction(scopes.peek(), jsName);
    jsFunc.setFromDart(true);
    scopes.push(jsFunc.getScope());
    translationContext.getMethods().put(func, jsFunc);
    return jsName;
  }

  private JsName declare(Symbol x, String name, String originalName) {
    return declareInScope(scopes.peek(), x, name, originalName);
  }

  private JsName declareExclusively(Symbol x, String name, String originalName) {
    return declareExclusivelyInScope(scopes.peek(), x, name, originalName);
  }

  private JsName declareExclusively(Symbol x, String name) {
    return declareExclusivelyInScope(scopes.peek(), x, name, name);
  }

  private static final int BIG_PRIME_UNDER_0XFFFFF = 985531;

  /**
   * Create a unique name for this variable in this scope.
   *
   * Try to keep this from being a linear scan of the namespace, and keep
   * it under 5 hex digits (over 1,000,000 unique suffixes).
   *
   */
  private JsName declareExclusivelyInScope(JsScope scope, Symbol x,
                                           String name, String originalName) {
    String mappedName = name;
    int offset = 0;
    while (scope.findExistingName(mappedName) != null) {
      mappedName = String.format("%s_%X", mappedName, varUniqifier);
      varUniqifier = (varUniqifier + offset++) % BIG_PRIME_UNDER_0XFFFFF;
    }
    return declareInScope(scope, x, mappedName, originalName);
  }

  private JsName declareInScope(JsScope scope, Symbol x, String name, String originalName) {
    JsName jsName = scope.declareName(name, name, originalName);
    jsName.getClass(); // Fast null check.
    x.getClass(); // Fast null check.
    translationContext.getNames().setName(x, jsName);
    return jsName;
  }
}