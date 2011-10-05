// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.DartComment;
import com.google.dart.compiler.ast.DartUnit;

import java.util.ArrayList;
import java.util.List;

/**
 * Tests for the parser, which simply assert that valid source units parse
 * correctly. All tests invoking {@code parseUnit} are designed such that
 * they will throw an exception if anything goes wrong in the parser.
 */
public class CPParserTest extends CompilerTestCase {

  private static String[] EXPECTED001 = {"/*\n * Beginning comment\n */",
    "// line comment", "// another", "/**/", "//",
  };
  private static String[] EXPECTED002 = {"/*\n*\n //comment\nX Y"};

  private String source;
  private CommentPreservingParser parser;

  public void test001() {
    DartUnit unit = parseUnit("Comments.dart");
    compareComments(unit.getComments(), EXPECTED001);
  }

  public void test002() {
    DartUnit unit = parseUnitErrors("BadCommentNegativeTest.dart",
                                    "Unexpected token 'ILLEGAL' (expected end of file)", 1, 1);
    compareComments(unit.getComments(), EXPECTED002);
  }

  @Override
  protected DartParser makeParser(ParserContext context) {
    parser = new CommentPreservingParser(context, false);
    return parser;
  }

  @Override
  protected ParserContext makeParserContext(Source src, String sourceCode,
      DartCompilerListener listener) {
    this.source = sourceCode;
    return CommentPreservingParser.createContext(src, sourceCode, listener);
  }

  private List<String> extractComments(List<DartComment> cms) {
    List<String> comments = new ArrayList<String>();
    for (DartComment cm : cms) {
      comments.add(source.substring(cm.getSourceStart(), cm.getSourceStart()+cm.getSourceLength()));
    }
    return comments;
  }

  private void compareComments(List<DartComment> cms, String[] expected) {
    List<String> comments = extractComments(cms);
    assertEquals(expected.length, comments.size());
    for (int i = 0; i < expected.length; i++) {
      assertEquals(expected[i], comments.get(i));
    }
  }

}
