// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.common.io.Closeables;
import com.google.dart.compiler.CompilerConfiguration.ErrorFormat;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintStream;
import java.io.Reader;

/**
 * An error formatter that scans the source file and prints the error line and
 * some context around it. This formatter has two modes: with or without color.
 * When using colors, it prints the error message in red, and it highlights the
 * portion of the line containing the error in red. Without colors, it prints an
 * extra line underlying the portion of the line containing the error.
 */
public class PrettyErrorFormatter extends DefaultErrorFormatter {
  public static final String ERROR_BOLD_COLOR = "\033[31;1m";
  public static final String ERROR_COLOR = "\033[31m";

  // Mix ANSI with xterm colors, giving ANSI priority.  The terminal should ignore xterm codes
  // if it doesn't support them.
  public static final String WARNING_BOLD_COLOR = "\033[33;1m\033[38;5;202m";
  public static final String WARNING_COLOR = "\033[33m\033[38;5;208m";

  public static final String NO_COLOR = "\033[0m";

  private final boolean useColor;

  public PrettyErrorFormatter(PrintStream outputStream,
      boolean useColor,
      ErrorFormat errorFormat) {
    super(outputStream, errorFormat);
    this.useColor = useColor;
  }

  @Override
  public void format(DartCompilationError event) {
    Source sourceFile = event.getSource();

    // if this is an unknown source type, default to the basic error formatter
    if (!(sourceFile instanceof DartSource) && !(sourceFile instanceof LibrarySource)) {
      super.format(event);
      return;
    }

    BufferedReader reader = null;
    try {
      Reader sourceReader = sourceFile.getSourceReader();
      if (sourceReader != null) {
        reader = new BufferedReader(sourceReader);
      }

      // get the error line and the line above it (note: line starts at 1)
      int line = event.getLineNumber();
      String lineBefore = null;
      String lineText = null;

      if (reader != null) {
        lineBefore = getLineAt(reader, line - 1);
        lineText = getLineAt(reader, 1);
      }

      // if there is no line to highlight, default to the basic error formatter
      if (lineText == null) {
        super.format(event);
        return;
      }

      // get column/length and ensure they are within the line limits.
      int col = event.getColumnNumber() - 1;
      int length = event.getLength();
      col = between(col, 0, lineText.length());
      length = between(length, 0, lineText.length() - col);
      length = length == 0 ? lineText.length() - col : length;

      // print the error message
      StringBuilder buf = new StringBuilder();
      if (useColor) {
        buf.append(event.getErrorCode().getErrorSeverity() == ErrorSeverity.WARNING
            ? WARNING_BOLD_COLOR : ERROR_BOLD_COLOR);
      }
      appendError(buf, event);
      if (useColor) {
        buf.append(NO_COLOR);
      }
      buf.append("\n");
      // show the previous line for context
      if (lineBefore != null) {
        buf.append(String.format("%6d: %s\n", line - 1, lineBefore));
      }

      if (useColor) {
        // highlight error in red
        buf.append(String.format("%6d: %s%s%s%s%s\n",
              line,
              lineText.substring(0, col),
              event.getErrorCode().getErrorSeverity() == ErrorSeverity.WARNING
              ? WARNING_COLOR : ERROR_COLOR,
              lineText.substring(col, col + length),
              NO_COLOR,
              lineText.substring(col + length)));
      } else {
        // print the error line without formatting
        buf.append(String.format("%6d: %s\n", line, lineText));

        // underline error portion
        buf.append("        ");
        for (int i = 0; i < col; ++i) {
          buf.append(' ');
        }
        buf.append('~');
        if (length > 1) {
          for (int i = 0; i < length - 2; ++i) {
            buf.append('~');
          }
          buf.append('~');
        }
        buf.append('\n');
      }

      outputStream.print(buf.toString());
    } catch (IOException ex) {
      super.format(event);
    } finally {
      if (reader != null) {
        Closeables.closeQuietly(reader);
      }
    }
  }

  private String getLineAt(BufferedReader reader, int line) throws IOException {
    if (line <= 0) {
      return null;
    }
    String currentLine = null;
    // TODO(sigmund): do something more efficient - we currently do a linear
    // scan of the file every time an error is reported. This will not scale
    // when many errors are reported on the same file.
    while ((currentLine = reader.readLine()) != null && line-- > 1){}
    return currentLine;
  }

  /**
   * Returns the closest value in {@code [start,end]} to the given value. If
   * the given range is entirely empty, then {@code start} is returned.
   */
  private static int between(int val, int start, int end) {
    return Math.max(start, Math.min(val, end));
  }
}
