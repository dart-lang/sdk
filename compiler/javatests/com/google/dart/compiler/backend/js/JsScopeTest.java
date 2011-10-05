// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.dart.compiler.backend.js.ast.JsName;
import com.google.dart.compiler.backend.js.ast.JsRootScope;
import com.google.dart.compiler.backend.js.ast.JsScope;

import junit.framework.TestCase;

/**
 * Tests {@link JsScope} and {@link JsName}.
 */
public class JsScopeTest extends TestCase {
  public void testRootScope() {
    JsScope scope = new JsRootScope(null);
    JsName name = scope.declareName("foo");
    assertSame(name, scope.findExistingName("foo"));
    assertTrue("foo".equals(name.getOriginalName()));
    JsName name2 = scope.declareName("foo");
    assertSame(name, name2);

    name = scope.declareName("bar");
    assertSame(name, scope.findExistingName("bar"));
    assertTrue("bar".equals(name.getOriginalName()));
    name2 = scope.declareName("bar");
    assertSame(name, name2);

    name = scope.declareName("false");
    assertTrue("false".equals(name.getIdent()));
    assertTrue("false".equals(name.getShortIdent()));
    assertTrue("false".equals(name.getOriginalName()));
  }

  public void testJsNames() {
    JsScope scope = new JsRootScope(null);

    JsName name = scope.declareName("foobar1");
    assertTrue("foobar1".equals(name.getIdent()));
    assertTrue("foobar1".equals(name.getShortIdent()));
    assertTrue("foobar1".equals(name.getOriginalName()));

    name = scope.declareName("foobar2", "foobar3");
    assertTrue("foobar2".equals(name.getIdent()));
    assertTrue("foobar3".equals(name.getShortIdent()));
    assertTrue("foobar2".equals(name.getOriginalName()));

    name = scope.declareName("foobar4", "foobar5", "foobar6");
    assertTrue("foobar4".equals(name.getIdent()));
    assertTrue("foobar5".equals(name.getShortIdent()));
    assertTrue("foobar6".equals(name.getOriginalName()));
  }

  public void testNestedScope() {
    JsScope rootScope = new JsRootScope(null);
    JsScope scope = new JsScope(rootScope, "nested", "unitid");

    // First the basic operations.
    JsName name = scope.declareName("foo");
    assertSame(name, scope.findExistingName("foo"));
    assertTrue("foo".equals(name.getOriginalName()));
    JsName name2 = scope.declareName("foo");
    assertSame(name, name2);
    name = scope.declareName("bar");
    assertSame(name, scope.findExistingName("bar"));
    assertTrue("bar".equals(name.getOriginalName()));
    name2 = scope.declareName("bar");
    assertSame(name, name2);

    // Test deep search.
    name = rootScope.declareName("fisk");
    name2 = scope.findExistingName("fisk");
    assertSame(name, name2);
    // Test shadowing.
    name2 = scope.declareName("fisk");
    assertNotSame(name, name2);
    assertTrue("fisk".equals(name2.getOriginalName()));
  }
}
