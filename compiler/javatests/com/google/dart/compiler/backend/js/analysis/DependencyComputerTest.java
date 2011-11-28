// Copyright 2011 Google Inc. All Rights Reserved.

package com.google.dart.compiler.backend.js.analysis;

import com.google.common.collect.Maps;

import junit.framework.TestCase;

import org.mozilla.javascript.Parser;
import org.mozilla.javascript.ast.AstNode;
import org.mozilla.javascript.ast.AstRoot;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;


/**
 * Tests that the dependency computer class reports dependencies correctly.
 */
public class DependencyComputerTest extends TestCase {
  private Parser parser = new Parser();
  private Map<String, List<JavascriptElement>> namesToElements = Maps.newHashMap();
  private List<AstNode> globals = new ArrayList<AstNode>();
  private TopLevelElementIndexer topLevelElementIndexer = new TopLevelElementIndexer(
      namesToElements, globals);
  private DependencyComputer dependencyComputer = new DependencyComputer(namesToElements);

  /**
   * Tests that we don't add virtual dependencies for names that are shadowed by
   * local variables.
   */
  public void testLocalVariableShadowingOfMemberOfUninstantiatedClass() {
    StringBuilder sb = new StringBuilder();
    sb.append("function A() {}\n");
    sb.append("A.prototype.foo = function() {}\n");
    sb.append("function B() {}\n");
    sb.append("B.prototype.foo = function() {}\n");
    sb.append("function execute() { var foo = 1; foo(); }");

    AstRoot astRoot = parser.parse(sb.toString(), "", 1);
    astRoot.visit(topLevelElementIndexer);
    AstNode executeFunction = (AstNode) astRoot.getLastChild();
    List<JavascriptElement> computedDependencies =
        dependencyComputer.computeDependencies(executeFunction);
    assertNotNull(computedDependencies);

    /*
     * The foo inside of execute method should lexically resolve to the local
     * variable hence foo() does not introduce a dependency on A.prototype.foo
     * or B.prototype.foo.
     */
    assertEquals(0, computedDependencies.size());
  }

  /**
   * Tests that we do add a virtual dependency to a member of an instantiated
   * class even though its name is shadowed by a local variable.
   */
  public void testLocalVariableShadowingOfMemberOfInstantiatedClass() {
    StringBuilder sb = new StringBuilder();
    sb.append("function A() {}\n");
    sb.append("A.prototype.foo = function() {}\n");
    sb.append("function B() {}\n");
    sb.append("B.prototype.foo = function() {}\n");
    sb.append("function execute() { var foo = 1; new A(); this.foo(); }");

    AstRoot astRoot = parser.parse(sb.toString(), "", 1);
    astRoot.visit(topLevelElementIndexer);
    AstNode executeFunction = (AstNode) astRoot.getLastChild();
    List<JavascriptElement> computedDependencies =
        dependencyComputer.computeDependencies(executeFunction);
    assertNotNull(computedDependencies);

    /*
     * The foo inside of execute method should lexically resolve to the local
     * variable foo, but this.foo() introduces a dependency on A.prototype.foo since A is 
     * instantiated and foo is qualified.
     */
    assertEquals(2, computedDependencies.size());
  }

  /**
   * Tests that referencing a static method through only pulls in the static
   * method and the enclosing function.
   */
  public void testStaticReferencesToStaticMethods() {
    StringBuilder sb = new StringBuilder();
    sb.append("function A() {}\n");
    sb.append("A.prototype.foo = function() {}\n");
    sb.append("function B() {}\n");
    sb.append("B.foo = function() {}\n");
    sb.append("function execute() { B.foo(); }");

    AstRoot astRoot = parser.parse(sb.toString(), "", 1);
    astRoot.visit(topLevelElementIndexer);
    AstNode executeFunction = (AstNode) astRoot.getLastChild();
    List<JavascriptElement> computedDependencies =
        dependencyComputer.computeDependencies(executeFunction);
    assertNotNull(computedDependencies);

    // Computed dependencies should be B and B.foo
    assertEquals(2, computedDependencies.size());
    List<JavascriptElement> list = new ArrayList<JavascriptElement>(namesToElements.get("B"));
    list.addAll(namesToElements.get("B.foo"));
    assertEquals(list, computedDependencies);
  }

  /**
   * Tests that referencing a virtual method through a static reference doesn't
   * introduce a virtual reference to the method.
   */
  public void testStaticReferencesToVirtualMethods() {
    StringBuilder sb = new StringBuilder();
    sb.append("function A() {}\n");
    sb.append("A.prototype.foo = function() {}\n");
    sb.append("function execute() { A.prototype.foo.call(this); }");
    AstRoot astRoot = parser.parse(sb.toString(), "", 1);
    astRoot.visit(topLevelElementIndexer);
    AstNode executeFunction = (AstNode) astRoot.getLastChild();
    List<JavascriptElement> computedDependencies =
        dependencyComputer.computeDependencies(executeFunction);
    assertNotNull(computedDependencies);
    assertEquals(1, computedDependencies.size());
    
    // Static reference to A.prototype.foo
    assertEquals(namesToElements.get("A.prototype.foo"), computedDependencies);
  }

  /**
   * Tests that referencing a virtual method only pulls in similarly named
   * virtual methods on classes that have been instantiated.d
   */
  public void testVirtualReferences() {
    StringBuilder sb = new StringBuilder();
    sb.append("function A() {}\n");
    sb.append("A.prototype.foo = function() {}\n");
    sb.append("function B() {}\n");
    sb.append("B.prototype.foo = function() {}\n");
    sb.append("function execute() { new A(); foo(); }");

    AstRoot astRoot = parser.parse(sb.toString(), "", 1);
    astRoot.visit(topLevelElementIndexer);
    AstNode executeFunction = (AstNode) astRoot.getLastChild();
    List<JavascriptElement> computedDependencies =
        dependencyComputer.computeDependencies(executeFunction);
    assertNotNull(computedDependencies);

    /*
     * Expect a dependency on A and A.prototype.foo, B was not instantiated so
     * B.prototype.foo does not qualify
     */
    assertEquals(2, computedDependencies.size());
    List<JavascriptElement> list = new ArrayList<JavascriptElement>(namesToElements.get("A"));
    list.addAll(namesToElements.get("A.prototype.foo"));
    assertEquals(list, computedDependencies);
  }
}
