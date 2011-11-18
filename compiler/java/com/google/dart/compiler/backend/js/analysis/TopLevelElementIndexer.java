// Copyright (c) 2011, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js.analysis;

import org.mozilla.javascript.Token;
import org.mozilla.javascript.ast.Assignment;
import org.mozilla.javascript.ast.AstNode;
import org.mozilla.javascript.ast.ExpressionStatement;
import org.mozilla.javascript.ast.FunctionCall;
import org.mozilla.javascript.ast.FunctionNode;
import org.mozilla.javascript.ast.Name;
import org.mozilla.javascript.ast.NodeVisitor;
import org.mozilla.javascript.ast.VariableDeclaration;
import org.mozilla.javascript.ast.VariableInitializer;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Deque;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

/**
 * Indexes the top level declarations and expressions contained in a JavaScript AST tree. Where top 
 * level expressions can be global variables, method definitions or invocations.  Note that method
 * bodies are not processed.
 */
class TopLevelElementIndexer implements NodeVisitor {
  /**
   * 
   */
  private static final String RUN_ENTRY_METHOD_NAME = "RunEntry";

  /**
   * Collects {@link Name} {@link AstNode}s.
   */
  static class NameLocator implements NodeVisitor {
    private static final int PROTOTYPE_DEFAULT_INDEX = -1;
    private final Deque<String> identifiers = new LinkedList<String>();
    private int prototypeIndex = PROTOTYPE_DEFAULT_INDEX;

    public String getEnclosingTypeName() {
      return identifiers.getFirst();
    }

    public String getName() {
      return identifiers.getLast();
    }

    public Collection<String> getPossibleNames() {
      List<String> names = new ArrayList<String>(2);
      if (hasPrototypeInName()) {
        names.add(identifiers.getLast());
      }
      names.add(getQualifiedName());
      return names;
    }

    public String getQualifiedName() {
      StringBuffer sb = new StringBuffer();
      Iterator<String> iterator = identifiers.iterator();
      while (iterator.hasNext()) {
        sb.append(iterator.next());
        if (iterator.hasNext()) {
          sb.append(".");
        }
      }
      return sb.toString();
    }

    public boolean hasPrototypeInName() {
      return prototypeIndex != PROTOTYPE_DEFAULT_INDEX;
    }

    @Override
    public boolean visit(AstNode node) {
      if (node.getType() == Token.NAME) {
        Name name = (Name) node;
        String identifier = name.getIdentifier();
        if ("prototype".equals(identifier)) {
          prototypeIndex = identifiers.size();
        }
        identifiers.add(identifier);
      }
      return true;
    }
  }

  public static void printGlobals(List<AstNode> globals) {
    System.out.println("Globals");
    for (AstNode global : globals) {
      System.out.println("--------");
      System.out.println(global.toSource());
      System.out.println();
    }
  }

  public static void printNamesToElements(Map<String, List<JavascriptElement>> namesToElements) {
    long rttCost = 0;
    long namedCost = 0;
    long ctorCost = 0;
    
    Set<Entry<String, List<JavascriptElement>>> entrySet = namesToElements.entrySet();
    for (Entry<String, List<JavascriptElement>> entry : entrySet) {
      System.out.println("--------");
      System.out.println("Name: " + entry.getKey());
      for (JavascriptElement javascriptElement : entry.getValue()) {
        AstNode node = javascriptElement.getNode();
        if (node == null) {
          continue;
        }

        System.out.println("Type: " + Token.typeToName(node.getType()));
        if (javascriptElement.getInherits() != null) {
          System.out.println("Inherits: " + javascriptElement.getInherits());
        }

        try {
          System.out.println(node.toSource());
        } catch (Exception e) {
          System.out.println("Failed to print node source code");
        }

        String name = javascriptElement.getName();
        if (name.endsWith("$named")) {
          namedCost += node.getLength();
        } else if (name.endsWith("$addTo") || name.endsWith("$lookupRTT")
            || name.endsWith("$RTTimplements")) {
          rttCost += node.getLength();
        } else if (name.endsWith("$Constructor") || name.endsWith("$Initializer")) {
          ctorCost += node.getLength();
        }
      }
      System.out.println();
    }

    System.out.println(ctorCost + 
        " characters worth of $Constructor and $Initializer methode declarations");
    System.out.println(namedCost + " characters worth of $named methods declarations");
    System.out.println(rttCost + " characters worth of RTT method declarations");
  }

  private final List<AstNode> entryPoints = new ArrayList<AstNode>();
  private final List<AstNode> globals;

  private final Map<String, List<JavascriptElement>> namesToElements;

  public TopLevelElementIndexer(Map<String, List<JavascriptElement>> namesToElements,
      List<AstNode> globals) {
    this.globals = globals;
    this.namesToElements = namesToElements;
  }

  private void addElement(String identifier, JavascriptElement javascriptElement) {
    List<JavascriptElement> list = namesToElements.get(identifier);
    if (list == null) {
      list = new ArrayList<JavascriptElement>(1);
      namesToElements.put(identifier, list);
    }
    list.add(javascriptElement);
  }

  /**
   * Processes an AST node that does not define a method.  If the node is an invocation to a 
   * RunEntry method or an inherits method update the entry points and element inheritance
   * hierarchy accordingly.  Otherwise we just add this node to the globals block and continue.
   */
  private void processGlobal(AstNode node) {
    if (node.getType() == Token.EXPR_RESULT) {
      ExpressionStatement expressionStatement = (ExpressionStatement) node;
      AstNode expression = expressionStatement.getExpression();
      if (expression.getType() == Token.CALL) {
        FunctionCall functionCall = (FunctionCall) expression;
        AstNode target = functionCall.getTarget();
        if (target.getType() == Token.NAME) {
          Name targetName = (Name) target;
          if (RUN_ENTRY_METHOD_NAME.equals(targetName.getIdentifier())) {
            // This is a call to an entry point so add it to the known set of entry points.
            entryPoints.add(node);
            return;
          } else if ("$inherits".equals(targetName.getIdentifier())) {
            // This is an inheirts call so update the element's inheritance hierarchy.
            List<AstNode> arguments = functionCall.getArguments();
            assert (arguments.size() == 2);
            assert (arguments.get(0).getType() == Token.NAME);
            assert (arguments.get(1).getType() == Token.NAME);
            Name subtype = (Name) arguments.get(0);
            Name supertype = (Name) arguments.get(1);
            List<JavascriptElement> subTypeFunctions = namesToElements.get(subtype.getIdentifier());
            assert (subTypeFunctions != null && subTypeFunctions.size() == 1);
            JavascriptElement subtypeFunction = subTypeFunctions.get(0);
            subtypeFunction.setInheritsNode(node);
            subtypeFunction.setInherits(namesToElements.get(supertype.getIdentifier()).get(0));
            return;
          }
        }
      }
    }

    globals.add(node);
  }

  public List<AstNode> getEntryPoints() {
    return entryPoints;
  }

  @Override
  public boolean visit(AstNode node) {
    if (node == node.getAstRoot()) {
      return true;
    }

    switch (node.getType()) {
      case Token.EXPR_VOID:
      case Token.EXPR_RESULT:
        ExpressionStatement expressionStatement = (ExpressionStatement) node;
        AstNode expression = expressionStatement.getExpression();
        if (expression.getType() == Token.ASSIGN) {
          Assignment assignment = (Assignment) expression;
          NameLocator nameLocator = new NameLocator();
          assignment.getLeft().visit(nameLocator);
          String enclosingTypeName = nameLocator.getEnclosingTypeName();
          JavascriptElement enclosingElement = null;
          if (enclosingTypeName != null) {
            List<JavascriptElement> list = namesToElements.get(enclosingTypeName);
            if (list == null) {
              // TODO: Assume that this is a native object for now, we could have a whitelist of
              // native objects if we wanted to.
              enclosingElement =
                  new JavascriptElement(null, false, enclosingTypeName, nameLocator.getName(), 
                      null);
              addElement(enclosingTypeName, enclosingElement);
            } else {
              assert (list != null && list.size() == 1);
              enclosingElement = list.get(0);
            }
          }

          JavascriptElement javascriptElement =
              new JavascriptElement(enclosingElement, nameLocator.hasPrototypeInName(),
                  nameLocator.getQualifiedName(), nameLocator.getName(), node);
          for (String identifier : nameLocator.getPossibleNames()) {
            addElement(identifier, javascriptElement);
          }
        } else {
          processGlobal(node);
        }
        break;

      case Token.FUNCTION:
        FunctionNode functionNode = (FunctionNode) node;
        String name = functionNode.getName();
        if (name != null && !name.isEmpty()) {
          addElement(name, new JavascriptElement(null, false, name, name, node));
        }
        break;

      case Token.VAR:
        VariableDeclaration variableDeclaration = (VariableDeclaration) node;
        List<VariableInitializer> variables = variableDeclaration.getVariables();
        for (VariableInitializer variable : variables) {
          AstNode target = variable.getTarget();
          if (target.getType() == Token.NAME) {
            Name variableName = (Name) target;
            addElement(variableName.getIdentifier(), new JavascriptElement(null, false,
                variableName.getIdentifier(), variableName.getIdentifier(), node));
          }
        }
        break;

      default:
        processGlobal(node);
        break;
    }

    return false;
  }
}
