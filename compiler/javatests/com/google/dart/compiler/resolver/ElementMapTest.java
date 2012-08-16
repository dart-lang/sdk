// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartObsoleteMetadata;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.Type;

import junit.framework.TestCase;

public class ElementMapTest extends TestCase {

  private class MockElement implements NodeElement {

    private final ElementKind kind;
    private final String name;

    public MockElement(String name, ElementKind kind) {
      this.name = name;
      this.kind = kind;
    }

    @Override
    public EnclosingElement getEnclosingElement() {
      throw new RuntimeException();
    }

    @Override
    public ElementKind getKind() {
      return kind;
    }

    @Override
    public DartObsoleteMetadata getMetadata() {
      throw new RuntimeException();
    }

    @Override
    public Modifiers getModifiers() {
      throw new RuntimeException();
    }

    @Override
    public String getName() {
      return name;
    }

    @Override
    public DartNode getNode() {
      throw new RuntimeException();
    }

    @Override
    public String getOriginalName() {
      throw new RuntimeException();
    }

    @Override
    public Type getType() {
      throw new RuntimeException();
    }

    @Override
    public boolean isDynamic() {
      throw new RuntimeException();
    }

    @Override
    public SourceInfo getSourceInfo() {
      throw new RuntimeException();
    }
    
    @Override
    public SourceInfo getNameLocation() {
      throw new RuntimeException();
    }
  }

  public void testAdd1() {
    ElementMap map = new ElementMap();
    MockElement element = new MockElement("foo", ElementKind.METHOD);
    map.add("foo", element);
    assertEquals(1, map.size());
    assertEquals(1, map.values().size());
    assertEquals(element, map.values().get(0));
    assertEquals(element, map.get("foo"));
    assertNull(map.get("bar"));
    assertNull(map.get("foo", ElementKind.FIELD));
    assertEquals(element, map.get("foo", ElementKind.METHOD));
  }

  public void testAdd1DifferentName() {
    ElementMap map = new ElementMap();
    MockElement element = new MockElement("bar", ElementKind.METHOD);
    map.add("foo", element);
    assertEquals(1, map.size());
    assertEquals(1, map.values().size());
    assertEquals(element, map.values().get(0));
    assertEquals(element, map.get("foo"));
    assertNull(map.get("bar"));
    assertNull(map.get("foo", ElementKind.FIELD));
    assertEquals(element, map.get("foo", ElementKind.METHOD));
  }

  public void testAdd2() {
    ElementMap map = new ElementMap();
    MockElement element = new MockElement("foo", ElementKind.METHOD);
    MockElement element2 = new MockElement("bar", ElementKind.METHOD);
    map.add("foo", element);
    map.add("bar", element2);
    assertEquals(2, map.size());
    assertEquals(2, map.values().size());
    assertEquals(element, map.values().get(0));
    assertEquals(element2, map.values().get(1));
    assertEquals(element, map.get("foo"));
    assertEquals(element2, map.get("bar"));
    assertNull(map.get("foo", ElementKind.FIELD));
    assertEquals(element, map.get("foo", ElementKind.METHOD));
  }

  public void testAdd2SameName() {
    ElementMap map = new ElementMap();
    MockElement element = new MockElement("foo", ElementKind.METHOD);
    MockElement element2 = new MockElement("foo", ElementKind.FIELD);
    map.add("foo", element);
    map.add("foo", element2);
    assertEquals(2, map.size());
    assertEquals(2, map.values().size());
    assertEquals(element, map.values().get(0));
    assertEquals(element2, map.values().get(1));
    assertEquals(element, map.get("foo"));
    assertNull(map.get("bar"));
    assertEquals(element2, map.get("foo", ElementKind.FIELD));
    assertEquals(element, map.get("foo", ElementKind.METHOD));
  }
  
  public void testDuplicate() throws Exception {
    ElementMap map = new ElementMap();
    MockElement element = new MockElement("foo", ElementKind.METHOD);
    assertEquals(0, map.size());
    map.add("foo", element);
    assertEquals(1, map.size());
    map.add("foo", element);
    assertEquals(1, map.size());
  }
  
  public void testDuplicate2() throws Exception {
    ElementMap map = new ElementMap();
    MockElement element = new MockElement("foo", ElementKind.METHOD);
    MockElement element2 = new MockElement("foo", ElementKind.FIELD);
    assertEquals(0, map.size());
    map.add("foo", element);
    assertEquals(1, map.size());
    map.add("foo", element2);
    assertEquals(2, map.size());
    map.add("foo", element);
    assertEquals(2, map.size());
    map.add("foo", element2);
    assertEquals(2, map.size());
  }

  public void testEmpty() throws Exception {
    ElementMap map = new ElementMap();
    assertEmpty(map);
  }

  public void testGrow() throws Exception {
    ElementMap map = new ElementMap();
    MockElement element = new MockElement("foo", ElementKind.METHOD);
    MockElement element2 = new MockElement("foo", ElementKind.FIELD);
    map.add("foo", element);
    map.add("foo", element2);

    for (int i = 0; i < 100; i++) {
      map.add("mem" + i, new MockElement("mem" + i, ElementKind.METHOD));
    }

    assertEquals(element, map.values().get(0));
    assertEquals(element2, map.values().get(1));
    assertEquals(element, map.get("foo"));
    assertNull(map.get("bar"));
    assertEquals(element2, map.get("foo", ElementKind.FIELD));
    assertEquals(element, map.get("foo", ElementKind.METHOD));
  }

  private void assertEmpty(ElementMap map) {
    assertTrue(map.isEmpty());
    assertEquals(0, map.size());
    assertEquals(0, map.values().size());
    assertNull(map.get("foo"));
    assertNull(map.get("bar"));
    assertNull(map.get("foo", ElementKind.FIELD));
    assertNull(map.get("foo", ElementKind.METHOD));
  }
}
