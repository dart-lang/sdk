// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.corelib;

import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.DartArtifactProvider;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.DefaultDartArtifactProvider;
import com.google.dart.compiler.DefaultLibrarySource;
import com.google.dart.compiler.ErrorSeverity;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.SubSystem;
import com.google.dart.compiler.UrlLibrarySource;
import com.google.dart.runner.DartRunner;
import com.google.dart.runner.RunnerError;
import com.google.dart.runner.V8Launcher;

import junit.framework.AssertionFailedError;
import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;

import java.io.ByteArrayOutputStream;
import java.io.CharArrayReader;
import java.io.CharArrayWriter;
import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.regex.Pattern;

/**
 * Wrapper around test that are shared between compiler and runtime (test.py).
 * <p>
 * Sometimes, when fixing a known issue, a test that was previously crashing or failing may start
 * passing. This will show up as a test failure because the status file has wrong information.
 * Please update the status file.
 */
public class SharedTestCase extends TestCase {
  private static final Pattern SEPARATOR = Pattern.compile("\\t");

  private final Set<String> outcomes;
  private final boolean isNegative;
  private final String[] arguments;
  private final boolean regularCompile;
  private final AtomicInteger compilationErrorCount = new AtomicInteger(0);
  private final AtomicInteger typeErrorCount = new AtomicInteger(0);
  private final AtomicInteger warningCount = new AtomicInteger(0);

  SharedTestCase(String name, Set<String> outcomes, boolean isNegative, boolean regularCompile,
                 String[] arguments) {
    super(name);
    this.outcomes = outcomes;
    this.isNegative = isNegative;
    this.regularCompile = regularCompile;
    this.arguments = arguments;
  }

  /**
   * This constructor is provided for compatibility with Eclipse (for running
   * a single test case).
   */
  public SharedTestCase(String name) {
    super(name = scrubName(name));
    TestSuite suite = SharedTests.suite();
    Enumeration<Test> tests = suite.tests();
    SharedTestCase test = null;
    while (tests.hasMoreElements()) {
      SharedTestCase current = (SharedTestCase) tests.nextElement();
      if (current.getScrubbedName().equals(name)) {
        test = current;
        break;
      }
    }
    if (test == null) {
      throw new IllegalArgumentException("Test '" +name + "' was not found.");
    }
    this.outcomes = test.outcomes;
    this.isNegative = test.isNegative;
    this.regularCompile = test.regularCompile;
    this.arguments = test.arguments;
  }

  private static String scrubName(String name) {
    int i = name.indexOf('[');
    if (i == -1) {
      return name;
    }
    return name.substring(0, i - 1);
  }

  @Override
  public String getName() {
    List<String> remarks = new ArrayList<String>();
    if (isNegative) {
      remarks.add("negative");
    }
    for (String outcome : outcomes) {
      if (!outcome.equals("pass")) {
        remarks.add(outcome);
      }
    }
    if (remarks.isEmpty()) {
      return super.getName();
    } else {
      return super.getName() + " " + remarks;
    }
  }

  String getScrubbedName() {
    return super.getName();
  }

  @Override
  public void runBare() {
    assertTrue(V8Launcher.isConfigured());
    ByteArrayOutputStream byteOutput = new ByteArrayOutputStream();
    PrintStream outputStream = new PrintStream(byteOutput);
    try {
      if (regularCompile) {
        invokeCompiler();
      } else {
        DartRunner.throwingMain(arguments, outputStream, outputStream);
      }
    } catch (RunnerError e) {
      outputStream.close();
      analyzeError(e, byteOutput.toString());
      return;
    } catch (Throwable t) {
      outputStream.close();
      analyzeCrash(t);
      return;
    }
    outputStream.close();
    analyzeNormalCompletion();
  }

  private void invokeCompiler() throws CmdLineException, IOException, RunnerError {
    CmdLineParser cmdLineParser = null;
    CompilerOptions compilerOptions = new CompilerOptions();
    cmdLineParser = new CmdLineParser(compilerOptions);
    cmdLineParser.parseArgument(arguments);
    CompilerConfiguration config = new DefaultCompilerConfiguration(compilerOptions);
    DartArtifactProvider provider = getArtifactProvider(config.getOutputDirectory());
    DartCompilerListener listener = getListener();
    List<String> sourceFiles = compilerOptions.getSourceFiles();
    assertEquals("incorrect number of source files " + sourceFiles, 1, sourceFiles.size());
    File sourceFile = new File(sourceFiles.get(0));
    LibrarySource lib;
    if (sourceFile.getName().endsWith(".dart")) {
      lib = new DefaultLibrarySource(sourceFile, null);
    } else {
      lib = new UrlLibrarySource(sourceFile);
    }
    DartCompiler.compileLib(lib, config, provider, listener);
    if (compilationErrorCount.get() != 0 || typeErrorCount.get() != 0 || warningCount.get() != 0) {
      throw new RunnerError(sourceFile.getPath());
    }
  }

  private DartArtifactProvider getArtifactProvider(File outputDirectory) {
    final DartArtifactProvider provider = new DefaultDartArtifactProvider(outputDirectory);
    return new DartArtifactProvider() {
      ConcurrentHashMap<URI, CharArrayWriter> artifacts =
          new ConcurrentHashMap<URI, CharArrayWriter>();

      @Override
      public boolean isOutOfDate(Source source, Source base, String extension) {
        return true;
      }

      @Override
      public Writer getArtifactWriter(Source source, String part, String extension) {
        URI uri = getArtifactUri(source, part, extension);
        CharArrayWriter writer = new CharArrayWriter();
        CharArrayWriter existing = artifacts.putIfAbsent(uri, writer);
        return (existing == null) ? writer : existing;
      }


      @Override
      public URI getArtifactUri(Source source, String part, String extension) {
        return provider.getArtifactUri(source, part, extension);
      }

      @Override
      public Reader getArtifactReader(Source source, String part, String extension)
          throws IOException {
        URI uri = getArtifactUri(source, part, extension);
        CharArrayWriter writer = artifacts.get(uri);
        if (writer != null) {
          return new CharArrayReader(writer.toCharArray());
        }
        return provider.getArtifactReader(source, part, extension);
      }
    };
  }

  private DartCompilerListener getListener() {
    DartCompilerListener listener = new DartCompilerListener() {
      @Override
      public void onError(DartCompilationError event) {
        if (event.getErrorCode().getSubSystem() == SubSystem.STATIC_TYPE) {
          typeErrorCount.incrementAndGet();
        } else if (event.getErrorCode().getErrorSeverity() == ErrorSeverity.ERROR) {
          compilationErrorCount.incrementAndGet();
        } else if (event.getErrorCode().getErrorSeverity() == ErrorSeverity.WARNING) {
          warningCount.incrementAndGet();
        }
        maybeThrow(event);
      }

      private void maybeThrow(DartCompilationError event) {
        if (isNegative) {
          return;
        }
        if (outcomes.contains("pass")) {
          // It is easier to debug a failing regular test if we throw an exception.
          throw new AssertionError(event);
        }
      }

      @Override
      public void unitCompiled(DartUnit unit) {
      }
    };
    return listener;
  }

  private void analyzeNormalCompletion() {
    if (isNegative) {
      if (!outcomes.contains("fail")) {
        fail("Negative test didn't cause an error");
      }
    } else {
      if (!outcomes.contains("pass")) {
        fail("Test passed unexpectly, please update status file");
      }
    }
  }

  private void analyzeCrash(Throwable t) {
    if (outcomes.contains("crash")) {
      return;
    }
    String message = outcomes.contains("fail") ? "Failing test crashed" : "Test crashed unexpectly";
    AssertionFailedError error = new AssertionFailedError(message);
    error.initCause(t);
    throw error;
  }

  private void analyzeError(RunnerError e, String log) {
    if (isNegative) {
      if (!outcomes.contains("pass")) {
        fail("Negative test is passing, please update status file");
      }
    } else {
      if (!outcomes.contains("fail")) {
        fail(log + e.getLocalizedMessage());
      }
    }
  }

  static Test getInstance(String line, boolean regularCompile) {
    String[] fields = SEPARATOR.split(line);
    assertTrue(line, fields.length > 3);
    String name = fields[0];
    Set<String> outcomes = new HashSet<String>(Arrays.<String>asList(fields[1].split(",")));
    boolean isNegative = fields[2].equals("True");
    String[] arguments = new String[fields.length - 3];
    System.arraycopy(fields, 3, arguments, 0, arguments.length);
    return new SharedTestCase(name, outcomes, isNegative, regularCompile, arguments);
  }
}
