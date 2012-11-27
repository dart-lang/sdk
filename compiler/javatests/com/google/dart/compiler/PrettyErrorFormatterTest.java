// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

import com.google.common.base.Joiner;
import com.google.dart.compiler.CompilerConfiguration.ErrorFormat;
import com.google.dart.compiler.parser.DartScanner.Location;
import com.google.dart.compiler.resolver.ResolverErrorCode;
import com.google.dart.compiler.resolver.TypeErrorCode;

import junit.framework.TestCase;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.io.Reader;

/**
 * Test for {@link PrettyErrorFormatter}.
 */
public class PrettyErrorFormatterTest extends TestCase {
  private static final String ERROR_BOLD_COLOR = PrettyErrorFormatter.ERROR_BOLD_COLOR;
  private static final String ERROR_COLOR = PrettyErrorFormatter.ERROR_COLOR;
  private static final String WARNING_BOLD_COLOR = PrettyErrorFormatter.WARNING_BOLD_COLOR;
  private static final String WARNING_COLOR = PrettyErrorFormatter.WARNING_COLOR;
  private static final String NO_COLOR = PrettyErrorFormatter.NO_COLOR;

  private static final Source SOURCE = new DartSourceTest("my/path/Test.dart",
      Joiner.on("\n").join("lineAAA", "lineBBB", "lineCCC"),
      new MockLibrarySource());

  /**
   * Not a {@link DartSource}, rollback to {@link DefaultErrorFormatter}.
   */
  public void test_notDartSource() throws Exception {
    Source emptyDartSource = new SourceTest("Test.dart") {
      @Override
      public Reader getSourceReader() {
        return null;
      }
    };
    Location location = new Location(2);
    DartCompilationError error =
        new DartCompilationError(emptyDartSource, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals("Test.dart:1:3: no such type \"Foo\"\n", errorString);
  }

  /**
   * Use {@link DartSource} with source {@link Reader} which throws {@link IOException}, rollback to
   * {@link DefaultErrorFormatter}.
   */
  public void test_throwsIOException() throws Exception {
    Source badDartSource = new DartSourceTest("my/path/Test.dart", "", new MockLibrarySource()) {
      @Override
      public Reader getSourceReader() {
        return new Reader() {
          @Override
          public int read(char[] cbuf, int off, int len) throws IOException {
            throw new IOException("boo!");
          }

          @Override
          public void close() {
          }
        };
      }
    };
    Location location = new Location(2);
    DartCompilationError error =
        new DartCompilationError(badDartSource, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals(
        "my/path/Test.dart:1:3: no such type \"Foo\" (sourced from Test_app)\n",
        errorString);
  }

  /**
   * Empty {@link DartSource}, rollback to {@link DefaultErrorFormatter}.
   */
  public void test_emptyDartSource() throws Exception {
    Source emptyDartSource = new DartSourceTest("my/path/Test.dart", "", new MockLibrarySource());
    Location location = new Location(2);
    DartCompilationError error =
        new DartCompilationError(emptyDartSource, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals(
        "my/path/Test.dart:1:3: no such type \"Foo\" (sourced from Test_app)\n",
        errorString);
  }

  /**
   * Error on first line, so no previous line printed.
   */
  public void test_noColor_notMachine_firstLine() throws Exception {
    Location location = new Location(2, 5);
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals(
        Joiner.on("\n").join(
            "my/path/Test.dart:1:3: no such type \"Foo\" (sourced from Test_app)",
            "     1: lineAAA",
            "          ~~~",
            ""),
        errorString);
  }

  /**
   * {@link Location} with single <code>Position</code>, underline single character.
   */
  public void test_noColor_notMachine_singlePosition() throws Exception {
    Location location = new Location(10);
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals(
        Joiner.on("\n").join(
            "my/path/Test.dart:2:3: no such type \"Foo\" (sourced from Test_app)",
            "     1: lineAAA",
            "     2: lineBBB",
            "          ~~~~~",
            ""),
        errorString);
  }

  /**
   * {@link Location} with single <code>Position</code>, underline single character.
   */
  public void test_withColor_notMachine_singlePosition() throws Exception {
    Location location = new Location(10);
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    String errorString = getErrorString(error, true, false);
    assertEquals(
        Joiner.on("\n").join(
            WARNING_BOLD_COLOR
                + "my/path/Test.dart:2:3: no such type \"Foo\" (sourced from Test_app)"
                + NO_COLOR,
            "     1: lineAAA",
            "     2: li" + WARNING_COLOR + "neBBB" + NO_COLOR,
            ""),
        errorString);

    error = new DartCompilationError(SOURCE, location, ResolverErrorCode.NO_SUCH_TYPE, "Foo");
    errorString = getErrorString(error, true, false);
    assertEquals(
        Joiner.on("\n").join(
            ERROR_BOLD_COLOR
                + "my/path/Test.dart:2:3: no such type \"Foo\" (sourced from Test_app)"
                + NO_COLOR,
            "     1: lineAAA",
            "     2: li" + ERROR_COLOR + "neBBB" + NO_COLOR,
            ""),
        errorString);
  }

  /**
   * Underline range of characters.
   */
  public void test_noColor_notMachine() throws Exception {
    Location location = new Location(10, 10 + 3);
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, false);
    assertEquals(
        Joiner.on("\n").join(
            "my/path/Test.dart:2:3: no such type \"Foo\" (sourced from Test_app)",
            "     1: lineAAA",
            "     2: lineBBB",
            "          ~~~",
            ""),
        errorString);
  }

  /**
   * Use color to highlight range of characters.
   */
  public void test_withColor_notMachine() throws Exception {
    Location location = new Location(10, 10 + 3);
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    String errorString = getErrorString(error, true, false);
    assertEquals(
        Joiner.on("\n").join(
            WARNING_BOLD_COLOR
                + "my/path/Test.dart:2:3: no such type \"Foo\" (sourced from Test_app)"
                + NO_COLOR,
            "     1: lineAAA",
            "     2: li" + WARNING_COLOR + "neB" + NO_COLOR + "BB",
            ""),
        errorString);

    error = new DartCompilationError(SOURCE, location, ResolverErrorCode.NO_SUCH_TYPE, "Foo");
    errorString = getErrorString(error, true, false);
    assertEquals(
        Joiner.on("\n").join(
            ERROR_BOLD_COLOR
                + "my/path/Test.dart:2:3: no such type \"Foo\" (sourced from Test_app)"
                + NO_COLOR,
            "     1: lineAAA",
            "     2: li" + ERROR_COLOR + "neB" + NO_COLOR + "BB",
            ""),
        errorString);
  }

  /**
   * Include all information about error context.
   */
  public void test_noColor_forMachine() throws Exception {
    Location location = new Location(10, 10 + 4);
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    //
    String errorString = getErrorString(error, false, true);
    assertEquals(
        Joiner.on("\n").join(
            "WARNING|STATIC_TYPE|NO_SUCH_TYPE|my/path/Test.dart|2|3|4|no such type \"Foo\"",
            "     1: lineAAA",
            "     2: lineBBB",
            "          ~~~~",
            ""),
        errorString);
  }

  /**
   * Use color to highlight range of characters. Include all information about error context.
   */
  public void test_withColor_forMachine() throws Exception {
    Location location = new Location(10, 10 + 4);
    DartCompilationError error =
        new DartCompilationError(SOURCE, location, TypeErrorCode.NO_SUCH_TYPE, "Foo");
    String errorString = getErrorString(error, true, true);
    assertEquals(
        Joiner.on("\n").join(
            WARNING_BOLD_COLOR
                + "WARNING|STATIC_TYPE|NO_SUCH_TYPE|my/path/Test.dart|2|3|4|no such type \"Foo\""
                + NO_COLOR,
            "     1: lineAAA",
            "     2: li" + WARNING_COLOR + "neBB" + NO_COLOR + "B",
            ""),
        errorString);

    error = new DartCompilationError(SOURCE, location, ResolverErrorCode.NO_SUCH_TYPE, "Foo");
    errorString = getErrorString(error, true, true);
    assertEquals(
        Joiner.on("\n").join(
            ERROR_BOLD_COLOR
                + "ERROR|RESOLVER|NO_SUCH_TYPE|my/path/Test.dart|2|3|4|no such type \"Foo\""
                + NO_COLOR,
            "     1: lineAAA",
            "     2: li" + ERROR_COLOR + "neBB" + NO_COLOR + "B",
            ""),
        errorString);
  }

  /**
   * @return output produced by {@link PrettyErrorFormatter}.
   */
  private String getErrorString(DartCompilationError error,
      boolean useColor,
      boolean printMachineProblems) {
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    PrintStream printStream = new PrintStream(outputStream);
    ErrorFormatter errorFormatter =
        new PrettyErrorFormatter(printStream, useColor, printMachineProblems
            ? ErrorFormat.MACHINE
            : ErrorFormat.NORMAL);
    errorFormatter.format(error);
    return outputStream.toString();
  }
}
