// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.common.collect.Lists;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.DartComment;
import com.google.dart.compiler.ast.DartDeclaration;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.common.SourceInfo;

import java.util.List;

/**
 * Tests to ensure the scanner is correctly recording comments, as defined
 * in the javadoc for <code>DartScanner.recordCommentLocation().</code>
 */
public class CommentTest extends CompilerTestCase {
  private String source;

  private static String[] EXPECTED001 = {"/*\n * Beginning comment\n */",
    "// line comment", "// another", "/**/", "//", "/*/*nested*/*/",
  };
  private static String[] EXPECTED002 = {"/*\n*\n //comment\nX Y"};

  public void test001() {
    DartUnit unit = parseUnit("Comments.dart");
    compareComments(unit, EXPECTED001);
  }

  public void test002() {
    DartUnit unit = parseUnitErrors("BadCommentNegativeTest.dart",
                    "Unexpected token 'ILLEGAL' (expected end of file)", 1, 1);
    compareComments(unit, EXPECTED002);
  }

  public void test003() {
    DartUnit unit = parseUnit("Comments2.dart");
    assertDeclComments(unit, "firstMethod", "/** Comments are good. */");
    assertDeclComments(unit, "secondMethod", null);
  }
  
  @Override
  protected DartParser makeParser(Source src, String sourceCode, DartCompilerListener listener) {
    source = sourceCode;
    return super.makeParser(src, sourceCode, listener);
  }

  private List<String> extractComments(DartUnit unit) {
    List<String> comments = Lists.newArrayList();
    List<DartComment> commentNodes = unit.getComments();
    for (DartComment commentNode : commentNodes) {
      SourceInfo sourceInfo = commentNode.getSourceInfo();
      String comment = source.substring(sourceInfo.getOffset(), sourceInfo.getEnd());
      comments.add(comment);
    }
    return comments;
  }

  private void compareComments(DartUnit unit, String[] expected) {
    List<String> comments = extractComments(unit);
    assertEquals(expected.length, comments.size());
    for (int i = 0; i < expected.length; i++) {
      assertEquals(expected[i], comments.get(i));
    }
  }

  private void assertDeclComments(DartUnit unit, String name, String comments) {
    for (DartNode node : unit.getTopLevelNodes()) {
      if (node instanceof DartDeclaration && node.getElement() != null
          && name.equals(node.getElement().getOriginalName())) {
        DartDeclaration<?> decl = (DartDeclaration<?>)node;
        String nodeComments = null;

        if (decl.getDartDoc() != null) {
          nodeComments = decl.getDartDoc().toSource();
        }

        assertEquals(comments, nodeComments);
      }
    }
  }
}
