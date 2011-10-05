// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.appstack.tools.dartserver;

import com.google.common.base.Preconditions;
import com.google.common.base.Throwables;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.Source;

import java.io.BufferedReader;
import java.io.IOException;

/**
 * Utility class that generates Javascript code to render error messages
 * (including dartc compiler errors, and dartc exceptions).
 */
public class ErrorFormatter {

  /** Css used in formatting error messages. */
  private static final String ERROR_CSS = ""
      + "@font-face {"
      + "   font-family: \"Consolas\";"
      + "   font-style: normal;"
      + "   font-weight: normal;"
      + "   src: local(\"Consolas\"), "
      + "        url(\"http://themes.googleusercontent.com/fonts/"
      + "font?kit=i88R1Ke5pSbpLTTuhd51Fw\") format(\"truetype\");"
      + " }"
      + "body {"
      + "  overflow: scroll;"
      + "}"
      + ".error {"
      + "  background: #eef;"
      + "  font-size: 11pt;"
      + "  border-style:solid;"
      + "  border-width:1px;"
      + "  padding: 5px 5px 5px 15px;"
      + "  margin: 2px;"
      + "  border-radius: 7px;"
      + "  width: 100%;"
      + "  font-family: verdana, sans-serif;"
      + "  color: black;"
      + "}"
      + ".error td {"
      + "  vertical-align:top;"
      + "}"
      + ".error .code-snippet {"
      + "  font-family: Consolas, Lucida Console, monospace;"
      + "  white-space: pre;"
      + "}"
      + ".error .error-portion {"
      + "  white-space: pre;"
      + "  color: red;"
      + "  font-weight: bold;"
      + "}"
      + ".error .error-message {"
      + "  color: red;"
      + "  font-weight: bold;"
      + "}"
      + ".error .error-location {"
      + "  color: blue;"
      + "}";

  /** The resutls from calling dartc. */
  private final DartApp.Result result;

  /** Buffer containing the generated JS code. */
  private final StringBuilder buf = new StringBuilder();

  private ErrorFormatter(DartApp.Result result) {
    this.result = result;
  }

  /**
   * Creates a script that displays dart syntax errors, dart compile errors, and
   * internal dartc compiler exceptions to the user.
   */
  public static String reportErrorsAsJs(DartApp.Result result) {
    return new ErrorFormatter(result).reportErrorsAsJs();
  }

  private String reportErrorsAsJs() {
    appendSafe("window.addEventListener('load', function() { document.body.innerHTML = '");
    appendSafe("<style> " + ERROR_CSS + "</style>");
    appendSafe("<div style=\"width:80%;\">");
    for (DartCompilationError error : result.getErrors()) {
      formatCompilationError(error);
    }
    appendSafe("</div>");

    if (result.getCompilationException() != null) {
      appendSafe("<h2>Dart compiler exception</h2><pre>");
      append(Throwables.getStackTraceAsString(result.getCompilationException()));
      appendSafe("</pre>");
    }

    appendSafe("' + document.body.innerHTML;");
    // Report errors to the developer console as well.
    for (DartCompilationError error : result.getErrors()) {
      appendSafe("console.error("
                + toJavaScriptStringLiteral(error.toString()) + ");\n");
    }
    if (result.getCompilationException() != null) {
      appendSafe("console.error(" + toJavaScriptStringLiteral(
          Throwables.getStackTraceAsString(result.getCompilationException()))
          + ");\n");
    }

    appendSafe("}, false);");
    return buf.toString();
  }

  private void formatCompilationError(DartCompilationError error) {
    Source sourceFile = error.getSource();
    int line = error.getLineNumber();
    // line numbers start at 1
    Preconditions.checkState(line > 0);
    String[] displayLines = getLines(sourceFile, Math.max(line - 1, 1), line);

    if (displayLines == null) {
      // default to the basic error format
      fallbackFormat(error);
      return;
    }

    Preconditions.checkState(
        displayLines.length == 1 || displayLines.length == 2);
    String lineBefore = null;
    String errorLine = null;
    if (displayLines.length == 1) {
      errorLine = displayLines[0];
    } else {
      lineBefore = displayLines[0];
      errorLine = displayLines[1];
    }

    // show heading with error message and file:
    appendSafe("<table class=\"error\"><tbody>");
    appendSafe("<tr><td colspan=\"2\">Error: <span class=\"error-message\">");
    append(error.getMessage());
    appendSafe("</span> (<span class=\"error-location\">");
    append(sourceFile.getName());
    appendSafe("</span>:");
    appendSafe(line);
    appendSafe(")</td></tr>");

    // show the previous line for context
    if (lineBefore != null && !lineBefore.trim().isEmpty()) {
      appendCodeSnippetLine(line - 1, htmlEscape(lineBefore));
    }

    // show error line, highlighting the error portion.
    appendCodeSnippetLine(line, highlightRangeHtml(
        errorLine, error.getColumnNumber() - 1, error.getLength()));
    appendSafe("</tbody></table>");
  }

  private void appendCodeSnippetLine(int line, String htmlSafeText) {
    appendSafe("<tr class=\"code-snippet\"><td>");
    appendSafe(line);
    appendSafe("</td><td>");
    appendSafe(htmlSafeText);
    appendSafe("</td></tr>");
  }

  /**
   * Split text in 3 segments [0, start], [start, start + length], and [start +
   * length, ...]. Sanitize each segment to be safe html, and wrap the middle
   * range in a &lgt;span&gt; element that highlights an error.
   *
   * Note: HTML escaping is done on each segment after slicing the text because
   * otherwise the start and length could get misaligned.
   */
  private String highlightRangeHtml(String text, int start, int length) {
    start = clamp(start, 0, text.length());
    length = clamp(length, 0, text.length() - start);
    return (length == 0) ? htmlEscape(text)
        : htmlEscape(text.substring(0, start))
            + "<span class=\"error-portion\">"
            + htmlEscape(text.substring(start, start + length))
            + "</span>"
            + htmlEscape(text.substring(start + length));
  }

  private static String htmlEscape(String text) {
    return text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\"", "&quot;")
        .replace("'", "&apos;")
        .replace("\n", "<br>")
        .replace(" ", "&nbsp;");
  }

  private void appendSafe(String htmlSafeText) {
    buf.append(htmlSafeText);
  }

  private void append(String unsafeText) {
    buf.append(htmlEscape(unsafeText));
  }

  private void appendSafe(int value) {
    buf.append(value);
  }

  private void fallbackFormat(DartCompilationError error) {
    appendSafe("<div class=\"error\"><span class\"error-portion\">");
    append(error.toString());
    appendSafe("</span></div>");
  }

  /**
   * Return all lines from {@code start} to {@code end} in a source file, or
   * null if the line numbers are out of range or any error occurs while reading
   * the file.
   */
  private static String[] getLines(Source source, int start, int end) {
    Preconditions.checkArgument(start >= 1);
    Preconditions.checkArgument(end >= start);
    BufferedReader reader = null;
    try {
      if (source.getSourceReader() == null) {
        // no file to read from: return the error state (null)
        return null;
      }
      reader = new BufferedReader(source.getSourceReader());
      String[] res = new String[end - start + 1];
      // note that line numbers start at 1:
      for (int i = 1; i <= end; i++) {
        String currentLine = reader.readLine();
        if (currentLine == null) {
          // no line should be out of range: return the error state (null)
          return null;
        }
        if (i >= start) {
          res[i - start] = currentLine;
        }
      }
      return res;
    } catch (IOException ex) {
      // error reading the file: return the error state (null)
      return null;
    } finally {
      if (reader != null) {
        try {
          reader.close();
        } catch (IOException ex) {
          // do nothing
        }
      }
    }
  }

  /**
   * Returns the closest value in {@code [start,end]} to the given value. If
   * the given range is entirely empty, then {@code start} is returned.
   */
  private static int clamp(int val, int start, int end) {
    return Math.max(start, Math.min(val, end));
  }
  
  private static String toJavaScriptStringLiteral(String value) {
    return "'" + value.replace("'", "\\'").replace("\n", "\\\n") + "'";
  }

}
