// Copyright 2011 Google Inc. All Rights Reserved.

package com.google.dart.compiler.backend.js.analysis;

import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.MockLibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.testing.TestCompilerContext;

import junit.framework.TestCase;

import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;

/**
 * Tests the JS based tree shaker used in incremental compilation.
 */
public class TreeShakerTest extends TestCase {
  class MockCompilerContext extends TestCompilerContext {
    private final String srcCode;

    public MockCompilerContext(String srcCode) {
      this.srcCode = srcCode;
    }

    @Override
    public Reader getArtifactReader(Source source, String part, String extension) {
      return new StringReader(srcCode);
    }
  }

  /**
   * Tests that {@link TreeShaker#reduce(LibrarySource, DartCompilerContext, String, Writer)} can
   * remove unused methods.
   */
  public void testReduce() throws IOException {
    StringBuffer inputSrc = new StringBuffer();
    inputSrc.append("function A() {}\n");
    inputSrc.append("A.prototype.foo = function(){}\n");
    inputSrc.append("function B() {}\n");
    inputSrc.append("B.prototype.foo = function(){}\n");
    inputSrc.append("function C() { A(); }\n");
    inputSrc.append("RunEntry(C);\n");

    StringWriter outputCode = new StringWriter();

    TreeShaker.reduce(new MockLibrarySource(), new MockCompilerContext(inputSrc.toString()), "",
        outputCode);

    StringBuffer outputSrc = new StringBuffer();
    outputSrc.append("function A() {}\n");
    outputSrc.append("function C() { A(); }\n");
    outputSrc.append("RunEntry(C);\n");

    assertEquals(outputSrc.toString(), outputCode.toString());
  }

  /**
   * Tests that {@link TreeShaker#reduce(LibrarySource, DartCompilerContext, String, Writer)} can 
   * handle empty code.
   */
  public void testReduceEmpty() throws IOException {
    StringReader inputSrc = new StringReader("");
    StringWriter outputSrc = new StringWriter();
    TreeShaker.reduce(new MockLibrarySource(), new MockCompilerContext(""), "", outputSrc);
    
    assertEquals("", outputSrc.toString());
  }
}
