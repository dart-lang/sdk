// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerListenerTest;
import com.google.dart.compiler.DartSourceTest;
import com.google.dart.compiler.ast.DartUnit;

public class TruncatedSourceParserTest extends AbstractParserTest {

  /**
   * Performs parsing in a separate thread such that the test can detect infinite loop.
   */
  private class ParserThread extends Thread {
    private final Object lock = new Object();
    private final String srcName;
    private int state = 0;
    private String srcCode;
    private DartUnit result;

    /**
     * Listener that ignores errors because this is a stress test
     */
    private DartCompilerListenerTest listener = new DartCompilerListenerTest("") {
      @Override
      public void checkAllErrorsReported() {
      }

      @Override
      public void onError(DartCompilationError event) {
      }
    };

    public ParserThread(String srcName) {
      super("Parsing " + srcName);
      this.srcName = srcName;
    }

    /**
     * Queue the specified source to be parsed on a separate thread. Wait up to 10 seconds for the
     * result
     * 
     * @return <code>true</code> if finished parsing
     */
    public boolean parse(String srcCode) {
      assert (srcCode != null);
      assert (state == 0);
      synchronized (lock) {
        this.srcCode = srcCode;
        result = null;
        state = 1;
        lock.notifyAll();
        try {
          lock.wait(10000);
        } catch (InterruptedException e) {
          // Fall through
        }
        return state == 0;
      }
    }

    /**
     * Parse source code in the background
     */
    @Override
    public void run() {
      while (true) {
        DartSourceTest src;
        ParserContext context;
        synchronized (lock) {
          while (state == 0) {
            try {
              lock.wait();
            } catch (InterruptedException e) {
              // Fall through
            }
          }
          if (state == 2) {
            return;
          }
          src = new DartSourceTest(srcName, srcCode, null);
          context = makeParserContext(src, srcCode, listener);
        }
        DartUnit unit = makeParser(context).parseUnit(src);
        synchronized (lock) {
          if (state == 2) {
            return;
          }
          state = 0;
          result = unit;
          lock.notifyAll();
        }
      }
    }

    /**
     * Signal the background thread to terminate
     */
    public void stopParsing() {
      synchronized (lock) {
        state = 2;
        lock.notify();
      }
    }
  }

  @Override
  public void testStringsErrors() {
    parseUnit("StringsErrorsNegativeTest.dart");
  }

  @Override
  public void testTiming() {
    // Skip
  }

  @Override
  protected DartUnit parseUnit(String srcName, String srcCode, Object... errors) {
    if (errors.length > 0) {
      throw new RuntimeException("Expected errors not implemented");
    }
    // System.out.print(srcName);
    ParserThread thread = new ParserThread(srcName);
    thread.start();
    int eol = 0;
    for (int index = 0; index < srcCode.length(); index++) {
      if (eol == index) {
        eol++;
        while (eol < srcCode.length()) {
          char ch = srcCode.charAt(eol);
          if (ch == '\r' || ch == '\n') {
            break;
          }
          eol++;
        }
      }
      String modifiedSrcCode = srcCode.substring(0, index);
      if (!thread.parse(modifiedSrcCode)) {
        // System.out.println();
        fail("Failed to finish parsing " + srcName + "\n" + modifiedSrcCode);
      }
      modifiedSrcCode += srcCode.substring(eol);
      if (!thread.parse(modifiedSrcCode)) {
        // System.out.println();
        fail("Failed to finish parsing " + srcName + "\n" + modifiedSrcCode);
      }
      // System.out.print('.');
    }
    thread.stopParsing();
    // System.out.println();
    return thread.result;
  }
}
