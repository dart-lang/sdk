// Copyright (c) 2011, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js.analysis;

import org.mozilla.javascript.Token;
import org.mozilla.javascript.ast.AstNode;
import org.mozilla.javascript.ast.FunctionNode;
import org.mozilla.javascript.ast.Name;
import org.mozilla.javascript.ast.NewExpression;
import org.mozilla.javascript.ast.NodeVisitor;
import org.mozilla.javascript.ast.PropertyGet;
import org.mozilla.javascript.ast.Scope;
import org.mozilla.javascript.ast.Symbol;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Computes the set of dependencies that a given AstNode node has.
 */
class DependencyComputer {
  /**
   * Visitor for determining what dependencies an AstNode has.
   */
  class DependencyComputingVisitor implements NodeVisitor {
    /**
     * Adds a dependency on the given identifier.  If the identifier is virtual then then a 
     * dependency is only added if the enclosing "class" has been instantiated.
     */
    private void addDependency(String identifier, boolean isVirtual) {
      List<JavascriptElement> members = namesToElements.get(identifier);
      if (members != null) {
        for (JavascriptElement member : members) {
          if (isVirtual && member.isVirtual()) {
            JavascriptElement enclosingElement = member.getEnclosingElement();
            if (enclosingElement != null && enclosingElement.isInstantiated()) {
              dependencies.add(member);
            }
          } else {
            if (!member.isVirtual()) {
              if (member.getEnclosingElement() != null) {
                dependencies.add(member.getEnclosingElement());
              }
            }
            dependencies.add(member);
          }
        }
      }
    }

    /**
     * Record that we saw a new of a given identifier.
     */
    private void addInstantiation(String identifier) {
      List<JavascriptElement> instantiatedClasses = namesToElements.get(identifier);
      if (instantiatedClasses != null) {
        for (JavascriptElement instantiatedClass : instantiatedClasses) {
          instantiatedClass.setInstantiated(true);

          /*
           * Whenever we see an instantiation we must check it and any super type for members that
           * match the virtual names seen to date. 
           */
          while (instantiatedClass != null) {
            for (JavascriptElement member : instantiatedClass.getMembers()) {
              if (virtualNames.contains(member.getName())) {
                dependencies.add(member);
              }
            }
            
            instantiatedClass = instantiatedClass.getInherits();
          }
        }
      }
    }

    private void addStaticDependency(String identifier) {
      addDependency(identifier, false);
    }

    private void addVirtualDependency(String identifier) {
      virtualNames.add(identifier);
      addDependency(identifier, true);
    }

    Symbol findSymbol(Scope scope, String name) {
      if (scope == null) {
        return null;
      }

      Symbol symbol = scope.getSymbol(name);
      if (symbol == null) {
        Scope parentScope = scope.getParentScope();
        if (parentScope == null) {
          return findSymbol(scope.getAstRoot(), name);
        } else {
          return findSymbol(parentScope, name);
        }
      }

      return symbol;
    }

    /**
     * Returns true if the name is a local or parameter name.  However, if the name is on the 
     * right hand side of a property get then we don't consider this name to be a local variable.
     */
    boolean isLocalVariableOrParameter(Name name) {
      Scope definingScope = name.getDefiningScope();
      Scope enclosingScope = name.getEnclosingScope();
      if (definingScope != null) {
        Symbol symbol = definingScope.getSymbol(name.getIdentifier());
        if (definingScope.getType() == Token.FUNCTION) {
          if (symbol != null && (symbol.getDeclType() == Token.VAR)
              || (symbol.getDeclType() == Token.LP)) {
            
            if (name.getParent().getType() == Token.GETPROP) {
              PropertyGet propertyGet = (PropertyGet) name.getParent();
              return propertyGet.getRight() != name;
            }
            
            return true;
          } 
        }
      }

      return false;
    }

    /**
     * Returns <code>true</code> if the name is associated with a native
     * function or a top level function.
     */
    private boolean isNativeOrTopLevelFunction(Scope enclosingScope, String name) {
      List<JavascriptElement> list = namesToElements.get(name);
      if (list == null || list.isEmpty()) {
        return false;
      }

      Symbol symbol = findSymbol(enclosingScope, name);
      if (symbol != null
          && (symbol.getDeclType() == Token.FUNCTION || symbol.getDeclType() == Token.VAR)) {
        return true;
      }

      JavascriptElement javascriptElement = list.get(0);
      return javascriptElement.isNative();
    }

    /**
     * Return a static name if the {@link PropertyGet} matches the pattern x.y or
     * x.prototype.y or <code>null</code> if it does not.
     */
    String maybeGetStaticName(PropertyGet propertyGet) {
      AstNode right = propertyGet.getRight();
      int rightType = right.getType();
      if (rightType != Token.NAME) {
        return null;
      }

      AstNode left = propertyGet.getLeft();
      int leftType = left.getType();
      if (leftType == Token.NAME) {
        String qualifier = ((Name) left).getIdentifier();

        if (isNativeOrTopLevelFunction(left.getEnclosingScope(), qualifier)) {
          String targetName = ((Name) right).getIdentifier();
          String qualifiedName = qualifier + "." + targetName;
          if ("prototype".equals(targetName)) {
            return qualifiedName;
          } else if (namesToElements.containsKey(qualifiedName)) {
            return qualifiedName;
          }
        }
      } else if (leftType == Token.GETPROP) {
        PropertyGet leftPropGet = (PropertyGet) left;
        String handleSpecialCase = maybeGetStaticName(leftPropGet);
        if (handleSpecialCase != null && handleSpecialCase.endsWith("prototype")) {
          handleSpecialCase = handleSpecialCase + "." + ((Name) right).getIdentifier();
          if (namesToElements.containsKey(handleSpecialCase)) {
            return handleSpecialCase;
          }
        }
      }

      return null;
    }

    @Override
    public boolean visit(AstNode node) {
      switch (node.getType()) {
        case Token.GETPROP:
          PropertyGet propertyGet = (PropertyGet) node;
          String staticName = maybeGetStaticName(propertyGet);
          if (staticName != null) {
            addStaticDependency(staticName);
            return false;
          }
          break;

        case Token.FUNCTION:
          FunctionNode functionNode = (FunctionNode) node;
          functionNode.getBody().visit(this);
          // Don't process the parameters
          return false;

        case Token.NAME:
          Name name = (Name) node;
          if (!isLocalVariableOrParameter(name)) {
            String identifier = name.getIdentifier();
            addVirtualDependency(identifier);
          }
          break;

        case Token.NEW:
          NewExpression newExpression = (NewExpression) node;
          Name target = (Name) newExpression.getTarget();
          if (target != null) {
            addInstantiation(target.getIdentifier());
          }
          break;

        default:
          break;
      }

      return true;
    }

  }

  private final List<JavascriptElement> dependencies = new ArrayList<JavascriptElement>();
  private final Map<String, List<JavascriptElement>> namesToElements;
  
  /**
   * Names that have been referenced using virtual syntax, i.e. not using A.prototype.foo, but 
   * as foo or this.foo, etc.
   */
  private final Set<String> virtualNames = new HashSet<String>();

  public DependencyComputer(Map<String, List<JavascriptElement>> namesToElements) {
    this.namesToElements = namesToElements;
  }

  public List<JavascriptElement> computeDependencies(AstNode node) {
    // Clear the dependencies so this object can be reused.
    dependencies.clear();
    node.visit(new DependencyComputingVisitor());
    return dependencies;
  }
}
