// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.io.CharStreams;
import com.google.dart.compiler.Backend;
import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartArtifactProvider;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.MockArtifactProvider;
import com.google.dart.compiler.backend.dart.DartBackend;
import com.google.dart.compiler.backend.js.ClosureJsBackend;
import com.google.dart.compiler.backend.js.JavascriptBackend;
import com.google.debugging.sourcemap.FilePosition;
import com.google.debugging.sourcemap.SourceMapConsumerFactory;
import com.google.debugging.sourcemap.SourceMapParseException;
import com.google.debugging.sourcemap.SourceMapSection;
import com.google.debugging.sourcemap.SourceMapping;
import com.google.debugging.sourcemap.proto.Mapping.OriginalMapping;

import java.io.IOException;
import java.io.StringWriter;
import java.util.List;
import java.util.Map;

/**
 * Tests for {@link GenerateSourceMap}.
 *
 * @author jschorr@google.com (Joseph Schorr)
 * @author johnlenz@google.com (John Lenz)
 */
public class GenerateSourceMapTest extends CompilerTestCase {

  // TODO(johnlenz): support detail levels

  enum ResultType {
    JS,
    CLOSURE_JS,
    DART
  }

  @Override
  public void setUp() {
  }

  // TODO(johnlenz): fix this
  public void disable_testClassMapping() throws Exception {
    compileAndCheck("class __CLASS__ { }", "__CLASS__");
  }

  public void testMethodMapping() throws Exception {
    compileAndCheck("class myClass { static __MEMBER__() {} }", "myClass");
  }

  // TODO(johnlenz): fix this
  public void disable_testFieldMapping1() throws Exception {
    compileAndCheck("class myClass { const int __FIELD__; }", "myClass");
  }

  // TODO(johnlenz): fails
  public void disable_testFieldMapping2() throws Exception {
    compileAndCheck("class myClass { static const int __FIELD__ = 1; }", "myClass");
  }

  public void testMethodParamMapping() throws Exception {
    compileAndCheck("class myClass { static member(__PARAM1__, __PARAM2__) {} }", "myClass");
  }

  public void testNamedFunctionMapping() throws Exception {
    compileAndCheck(
        "class c {\n" +
        "  void member() {\n" +
        "    __FN__(__PARAM1__, __PARAM2__) {}\n" +
        "  }" +
        "}", "c");
  }

  public void testLocalMapping() throws Exception {
    compileAndCheck(
        "class c {\n" +
        "  void member() {\n" +
        "    var __VAR__ = '__STR__'; \n" +
        "  }" +
        "}", "c");
  }

  public void testLocalInClosureMapping() throws Exception {
    compileAndCheck(
        "class c {\n" +
        "  void member() {\n" +
        "    fn(p1, p2) {\n" +
        "      var __VAR__ = '__STR__'; \n" +
        "    }\n" +
        "  }" +
        "}", "c");
  }

  public void testWriteMetaMap() throws IOException {
    StringWriter out = new StringWriter();
    String name = "./app.js";
    List<SourceMapSection> appSections = Lists.newArrayList(
        SourceMapSection.forURL("src1", 0, 0),
        SourceMapSection.forURL("src2", 100, 10),
        SourceMapSection.forURL("src3", 150, 5));

    new GenerateSourceMap().appendIndexMapTo(out, name, appSections);

    assertEquals(
            "{\n" +
            "\"version\":3,\n" +
            "\"file\":\"./app.js\",\n" +
            "\"sections\":[\n" +
            "{\n" +
            "\"offset\":{\n" +
            "\"line\":0,\n" +
            "\"column\":0\n" +
            "},\n" +
            "\"url\":\"src1\"\n" +
            "},\n" +
            "{\n" +
            "\"offset\":{\n" +
            "\"line\":100,\n" +
            "\"column\":10\n" +
            "},\n" +
            "\"url\":\"src2\"\n" +
            "},\n" +
            "{\n" +
            "\"offset\":{\n" +
            "\"line\":150,\n" +
            "\"column\":5\n" +
            "},\n" +
            "\"url\":\"src3\"\n" +
            "}\n" +
            "]\n" +
            "}\n",
            out.toString());
  }


  private static class RunResult {
    final String generatedSource;
    final String sourceMapFileContent;

    RunResult(String source, String sourceMap) {
      this.generatedSource = source;
      this.sourceMapFileContent = sourceMap;
    }
  }

  private static class Token {
    String tokenName;
    FilePosition position;
  }

  /**
   * Finds the all the __XX__ tokens in the given Javascript
   * string.
   */
  private Map<String, Token> findTokens(String js) {
    Map<String, Token> tokens = Maps.newLinkedHashMap();

    int currentLine = 0;
    int positionOffset = 0;

    for (int i = 0; i < js.length(); ++i) {
      char current = js.charAt(i);

      if (current == '\n') {
        positionOffset = i + 1;
        currentLine++;
        continue;
      }

      if (current == '_' && (i < js.length() - 5)) {
        // Check for the _ token.
        if (js.charAt(i + 1) != '_') {
          continue;
        }

        // Loop until we have another _ token.
        String tokenName = "";

        int j = i + 2;
        for (; j < js.length(); ++j) {
          if (js.charAt(j) == '_') {
            break;
          }

          tokenName += js.charAt(j);
        }

        if (tokenName.length() > 0) {
          Token token = new Token();
          token.tokenName = tokenName;
          int currentPosition = i - positionOffset;
          token.position = new FilePosition(currentLine, currentPosition);

          // Only use the first instance of a token (parameters can be repeated in trampolines).
          if (!tokens.containsKey(tokenName)) {
            tokens.put(tokenName, token);
          }
        }

        i = j;
      }
    }

    return tokens;
  }

  private void compileAndCheck(String dartSource, String part)  throws Exception {
    compileAndCheck(dartSource, "", ResultType.DART);
    compileAndCheck(dartSource, part, ResultType.JS);
    // TODO(johnlenz): Use the application map instead of the per file map
    // compileAndCheck(dartSource, null, ResultType.CLOSURE_JS);
  }

  private void compileAndCheck(String dartSource, String part, ResultType type) throws Exception {
    RunResult result = getCompileResult("testcode", dartSource, part, type);

    // Find all instances of the __XXX__ pattern in the original
    // source code.
    Map<String, Token> originalTokens = findTokens(dartSource);

    // Find all instances of the __XXX__ pattern in the generated
    // source code.
    Map<String, Token> resultTokens = findTokens(result.generatedSource);

    // Ensure that the generated instances match via the source map
    // to the original source code.

    // Ensure the token counts match.
    assertEquals(originalTokens.size(), resultTokens.size());

    SourceMapping sourcemap;
    try {
      sourcemap = SourceMapConsumerFactory.parse(result.sourceMapFileContent);
    } catch (SourceMapParseException e) {
      throw new RuntimeException("unexpected exception", e);
    }

    // Map the tokens from the generated source back to the
    // input source and ensure that the map is correct.
    for (Token token : resultTokens.values()) {
      OriginalMapping mapping = sourcemap.getMappingForLine(
          token.position.getLine() + 1,
          token.position.getColumn() + 1);

      assertNotNull(mapping);

      // Find the associated token in the input source.
      Token inputToken = originalTokens.get(token.tokenName);
      assertNotNull(inputToken);

      // Ensure that the map correctly points to the token (we add 1
      // to normalize versus the Rhino line number indexing scheme).
      assertEquals(mapping.getLineNumber(),
                   inputToken.position.getLine() + 1);

      // Ensure that if the token name does not being with an 'STR' (meaning a
      // string) it has an original name.
      String originalName = mapping.getIdentifier();
      if (!inputToken.tokenName.startsWith("STR")) {
        assertTrue(!originalName.isEmpty());
      }

      // Ensure that if the mapping has a name, it matches the token.
      if (!originalName.isEmpty()) {
        assertEquals("__" + inputToken.tokenName + "__", originalName);
      }
    }
  }

  @Override
  protected CompilerConfiguration getCompilerConfiguration(Backend backend) {
    return new DefaultCompilerConfiguration(
        backend, new com.google.dart.compiler.CommandLineOptions.CompilerOptions(){
          @Override
          public boolean generateSourceMaps() { return true; }
        });
  }

  protected RunResult getResultForCompile(String fileName, String sourceCode, String part,
      Backend backend, String outExt, String mapExt) throws Exception {
    DartArtifactProvider provider = new MockArtifactProvider();
    DartSource dart = compileSingleUnit(
        fileName, sourceCode, provider, backend);

    StringBuilder src = new StringBuilder();
    StringBuilder map = new StringBuilder();
    CharStreams.copy(provider.getArtifactReader(dart, part, outExt), src);
    CharStreams.copy(provider.getArtifactReader(dart, part, mapExt), map);

    return new RunResult(src.toString(), map.toString());
  }

  private RunResult getCompileResult(
      String filename, String sourceCode, String part, ResultType type)
      throws Exception {
    switch (type) {
      case DART:
        return getResultForCompile(filename, sourceCode, part, new DartBackend(),
            DartBackend.EXTENSION_DART, DartBackend.EXTENSION_DART_SRC_MAP);
      case JS:
        return getResultForCompile(filename, sourceCode, part, new JavascriptBackend(),
            JavascriptBackend.EXTENSION_JS, JavascriptBackend.EXTENSION_JS_SRC_MAP);
      case CLOSURE_JS:
        return getResultForCompile(filename, sourceCode, part, new ClosureJsBackend(),
            ClosureJsBackend.EXTENSION_JS, ClosureJsBackend.EXTENSION_JS_SRC_MAP);
    }
    throw new IllegalStateException();
  }
}
