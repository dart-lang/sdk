// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSourceTest;
import com.google.dart.compiler.ast.DartUnit;

import junit.framework.TestCase;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

public class DartParserRunner extends DartCompilerListener implements Runnable {

  public static final int DEFAULT_TIMEOUT_IN_MILISECONDS = 10 * 1000;

  public static void main(String[] args) {
    for (String fileName : args) {
      String source = readSource(fileName);
      if (source == null) {
        System.err.println("Unable to read " + fileName);
        continue;
      }
      System.out.println("Parsing " + fileName);
      DartParserRunner parser = DartParserRunner.parse(fileName, source, Integer.MAX_VALUE, true);
      for (DartCompilationError error : parser.getErrors()) {
        System.err.println(error.toString());
      }
    }
  }

  /*
   * Parses @sourceCode ensuring explicit failure in case of non-termination.
   */
  public static DartParserRunner parse(String name, String sourceCode) {
   return DartParserRunner.parse(name, sourceCode, false);
  }

  /*
   * Parses @sourceCode ensuring explicit failure in case of non-termination.
   */
  public static DartParserRunner parse(String name, String sourceCode, int timeoutInMs,
       boolean wantWarnings) {
   return DartParserRunner.parse(name, sourceCode, false, timeoutInMs, wantWarnings);
  }

  /*
   * Parses @sourceCode ensuring explicit failure in case of non-termination.
   */
  public static DartParserRunner parse(String name, String sourceCode, boolean apiParsing) {
    return parse(name, sourceCode, apiParsing, 0, false);
  }

  /*
   * Parses @sourceCode ensuring explicit failure in case of non-termination.
   */
  public static DartParserRunner parse(String name, String sourceCode, boolean apiParsing,
        int timeoutInMs, boolean wantWarnings) {
    DartParserRunner parser  = null;
    try {
      parser = new DartParserRunner(name, sourceCode, apiParsing);
      if (timeoutInMs != 0) {
        parser.setTimeout(timeoutInMs);
      }
      parser.setWantWarnings(wantWarnings);
      parser.doWork();
      TestCase.assertFalse("Dart parser failed to terminate.", parser.isAlive());
      Throwable t = parser.workerException.get();
      if (t != null) {
        throw new AssertionError(t);
      }
    } catch(Exception e) {
      throw new Error(e.toString());
    }
    return parser;
  }

  /**
   * Reads a text file and returns the contents as a String.
   * 
   * @param file
   * @return file contents as a String
   */
  private static String readSource(String file) {
    StringBuilder buf = new StringBuilder();
    BufferedReader reader = null;
    try {
      reader = new BufferedReader(new FileReader(file));
      String line;
      while ((line = reader.readLine()) != null) {
        buf.append(line).append("\n");
      }
      return buf.toString();
    } catch (IOException e) {
      return null;
    } finally {
      if (reader != null) {
        try {
          reader.close();
        } catch (IOException e) {
        }
      }
    }
  }

  boolean apiParsing;
  DartUnit dartUnit;
  List<DartCompilationError> errors = new ArrayList<DartCompilationError>();
  String name;

  Thread parserWorker;

  String sourceCode;

  int timeoutInMillis = DEFAULT_TIMEOUT_IN_MILISECONDS;

  AtomicReference<Throwable> workerException = new AtomicReference<Throwable>();

  private boolean wantWarnings;

  private DartParserRunner(String name, String sourceCode) {
    this(name, sourceCode, false);
  }

  private DartParserRunner(String name, String sourceCode, boolean apiParsing) {
    this.name = name;
    this.sourceCode = sourceCode;
    this.parserWorker = new Thread(this);
    this.apiParsing = apiParsing;
  }

  @Override
  public void compilationError(DartCompilationError event) {
    errors.add(event);
  }

  @Override
  public void compilationWarning(DartCompilationError event) {
    if (wantWarnings) {
      errors.add(event);
    }
  }

  public int getErrorCount() {
    return errors.size();
  }

  public List<DartCompilationError> getErrors() {
    return errors;
  }

  public boolean hasErrors() {
    return getErrors().size() > 0;
  }

  @Override
  public void run() {
    try {
      DartSourceTest dartSrc = new DartSourceTest(name, sourceCode, null);
      ParserContext context = new DartScannerParserContext(dartSrc, sourceCode, this);
      dartUnit = (new DartParser(context, apiParsing)).parseUnit(dartSrc);
    } catch (Throwable t) {
      workerException.set(t);
    }
  }

  public DartParserRunner setTimeout(int timeoutInMillis) {
    this.timeoutInMillis = timeoutInMillis;
    return this;
  }

  public DartParserRunner setWantWarnings(boolean wantWarnings) {
    this.wantWarnings = wantWarnings;
    return this;
  }

  @Override
  public void typeError(DartCompilationError event) {
    errors.add(event);
  }

  private void doWork() throws InterruptedException {
    parserWorker.start();
    parserWorker.join(timeoutInMillis);
  }

  private boolean isAlive() {
    return parserWorker.isAlive();
  }

  @Override
  public void unitCompiled(DartUnit unit) {
  }
}
