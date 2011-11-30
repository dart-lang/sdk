// Copyright 2011 Google Inc. All Rights Reserved.

package com.google.dart.compiler.backend.js.analysis;

import com.google.common.collect.Maps;

import junit.framework.TestCase;

import org.mozilla.javascript.Parser;
import org.mozilla.javascript.Token;
import org.mozilla.javascript.ast.AstNode;
import org.mozilla.javascript.ast.AstRoot;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Tests how "top-level" elements are identified in Javascript code.
 */
public class TopLevelElementIndexerTest extends TestCase {
  /**
   * Tests that we can find top-level invocations to the RunEntry method to anchor the analysis.
   */
  public void testGetEntryPoints() {
    Parser parser = new Parser();
    AstRoot astRoot = parser.parse("function main() {} RunEntry(main)", "", 1);
    Map<String, List<JavascriptElement>> namesToElements = Maps.newHashMap();
    List<AstNode> globals = new ArrayList<AstNode>();
    TopLevelElementIndexer topLevelElementIndexer =
        new TopLevelElementIndexer(namesToElements, globals);
    
    astRoot.visit(topLevelElementIndexer);
    List<AstNode> entryPoints = topLevelElementIndexer.getEntryPoints();
    assertFalse(entryPoints.isEmpty());
    
    // Assert that the entry point node is the "RunEntry(main) node.
    assertEquals(astRoot.getLastChild(), entryPoints.get(0));
  }
  
  /**
   * Tests that we don't find any entry point invocations.
   */
  public void testGetEntryPointsEmpty() {
    Parser parser = new Parser();
    AstRoot astRoot = parser.parse("function main() {}", "", 1);
    Map<String, List<JavascriptElement>> namesToElements = Maps.newHashMap();
    List<AstNode> globals = new ArrayList<AstNode>();
    TopLevelElementIndexer topLevelElementIndexer =
        new TopLevelElementIndexer(namesToElements, globals);
    astRoot.visit(topLevelElementIndexer);
    List<AstNode> entryPoints = topLevelElementIndexer.getEntryPoints();
    assertTrue(entryPoints.isEmpty());
  }

  /**
   * Test that we find global symbols.
   */
  public void testGlobals() {
    Parser parser = new Parser();
    AstRoot astRoot = parser.parse("if (true) {}", "", 1);
    Map<String, List<JavascriptElement>> namesToElements = Maps.newHashMap();
    List<AstNode> globals = new ArrayList<AstNode>();
    TopLevelElementIndexer topLevelElementIndexer =
        new TopLevelElementIndexer(namesToElements, globals);
    astRoot.visit(topLevelElementIndexer);
    
    // if (true) {} should not introduce a top level name and should be a global
    assertTrue(namesToElements.isEmpty());
    
    assertEquals(1, globals.size());
  }
  
  /**
   * Checks that instance methods are associated with their parent and that their names appear
   * as fully qualified "A.prototype.Hello" and virtually as "Hello".
   */
  public void testInstanceFunctions() {
    Parser parser = new Parser();
    AstRoot astRoot = parser.parse("function A() {} A.prototype.Hello = function(){}", "", 1);
    Map<String, List<JavascriptElement>> namesToElements = Maps.newHashMap();
    List<AstNode> globals = new ArrayList<AstNode>();
    TopLevelElementIndexer topLevelElementIndexer =
        new TopLevelElementIndexer(namesToElements, globals);
    astRoot.visit(topLevelElementIndexer);
    
    assertEquals(0, globals.size());
    // A, A.prototype.Hello and Hello
    assertEquals(3, namesToElements.size());
    
    List<JavascriptElement> list = namesToElements.get("A");
    assertNotNull(list);
    assertEquals(1, list.size());
    JavascriptElement a = list.get(0);
    assertEquals(1, a.getMembers().size());
    
    list = namesToElements.get("A.prototype.Hello");
    assertNotNull(list);
    assertEquals(1, list.size());
    
    JavascriptElement javascriptElement = list.get(0);
    assertEquals(list.get(0), namesToElements.get("Hello").get(0));
    
    assertNotNull(javascriptElement);
    assertTrue(javascriptElement.isVirtual());
    AstNode node = javascriptElement.getNode();
    assertEquals(Token.EXPR_RESULT, node.getType());
    assertEquals(a, javascriptElement.getEnclosingElement());
  }
  
  /**
   * Checks that static functions get associated with their parent.
   */
  public void testStaticFunctions() {
    Parser parser = new Parser();
    AstRoot astRoot = parser.parse("function A() {} A.Hello = function(){}", "", 1);
    Map<String, List<JavascriptElement>> namesToElements = Maps.newHashMap();
    List<AstNode> globals = new ArrayList<AstNode>();
    TopLevelElementIndexer topLevelElementIndexer =
        new TopLevelElementIndexer(namesToElements, globals);
    astRoot.visit(topLevelElementIndexer);
    
    assertEquals(0, globals.size());
    assertEquals(2, namesToElements.size());
    
    List<JavascriptElement> list = namesToElements.get("A");
    assertNotNull(list);
    assertEquals(1, list.size());
    JavascriptElement a = list.get(0);
    assertFalse(a.isVirtual());
    assertEquals(1, a.getMembers().size());
    
    list = namesToElements.get("A.Hello");
    assertNotNull(list);
    assertEquals(1, list.size());
    
    JavascriptElement javascriptElement = list.get(0);
    assertFalse(javascriptElement.isVirtual());
    
    assertNotNull(javascriptElement);
    AstNode node = javascriptElement.getNode();
    assertEquals(Token.EXPR_RESULT, node.getType());
    assertEquals(a, javascriptElement.getEnclosingElement());
  }

  public void testStaticFunctions2() {
    Parser parser = new Parser();
    AstRoot astRoot = parser.parse("var A = new Object(); A.Hello = function(){}", "", 1);
    Map<String, List<JavascriptElement>> namesToElements = Maps.newHashMap();
    List<AstNode> globals = new ArrayList<AstNode>();
    TopLevelElementIndexer topLevelElementIndexer =
        new TopLevelElementIndexer(namesToElements, globals);
    astRoot.visit(topLevelElementIndexer);
    
    assertEquals(0, globals.size());
    assertEquals(2, namesToElements.size());
    
    List<JavascriptElement> list = namesToElements.get("A");
    assertNotNull(list);
    assertEquals(1, list.size());
    JavascriptElement a = list.get(0);
    assertFalse(a.isVirtual());
    assertEquals(1, a.getMembers().size());
    
    list = namesToElements.get("A.Hello");
    assertNotNull(list);
    assertEquals(1, list.size());
    
    JavascriptElement javascriptElement = list.get(0);
    assertFalse(javascriptElement.isVirtual());
    
    assertNotNull(javascriptElement);
    AstNode node = javascriptElement.getNode();
    assertEquals(Token.EXPR_RESULT, node.getType());
    assertEquals(a, javascriptElement.getEnclosingElement());
  }

  public void testTopLevelFunctions() {
    Parser parser = new Parser();
    AstRoot astRoot = parser.parse("function Hello(){}", "", 1);
    Map<String, List<JavascriptElement>> namesToElements = Maps.newHashMap();
    List<AstNode> globals = new ArrayList<AstNode>();
    TopLevelElementIndexer topLevelElementIndexer =
        new TopLevelElementIndexer(namesToElements, globals);
    astRoot.visit(topLevelElementIndexer);
    
    assertEquals(0, globals.size());
    assertEquals(1, namesToElements.size());
    
    List<JavascriptElement> list = namesToElements.get("Hello");
    assertNotNull(list);
    assertEquals(1, list.size());
    
    JavascriptElement javascriptElement = list.get(0);
    assertNotNull(javascriptElement);
    assertEquals(Token.FUNCTION, javascriptElement.getNode().getType());
  }

  /**
   * Tests that names that appear in a variable declaration map to the same node if they are in 
   * part of the same variable declaration.
   */
  public void testVariables() {
    Parser parser = new Parser();
    AstRoot astRoot = parser.parse("var A = 1, B = 2; var C;", "", 1);
    Map<String, List<JavascriptElement>> namesToElements = Maps.newHashMap();
    List<AstNode> globals = new ArrayList<AstNode>();
    TopLevelElementIndexer topLevelElementIndexer =
        new TopLevelElementIndexer(namesToElements, globals);
    astRoot.visit(topLevelElementIndexer);
    
    assertEquals(3, namesToElements.size());
    List<JavascriptElement> a = namesToElements.get("A");
    List<JavascriptElement> b = namesToElements.get("B");
    assertEquals(a.get(0).getNode(), b.get(0).getNode());
    
    List<JavascriptElement> c = namesToElements.get("C");
    assertEquals(1, c.size());
    assertNotSame(a.get(0).getNode(), c.get(0).getNode());
  }

  /**
   * Tests that we handle "natives" correctly and that we associate virtual members with them.
   */
  public void testNatives() {
    Parser parser = new Parser();
    AstRoot astRoot = parser.parse("Array.prototype.foo = function() {}", "", 1);
    Map<String, List<JavascriptElement>> namesToElements = Maps.newHashMap();
    List<AstNode> globals = new ArrayList<AstNode>();
    TopLevelElementIndexer topLevelElementIndexer =
        new TopLevelElementIndexer(namesToElements, globals);
    astRoot.visit(topLevelElementIndexer);
    
    // Array (native), Array.prototype.foo, foo
    assertEquals(3, namesToElements.size());
    
    List<JavascriptElement> list = namesToElements.get("Array");
    JavascriptElement javascriptElement = list.get(0);
    assertTrue(javascriptElement.isNative());
    assertEquals(1, javascriptElement.getMembers().size());
    
    List<JavascriptElement> staticFoo = namesToElements.get("Array.prototype.foo");
    assertEquals(1, staticFoo.size());
    List<JavascriptElement> virtualFoo = namesToElements.get("foo");
    assertEquals(1, virtualFoo.size());
    assertEquals(staticFoo.get(0), virtualFoo.get(0));
    assertTrue(virtualFoo.get(0).isVirtual());
  }
}
