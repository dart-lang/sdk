// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.dart.compiler.backend.js.JsToStringGenerationVisitor;

import junit.framework.TestCase;

import org.mozilla.javascript.Node;
import org.mozilla.javascript.Parser;
import org.mozilla.javascript.Token;
import org.mozilla.javascript.ast.AstNode;
import org.mozilla.javascript.ast.ExpressionStatement;
import org.mozilla.javascript.ast.StringLiteral;

import java.io.IOException;
import java.io.StringReader;

/**
 * Tests {@link JsToStringGenerationVisitor#javaScriptString(String)}.
 */
public class JavaScriptStringTest extends TestCase {
  private void test(String original) throws IOException {
    String escaped = JsToStringGenerationVisitor.javaScriptString(original);

    // Parse it back
    Parser parser = new Parser();
    AstNode node = parser.parse(new StringReader(escaped), "virtual file", 1);
    assertEquals(Token.SCRIPT, node.getType());
    Node exprResult = node.getFirstChild();
    assertEquals(Token.EXPR_RESULT, node.getFirstChild().getType());
    ExpressionStatement exprStatement = (ExpressionStatement) node.getFirstChild();
    assertEquals(Token.STRING, exprStatement.getExpression().getType());
    StringLiteral stringLiteral = (StringLiteral) exprStatement.getExpression();
    assertEquals(original, stringLiteral.getValue());

    // It should be the only token
    assertNull(node.getNext());
  }

  public void testBasic() throws IOException {
    test("abc");
    test("");
    test("abc\0def");
    test("abc\\def");
    test("\u00CC\u1234\5678\uabcd");
    test("'''");
    test("\"\"\"");
    test("\b\f\n\r\t");
  }
}
