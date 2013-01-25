// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;


import com.google.dart.compiler.DartCompiler.Result;

import java.io.BufferedReader;
import java.io.InputStreamReader;

/**
 * Provides a framework to read command line options from stdin and feed them to
 * the {@link DartCompiler}.
 *
 */
public class UnitTestBatchRunner {

  public interface Invocation {
    public Result invoke (String[] args) throws Throwable;
  }

  /**
   * Run the tool in 'batch' mode, receiving command lines through stdin and returning
   * pass/fail status through stdout.  This feature is intended for use in unit testing.
   *
   * @param batchArgs command line arguments forwarded from main().
   */
  public static Result runAsBatch(String[] batchArgs, Invocation toolInvocation) throws Throwable {
    System.out.println(">>> BATCH START");

    // Read command lines in from stdin and create a new compiler for each one.
    BufferedReader cmdlineReader = new BufferedReader(new InputStreamReader(
        System.in));
    long startTime = System.currentTimeMillis();
    int testsFailed = 0;
    int totalTests = 0;
    Result batchResult = new Result(DartCompiler.RESULT_OK, null);
    try {
      String line;
      for (; (line = cmdlineReader.readLine()) != null; totalTests++) {
        long testStart = System.currentTimeMillis();
        // TODO(zundel): These are shell script cmdlines: be smarter about quoted strings.
        String[] args = line.trim().split("\\s+");
        Result result = toolInvocation.invoke(args);
        boolean resultPass = result.code < DartCompiler.RESULT_ERRORS;
        if (resultPass) {
          testsFailed++;
        }
        batchResult = batchResult.merge(result);
        // Write stderr end token and flush.
        System.err.println(">>> EOF STDERR");
        System.err.flush();
        System.out.println(">>> TEST " + (resultPass ? "PASS" : "FAIL") + " "
            + (System.currentTimeMillis() - testStart) + "ms");
        System.out.flush();
      }
    } catch (Throwable e) {
      System.err.println(">>> EOF STDERR");
      System.err.flush();
      System.out.println(">>> TEST CRASH");
      System.out.flush();
      throw e;
    }
    long elapsed = System.currentTimeMillis() - startTime;
    System.out.println(">>> BATCH END (" + (totalTests - testsFailed) + "/"
        + totalTests + ") " + elapsed + "ms");
    System.out.flush();
    return batchResult;
  }
}
