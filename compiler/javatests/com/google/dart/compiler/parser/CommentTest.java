// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.Source;

import java.util.ArrayList;
import java.util.List;

/**
 * Tests to ensure the scanner is correctly recording comments, as defined
 * in the javadoc for <code>DartScanner.recordCommentLocation().</code>
 */
public class CommentTest extends CompilerTestCase {

  /**
   * A parser context that uses its own scanner.
   */
  class CommentParserContext extends DartScannerParserContext {

    CommentParserContext(Source source, String sourceCode,
        DartCompilerListener listener) {
      super(source, sourceCode, listener);
    }

    protected DartScanner createScanner(String sourceCode) {
      return new CommentScanner(sourceCode);
    }
  }

  /**
   * A specialized scanner that records comment locations. It would have been
   * more natural to use the parser context to record comments, but the
   * scanner doesn't know about the context.
   */
  class CommentScanner extends DartScanner {

    CommentScanner(String sourceCode) {
      super(sourceCode);
    }

    @Override
    protected void recordCommentLocation(int start, int stop, int line, int col) {
      int size = commentLocs.size();
      if (size > 0) {
        // check for duplicates
        int[] loc = commentLocs.get(size - 1);
        // use <= to allow parser to back up more than one token
        if (start <= loc[0] && stop <= loc[1]) {
          return;
        }
      }
      commentLocs.add(new int[]{start, stop});
    }
  }

  private List<int[]> commentLocs = new ArrayList<int[]>();
  private String source;

  private static String[] EXPECTED001 = {"/*\n * Beginning comment\n */",
    "// line comment", "// another", "/**/", "//",
  };
  private static String[] EXPECTED002 = {"/*\n*\n //comment\nX Y"};

  public void test001() {
    parseUnit("Comments.dart");
    compareComments(EXPECTED001);
  }

  public void test002() {
    parseUnitErrors("BadCommentNegativeTest.dart",
                    "Unexpected token 'ILLEGAL' (expected end of file)", 1, 1);
    compareComments(EXPECTED002);
  }

  @Override
  protected ParserContext makeParserContext(Source src, String sourceCode,
      DartCompilerListener listener) {
    // initializing source and commentLocs here is a bit of a hack but it
    // means parseUnit() and parseUnitErrors() do not have to be overridden
    source = sourceCode;
    commentLocs.clear();
    return new CommentParserContext(src, sourceCode, listener);
  }

  private List<String> extractComments() {
    List<String> comments = new ArrayList<String>();
    for (int[] loc : commentLocs) {
      comments.add(source.substring(loc[0], loc[1]));
    }
    return comments;
  }

  private void compareComments(String[] expected) {
    List<String> comments = extractComments();
    assertEquals(expected.length, comments.size());
    for (int i = 0; i < expected.length; i++) {
      assertEquals(expected[i], comments.get(i));
    }
  }
}
