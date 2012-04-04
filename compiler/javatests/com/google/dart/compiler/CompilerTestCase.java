// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import static com.google.dart.compiler.common.ErrorExpectation.assertErrors;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartInvocation;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.common.ErrorExpectation;
import com.google.dart.compiler.parser.DartParser;
import com.google.dart.compiler.parser.DartParserRunner;
import com.google.dart.compiler.parser.DartScannerParserContext;
import com.google.dart.compiler.parser.ParserContext;

import junit.framework.TestCase;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.List;
import java.util.Map;

/**
 * Base class for compiler tests, with helpful utility methods.
 */
public abstract class CompilerTestCase extends TestCase {

  private static final String UTF8 = "UTF-8";

  /**
   * Instance of {@link CompilerConfiguration} for incremental check-only compilation.
   */
  protected static final CompilerConfiguration CHECK_ONLY_CONFIGURATION =
      new DefaultCompilerConfiguration(new CompilerOptions()) {
        @Override
        public boolean incremental() {
          return true;
        }

        @Override
        public boolean resolveDespiteParseErrors() {
          return true;
        }
      };

  /**
   * Read a resource from the given URL.
   */
  protected static String readUrl(URL url) {
    try {
      StringBuffer out = new StringBuffer();
      Reader in = new InputStreamReader(url.openStream(), UTF8);
      char[] buf = new char[10240];
      int n;
      while ((n = in.read(buf)) > 0) {
        out.append(buf, 0, n);
      }
      in.close();
      return out.toString();
    } catch (IOException e) {
      // Just punt a RuntimeException out the top if something goes wrong.
      // It will simply cause the test to fail, which is exactly what we want.
      throw new RuntimeException(e);
    }
  }

  /**
   * Return a URL that can be used to read an input file for the given test name
   * and path.
   */
  protected static URL inputUrlFor(Class<?> testClass, String testName) {
    String fullPath = testClass.getPackage().getName().replace('.', '/') + "/"
        + testName;
    URL url = chooseClassLoader().getResource(fullPath);
    if (url == null) {
      fail("Could not find input file: " + fullPath);
    }
    return url;
  }

  private static ClassLoader chooseClassLoader() {
    if (Thread.currentThread().getContextClassLoader() != null) {
      return Thread.currentThread().getContextClassLoader();
    }
    return CompilerTestCase.class.getClassLoader();
  }

  /**
   * Collects the results of running analyzeLibrary.
   */
  protected static class AnalyzeLibraryResult extends DartCompilerListener.Empty {
    private final List<DartCompilationError> errors = Lists.newArrayList();
    private final List<DartCompilationError> compilationErrors = Lists.newArrayList();
    private final List<DartCompilationError> compilationWarnings = Lists.newArrayList();
    private final List<DartCompilationError> typeErrors = Lists.newArrayList();
    private LibraryUnit result;

    @Override
    public void onError(DartCompilationError event) {
      errors.add(event);
      if (event.getErrorCode().getSubSystem() == SubSystem.STATIC_TYPE) {
        typeErrors.add(event);
      } else if (event.getErrorCode().getErrorSeverity() == ErrorSeverity.ERROR) {
        compilationErrors.add(event);
      }   else if (event.getErrorCode().getErrorSeverity() == ErrorSeverity.WARNING) {
        compilationWarnings.add(event);
      }
    }

    public List<DartCompilationError> getErrors() {
      return errors;
    }

    public List<DartCompilationError> getTypeErrors() {
      return typeErrors;
    }

    public List<DartCompilationError> getCompilationErrors() {
      return compilationErrors;
    }

    public List<DartCompilationError> getCompilationWarnings() {
      return compilationWarnings;
    }

    /**
     * @param lib
     */
    public void setLibraryUnitResult(LibraryUnit lib) {
      result = lib;
    }

    /**
     * @return the analyzed library
     */
    public LibraryUnit getLibraryUnitResult() {
      return result;
    }
  }

  /**
   * Build a multi-line string from a list of strings.
   *
   * @param lines
   * @return a single string containing {@code lines}, each terminated by \n
   */
  protected static String makeCode(String... lines) {
    StringBuilder buf = new StringBuilder();
    for (String line : lines) {
      buf.append(line).append('\n');
    }
    return buf.toString();
  }

  /**
   * Simulate running {@code analyzeLibrary} the way the IDE will.
   * <p>
   * <b>Note:</b> if the IDE changes how it calls analyzeLibrary, this should
   * be changed to match.
   *
   * @param name the name to use for the source file
   * @param code the Dart code to parse/analyze
   * @return an {@link AnalyzeLibraryResult} containing the {@link LibraryUnit}
   *     and all the errors/warnings generated from the supplied code
   * @throws Exception
   */
  protected AnalyzeLibraryResult analyzeLibrary(String name, String code)
      throws Exception {
    AnalyzeLibraryResult result = new AnalyzeLibraryResult();
    // Prepare library.
    MockLibrarySource lib = new MockLibrarySource();
    // Prepare unit.
    Map<URI, DartUnit> testUnits =  Maps.newHashMap();
    {
      DartSourceTest src = new DartSourceTest(name, code, lib);
      ParserContext context = makeParserContext(src, code, result);
      DartUnit unit = makeParser(context).parseUnit(src);
      // Remember unit.
      lib.addSource(src);
      testUnits.put(src.getUri(), unit);
    }
    DartArtifactProvider provider = new MockArtifactProvider();
    result.setLibraryUnitResult(DartCompiler.analyzeLibrary(
        lib,
        testUnits,
        CHECK_ONLY_CONFIGURATION,
        provider,
        result));
    // TODO(zundel): One day, we want all AST nodes that are identifiers to point to
    // elements if they are resolved.  Uncommenting this line helps track missing elements
    // down.
    // ResolverAuditVisitor.exec(unit);
    return result;
  }

  /**
   * Compiles a single unit with a synthesized application.
   */
  protected DartSource compileSingleUnit(String name, String code,
       DartArtifactProvider provider) throws IOException {
     MockLibrarySource lib = new MockLibrarySource();
     DartSourceTest src = new DartSourceTest(name, code, lib);
     lib.addSource(src);
     CompilerConfiguration config = getCompilerConfiguration();
     DartCompilerListener listener = new DartCompilerListenerTest(src.getName());
     DartCompiler.compileLib(lib, config, provider, listener);
     return src;
  }

  /**
   * Allow tests to override the configuration used.
   */
  protected CompilerConfiguration getCompilerConfiguration() {
    return new DefaultCompilerConfiguration();
  }

  /**
   * Parse a single compilation unit for the given input file.
   */
  protected final DartUnit parseUnit(String path) {
    // final because we delegate to the method below, and only that one should
    // be overriden to do extra checks.
    URL url = inputUrlFor(getClass(), path);
    String source = readUrl(url);
    return parseUnit(path, source);
  }

  /**
   * Parse a single compilation unit for the name and source.
   */
  protected DartUnit parseUnit(String srcName, String sourceCode, Object... errors) {
    // TODO(jgw): We'll need to fill in the library parameter when testing multiple units.
    DartSourceTest src = new DartSourceTest(srcName, sourceCode, null);
    DartCompilerListenerTest listener = new DartCompilerListenerTest(srcName, errors);
    ParserContext context = makeParserContext(src, sourceCode, listener);
    DartUnit unit = makeParser(context).parseUnit(src);
    listener.checkAllErrorsReported();
    return unit;
  }
  
  /**
   * Parse a single compilation unit for the name and source. The parse expects some kind of error,
   * but isn't picky about the actual contents. This is useful for testing parser recovery where we
   * don't want to make the test too brittle.
   */
  protected DartUnit parseUnitUnspecifiedErrors(String srcName, String sourceCode) {
    DartSourceTest src = new DartSourceTest(srcName, sourceCode, null);
    final List<DartCompilationError> errorsEncountered = Lists.newArrayList();
    DartCompilerListener listener = new DartCompilerListener.Empty() {
      @Override
      public void onError(DartCompilationError event) {
        errorsEncountered.add(event);
      }
    };
    ParserContext context = makeParserContext(src, sourceCode, listener);
    DartUnit unit = makeParser(context).parseUnit(src);
    assertTrue("Expected some compilation errors, got none.", errorsEncountered.size() > 0);
    return unit;
    }
  
    protected DartUnit parseUnitAsSystemLibrary(final String srcName, String sourceCode,
                                              Object... errors) {
    DartSourceTest src = new DartSourceTest(srcName, sourceCode, null) {
      @Override
      public URI getUri() {
        return URI.create("dart:core/" + srcName);
      }
    };
    DartCompilerListenerTest listener = new DartCompilerListenerTest(srcName, errors);
    ParserContext context = makeParserContext(src, sourceCode, listener);
    DartUnit unit = makeParser(context).parseUnit(src);
    listener.checkAllErrorsReported();
    return unit;
  }


  /**
   * Parse a single compilation unit with given name and source, and check for a set of expected errors.
   *
   * @param errors a sequence of errors represented as triples of the form
   *        (String msg, int line, int column) or
   *        (ErrorCode code, int line, int column)
   */
  protected DartUnit parseSourceUnitErrors(String sourceCode,  Object... errors) {
    String srcName = "Test.dart";
    DartSourceTest src = new DartSourceTest(srcName, sourceCode, null);
    DartCompilerListenerTest listener = new DartCompilerListenerTest(srcName, errors);
    ParserContext context = makeParserContext(src, sourceCode, listener);
    DartUnit unit = makeParser(context).parseUnit(src);
    listener.checkAllErrorsReported();
    return unit;
  }

  /**
   * Parse a single compilation unit for the given input file, and check for a
   * set of expected errors.
   *
   * @param errors a sequence of errors represented as triples of the form
   *        (String msg, int line, int column) or
   *        (ErrorCode code, int line, int column)
   */
  protected DartUnit parseUnitErrors(final String path, final Object... errors) {
    URL url = inputUrlFor(getClass(), path);
    String sourceCode = readUrl(url);
    // TODO(jgw): We'll need to fill in the library parameter when testing multiple units.
    DartSourceTest src = new DartSourceTest(path, sourceCode, null);
    DartCompilerListenerTest listener = new DartCompilerListenerTest(path, errors);
    ParserContext context = makeParserContext(src, sourceCode, listener);
    DartUnit unit = makeParser(context).parseUnit(src);
    listener.checkAllErrorsReported();
    return unit;
  }

  /**
   * Override this method to provide an alternate {@link DartParser}.
   */
  protected DartParser makeParser(ParserContext context) {
    return new DartParser(context);
  }

  /**
   * Override this method to provide an alternate {@link ParserContext}.
   */
  protected ParserContext makeParserContext(Source src, String sourceCode,
      DartCompilerListener listener) {
    return new DartScannerParserContext(src, sourceCode, listener);
  }

  /**
   * @return the {@link DartParserRunner} with parsed source. It can be used to request
   *         {@link DartUnit} or compilation problems.
   */
  protected final DartParserRunner parseSource(String code) {
    return DartParserRunner.parse(getName(), code, Integer.MAX_VALUE, false);
  }

  /**
   * Parses given source and checks parsing problems.
   */
  protected final DartParserRunner parseExpectErrors(String code,
      ErrorExpectation... expectedErrors) {
    DartParserRunner parserRunner = parseSource(code);
    List<DartCompilationError> errors = parserRunner.getErrors();
    assertErrors(errors, expectedErrors);
    return parserRunner;
  }

  /**
   * Parses given source and checks parsing problems.
   */
  protected final void parseExpectWarnings(String code, ErrorExpectation... expectedWarnings) {
    DartParserRunner runner =  DartParserRunner.parse(getName(), code, Integer.MAX_VALUE, true);
    List<DartCompilationError> errors = runner.getErrors();
    assertErrors(errors, expectedWarnings);
  }
  /**
   * @return the {@link DartInvocation} with given source. This is inaccurate approach, but good
   *         enough for specific tests.
   */
  protected static DartNewExpression findNewExpression(DartNode rootNode, final String sampleSource) {
    final DartNewExpression result[] = new DartNewExpression[1];
    rootNode.accept(new ASTVisitor<Void>() {
      @Override
      public Void visitNewExpression(DartNewExpression node) {
        if (node.toSource().equals(sampleSource)) {
          result[0] = node;
        }
        return super.visitInvocation(node);
      }
    });
    return result[0];
  }

  protected static DartFunctionTypeAlias findTypedef(DartNode rootNode, final String name) {
    final DartFunctionTypeAlias result[] = new DartFunctionTypeAlias[1];
    rootNode.accept(new ASTVisitor<Void>() {
      @Override
      public Void visitFunctionTypeAlias(DartFunctionTypeAlias node) {
        if (node.getName().getName().equals(name)) {
          result[0] = node;
        }
        return null;
      }
    });
    return result[0];
  }
}
