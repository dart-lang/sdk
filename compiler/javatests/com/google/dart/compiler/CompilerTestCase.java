// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.common.collect.Lists;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.parser.DartParser;
import com.google.dart.compiler.parser.DartScannerParserContext;
import com.google.dart.compiler.parser.ParserContext;

import junit.framework.TestCase;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.URI;
import java.net.URL;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Base class for compiler tests, with helpful utility methods.
 */
public abstract class CompilerTestCase extends TestCase {

  private static final String UTF8 = "UTF-8";

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
  protected static class AnalyzeLibraryResult extends DartCompilerListener {
    private final List<DartCompilationError> compilationErrors;
    private final List<DartCompilationError> compilationWarnings;
    private final List<DartCompilationError> typeErrors;
    private LibraryUnit result;

    public AnalyzeLibraryResult() {
      compilationErrors = Lists.newArrayList();
      compilationWarnings = Lists.newArrayList();
      typeErrors = Lists.newArrayList();
    }

    @Override
    public void compilationError(DartCompilationError event) {
      compilationErrors.add(event);
    }

    @Override
    public void compilationWarning(DartCompilationError event) {
      compilationWarnings.add(event);
    }

    @Override
    public void typeError(DartCompilationError event) {
      typeErrors.add(event);
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

    @Override
    public void unitCompiled(DartUnit unit) {
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
    MockLibrarySource lib = new MockLibrarySource();
    DartSourceTest src = new DartSourceTest(name, code, lib);
    lib.addSource(src);
    final CompilerConfiguration config = new DefaultCompilerConfiguration(new CompilerOptions()) {
      @Override
      public boolean checkOnly() {
        return true;
      }

      @Override
      public boolean incremental() {
        return true;
      }

      @Override
      public boolean resolveDespiteParseErrors() {
        return true;
      }
    };
    AnalyzeLibraryResult result = new AnalyzeLibraryResult();
    Map<URI, DartUnit> testUnits = new HashMap<URI, DartUnit>();
    ParserContext context = makeParserContext(src, code, result);
    DartUnit unit = makeParser(context).parseUnit(src);
    testUnits.put(src.getUri(), unit);
    DartArtifactProvider provider = new MockArtifactProvider();
    result.setLibraryUnitResult(DartCompiler.analyzeLibrary(lib, testUnits, config, provider,
        result));
    return result;
  }

  /**
   * Compiles a single unit with a synthesized application, using the specified backend.
   */
  protected DartSource compileSingleUnit(String name, String code,
       DartArtifactProvider provider, Backend backend) throws IOException {
     MockLibrarySource lib = new MockLibrarySource();
     DartSourceTest src = new DartSourceTest(name, code, lib);
     lib.addSource(src);
     CompilerConfiguration config = getCompilerConfiguration(backend);
     DartCompilerListener listener = new DartCompilerListenerTest(src.getName());
     DartCompiler.compileLib(lib, config, provider, listener);
     return src;
  }

  /**
   * Allow tests to override the configuration used.
   */
  protected CompilerConfiguration getCompilerConfiguration(Backend backend) {
    return new DefaultCompilerConfiguration(backend);
  }

  /**
   * Parse a single compilation unit for the given input file.
   */
  protected final DartUnit parseUnit(final String path) {
    // final because we delegate to the method below, and only that one should
    // be overriden to do extra checks.
    URL url = inputUrlFor(getClass(), path);
    String source = readUrl(url);
    return parseUnit(path, source);
  }

  /**
   * Parse a single compilation unit for the name and source.
   */
  protected DartUnit parseUnit(final String srcName, final String sourceCode) {
    // TODO(jgw): We'll need to fill in the library parameter when testing multiple units.
    DartSourceTest src = new DartSourceTest(srcName, sourceCode, null);
    ParserContext context = makeParserContext(src, sourceCode,
        new DartCompilerListenerTest(srcName));
    return makeParser(context).parseUnit(src);
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
}
