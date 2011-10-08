// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.end2end;

import com.google.dart.compiler.CommandLineOptions;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.CommandLineOptions.DartRunnerOptions;
import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartCompilerListenerTest;
import com.google.dart.compiler.DartLibrarySourceTest;
import com.google.dart.compiler.DartSourceTest;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.MockLibrarySource;
import com.google.dart.compiler.backend.js.ClosureJsBackend;
import com.google.dart.compiler.backend.js.JavascriptBackend;
import com.google.dart.runner.DartRunner;
import com.google.dart.runner.RunnerError;

import org.kohsuke.args4j.CmdLineException;
import org.mozilla.javascript.RhinoException;

import java.util.List;

/**
 * Abstract base for end-to-end tests. Tests are entirely Dart code that are compiled and run
 * within Rhino or V8.
 */
public abstract class End2EndTestCase extends CompilerTestCase {

  enum OptimizationLevel {
    RAW,
    APP
  }

  /**
   * Creates an ApplicationSource that should be compiled and executed.
   *
   * @param srcs paths to the input.
   * @param mainClass the name of the main class to execute.
   * @return an ApplicationSource suitable to be compiled and executed.
   */
  protected LibrarySource createApplication(List<String> srcs) {
    MockLibrarySource app = new MockLibrarySource();
    for (String src : srcs) {
      DartSourceTest dartSource = new DartSourceTest(getClass(), src, app);
      app.addSource(dartSource);
    }
    return app;
  }

  /**
   * Creates a compiler configuration appropriate for the optimization level.
   */
  CompilerConfiguration getCompilerConfiguration(OptimizationLevel opLevel) {
    switch (opLevel) {
      case RAW:
        return new DefaultCompilerConfiguration(new JavascriptBackend());
      case APP:
        return new DefaultCompilerConfiguration(new ClosureJsBackend());
    }
    throw new IllegalStateException("unexpected opLevel");
  }

  /**
   * Runs an end-to-end Dart test for the given compilation unit.
   */
  protected void runTest(LibrarySource app, OptimizationLevel opLevel,
                         DartCompilerListener listener) {
    runTest(app, opLevel, listener, new String[0]);
  }

  protected void runTest(LibrarySource app, OptimizationLevel opLevel,
                         DartCompilerListener listener, String[] args) {
    final CompilerConfiguration config = getCompilerConfiguration(opLevel);
    runTest(app, opLevel, listener, config, args);
  }

  /**
   * Runs an end-to-end Dart test for the given compilation unit.
   */
  protected void runTest(LibrarySource app, OptimizationLevel opLevel,
                         DartCompilerListener listener,
                         CompilerConfiguration config, String[] args) {
    DartRunnerOptions verboseOptions = new CommandLineOptions.DartRunnerOptions();
    verboseOptions.setVerbose(true);
    try {
      DartRunner.compileAndRunApp(app,
                                  verboseOptions,
                                  config,
                                  listener,
                                  args,
                                  System.out,
                                  System.err);
    } catch (RhinoException e) {
      // TODO(jgw): This is a hack to dump the translated source when something goes wrong. It can
      // be removed as soon as we have a source map we can use to provide source-level errors.

      // TODO(floitsch): clean up the exception handling. Who prints what, and when?

      StringBuffer msg = new StringBuffer();
      msg.append("optimization level: " + opLevel.toString() + "\n");
      msg.append(e.sourceName());
      msg.append(" (" + e.lineNumber() + ":" + e.columnNumber() + ")");
      msg.append(" : " + e.details());
      fail(msg.toString());
    } catch (RunnerError e) {
      fail(e.getLocalizedMessage());
    }
  }

  /**
   * Runs an end-to-end Dart test for the given compilation unit.
   */
  protected void runTest(LibrarySource app, OptimizationLevel opLevel) {
    DartCompilerListener listener = new DartCompilerListenerTest(null);
    runTest(app, opLevel, listener);
  }

  /**
   * Runs an end-to-end Dart test for the given compilation unit.
   */
  protected void runTest(String appSrc, String[] args) throws Exception {
    DartCompilerListener listener = new DartCompilerListenerTest(null);
    CompilerOptions options = processCommandLineOptions(args);
    DefaultCompilerConfiguration config = new DefaultCompilerConfiguration(options);
    runTest(new DartLibrarySourceTest(getClass(), appSrc),
            OptimizationLevel.RAW,
            listener,
            config,
            args);
  }

  /**
   * Runs an end-to-end Dart test for the given compilation unit.
   *
   * @param srcs path to the Dart source files containing the test
   * @param opLevel The type of optimization to perform on the test code.
   */
  protected void runTest(
      List<String> srcs, OptimizationLevel opLevel)
      throws SecurityException {
    runTest(createApplication(srcs), opLevel);
  }

  protected void runTest(String appSrc) throws Exception {
    runTest(new DartLibrarySourceTest(getClass(), appSrc), OptimizationLevel.RAW);
  }

  protected static CompilerOptions processCommandLineOptions(String[] args) {
    CompilerOptions compilerOptions = null;
    try {
      compilerOptions = new CompilerOptions();
      CommandLineOptions.parse(args, compilerOptions);
      if (args.length == 0 || compilerOptions.showHelp()) {
        fail("invalid arguments.");
      }
    } catch (CmdLineException e) {
      fail(e.getLocalizedMessage());
    }
    assert compilerOptions != null;
    return compilerOptions;
  }
}
