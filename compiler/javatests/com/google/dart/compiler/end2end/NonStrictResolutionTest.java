// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.end2end;

import com.google.dart.compiler.CommandLineOptions;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.CommandLineOptions.DartRunnerOptions;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartCompilerListenerTest;
import com.google.dart.compiler.DartLibrarySourceTest;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.runner.DartRunner;
import com.google.dart.runner.RunnerError;

import org.mozilla.javascript.RhinoException;

import java.io.FileNotFoundException;
import java.io.OutputStream;
import java.io.PrintStream;

/**
 * Tests cover experimental flag --warn_no_such_type
 */
public class NonStrictResolutionTest extends End2EndTestCase {

  private final String[] compilerOptions = { "--warn_no_such_type" };

  public void testNonStrictResolution() throws Exception {
    runExpectError("NonStrictResolutionTest.dart",
                   "",
                   compilerOptions,
                   "no such type \"type1\"", 12, 10,
                   "no such type \"type2\"", 16, 3,
                   "no such type \"type4\"", 18, 18,
                   "no such type \"type3\"", 18, 3,
                   "no such type \"type5\"", 22, 3,
                   "no such type \"type7\"", 26, 13,
                   "no such type \"type6\"", 26, 3,
                   "no such type \"type8\"", 27, 5,
                   "no such type \"type9\"", 28, 5);
  }

  public void testNoMethod() throws Exception {
    runExpectError("NonStrictResolutionNegativeTest1.dart",
                   "TypeError//has no method 'foo$named'",
                   compilerOptions,
                   "A has no method named \"foo\"", 15, 17);
  }

  public void testNewNonExistentType() throws Exception {
    // cannot enable until we resolve how to prevent JsNameProvider.getName() assert.
    // runExpectError("NonStrictResolutionNegativeTest2.dart",
    // "ReferenceError//$_Dynamic_$Dart is not defined",
    // compilerOptions);
  }

  /**
   * @param source - the source file name.
   * @param expectRuntimeErrors - String with expected errors separated by '//'
   * @param args - dart compiler arguments.
   * @throws FileNotFoundException
   */
  private void runExpectError(String source, String expectRuntimeErrors, String[] args,
                              Object... expectedCompilerErrors) throws FileNotFoundException {
    DartLibrarySourceTest app = new DartLibrarySourceTest(getClass(), source);
    DartCompilerListener listener = new DartCompilerListenerTest(source, expectedCompilerErrors);
    CompilerOptions options = processCommandLineOptions(args);
    DefaultCompilerConfiguration config = new DefaultCompilerConfiguration(options);
    DartRunnerOptions verboseOptions = new CommandLineOptions.DartRunnerOptions();
    verboseOptions.setVerbose(true);
    StringStream outStream = new StringStream(System.out);
    StringStream errStream = new StringStream(System.err);
    try {
      DartRunner.compileAndRunApp(app, verboseOptions, config, listener, args,
                                  outStream, errStream);
    } catch (RhinoException e) {
      super.fail(e.getLocalizedMessage());
    } catch (RunnerError e) {
      String outputStream = outStream.getSerializedStream();
      assertNotNull(outputStream);
      for (String expectedError : expectRuntimeErrors.split("//")) {
        assertNotNull(expectedError);
        if (!outputStream.contains(expectedError)) {
          System.err.println("Missing expected error: " + expectedError
              + " in \"" + outputStream + "\"");
          System.err.println(e);
        }
        assertTrue(outputStream.contains(expectedError));
      }
    }
  }

  public class StringStream extends PrintStream {
    StringBuffer sb = new StringBuffer(2048);

    public StringStream(OutputStream out) {
      super(out);
    }

    @Override
    public void write(byte buffer[], int off, int len) {
      sb.append(new String(buffer));
    }

    public String getSerializedStream() {
      return sb.toString();
    }
  }
}
