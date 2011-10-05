// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.javascript.jscomp.CodingConvention.Bind;
import com.google.javascript.rhino.Node;
import com.google.javascript.rhino.Token;

import junit.framework.TestCase;

/**
 * @author johnlenz@google.com (John Lenz)
 */
public class ClosureJsCodingConventionTest extends TestCase {
   public void testBind() {
     ClosureJsCodingConvention convention = new ClosureJsCodingConvention();

     // don't recognize a non-bind call.
     Node expr = new Node(Token.CALL, Node.newString(Token.NAME, "foo"));
     assertNull(convention.describeFunctionBind(expr));

     // don't recognize a bind call.
     expr = new Node(Token.CALL,
       Node.newString(Token.NAME, "$bind"), new Node(Token.THIS));
     Bind bind = convention.describeFunctionBind(expr);
     assertNotNull(bind);
   }
}
