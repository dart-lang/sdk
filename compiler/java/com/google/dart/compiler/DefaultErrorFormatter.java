// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.common.base.Objects;
import com.google.dart.compiler.CompilerConfiguration.ErrorFormat;

import java.io.PrintStream;

/**
 * An error formatter that simply prints the file name with the line and column
 * location.
 */
public class DefaultErrorFormatter implements ErrorFormatter {
  protected final PrintStream outputStream;
  protected final ErrorFormat errorFormat;
  
  public DefaultErrorFormatter(PrintStream outputStream, ErrorFormat errorFormat) {
    this.outputStream = outputStream;
    this.errorFormat = errorFormat;
  }

  @Override
  public void format(DartCompilationError event) {
    StringBuilder buf = new StringBuilder();
    appendError(buf, event);
    outputStream.print(buf);
    outputStream.print("\n");
  }

  protected void appendError(StringBuilder buf, DartCompilationError error) {
    Source source = error.getSource();
    String sourceName = getSourceName(source);
    int line = error.getLineNumber();
    int col = error.getColumnNumber();
    int length = error.getLength();
    if (errorFormat == ErrorFormat.MACHINE) {
      buf.append(String.format(
          "%s|%s|%s|%s|%d|%d|%d|%s",
          escapePipe(error.getErrorCode().getErrorSeverity().toString()),
          escapePipe(error.getErrorCode().getSubSystem().toString()),
          escapePipe(error.getErrorCode().toString()),
          escapePipe(sourceName),
          line,
          col,
          length,
          escapePipe(error.getMessage())));
    } else {
      String includeFrom = getImportString(source);
      buf.append(String.format(
          "%s:%d:%d: %s%s",
          sourceName,
          line,
          col,
          error.getMessage(),
          includeFrom));
    }
  }

  protected static String getImportString(Source sourceFile) {
    String includeFrom = "";
    if (sourceFile instanceof DartSource) {
      LibrarySource lib = ((DartSource) sourceFile).getLibrary();
      if (lib != null && !Objects.equal(sourceFile.getUri(), lib.getUri())) {
        includeFrom = " (sourced from " + lib.getUri() + ")";
      }
    }
    return includeFrom;
  }
  
  protected static String getSourceName(Source source) {
    if (source instanceof UrlDartSource) {
      return source.getUri().toString();
    }
    if (source != null) {
      return source.getName();
    }
    return "<unknown-source-file>";
  }

  protected static String escapePipe(String input) {
    StringBuilder result = new StringBuilder();
    for (char c : input.toCharArray()) {
      if (c == '\\' || c == '|') {
        result.append('\\');
      }
      result.append(c);
    }
    return result.toString();
  }
}
