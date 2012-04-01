// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.corelib;

import com.google.common.io.CharStreams;
import com.google.common.io.LineReader;

import junit.extensions.TestSetup;
import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

/**
 * JUnit wrapper around test.py. This wrapper allows you to run most test.py tests from inside your
 * favorite IDE, to ease debugging.
 * <p>
 * If you followed the instructions in compiler/eclipse.workspace/README.txt, this test should just
 * work inside Eclipse.
 * <p>
 * If you just want to run a single test, launch this class as a JUnit test and stop it once it has
 * listed all the tests. Then right click on the desired test and select Run or Debug.
 */
public class SharedTests extends TestSetup {
  private final static String TEST_PY =
      System.getProperty("com.google.dart.corelib.SharedTests.test_py", "../tools/test.py");

  private static final String[] listTests = {
      TEST_PY,
      "--compiler=dartc",
      "--runtime=none",
      "--mode=release",
      "--progress=silent",
      "--list"};

  public SharedTests(Test test) {
    super(test);
  }

  public static TestSuite suite() {
    return new SuiteBuilder().buildSuite();
  }

  protected static class SuiteBuilder {
    protected TestSuite buildSuite() {
      TestSuite suite = new TestSuite("Shared Dart tests");
      File file = new File(listTests[0]);
      if (!file.canExecute()) {
        return configurationProblem(suite, file.getPath() + " is not executable");
      }
      ProcessBuilder builder = new ProcessBuilder(listTests);
      try {
        Process process = builder.start();
        InputStream inputStream = process.getInputStream();
        StringBuilder sb = new StringBuilder();
        try {
          InputStreamReader inputStreamReader = new InputStreamReader(inputStream);
          LineReader lineReader = new LineReader(inputStreamReader);
          String line;
          while ((line = lineReader.readLine()) != null) {
            if (!line.startsWith("dartc/")) {
              suite.addTest(SharedTestCase.getInstance(line, false));
            } else if (line.startsWith("dartc/client/")) {
              suite.addTest(SharedTestCase.getInstance(line, true));
            }
          }
        } finally {
          inputStream.close();
          process.getOutputStream().close();
          InputStreamReader inputStreamReader = new InputStreamReader(process.getErrorStream());
          CharStreams.copy(inputStreamReader, sb);
          process.getErrorStream().close();
        }
        process.waitFor();
        if (process.exitValue() != 0) {
          sb.insert(0, file.getPath());
          sb.insert(0, " returned non-zero exit code.\n");
          return configurationProblem(suite, sb.toString());
        }
      } catch (IOException e) {
        throw new AssertionError(e);
      } catch (InterruptedException e) {
        throw new AssertionError(e);
      }
      return suite;
    }

    /**
     * Errors reported during suite construction are hard to read. This method creates a test that
     * will always fail with an error message that shows up in the Eclipse JUnit UI.
     */
    protected TestSuite configurationProblem(TestSuite suite, final String message) {
      suite.addTest(new TestCase("Configuration problem") {
        @Override
        public void runBare() throws Throwable {
          fail(message);
        }
      });
      return suite;
    }
  }
}
