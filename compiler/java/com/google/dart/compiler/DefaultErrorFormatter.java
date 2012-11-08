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
    String sourceName = "<unknown-source-file>";
    Source sourceFile = event.getSource();
    String includeFrom = getImportString(sourceFile);

    if (sourceFile != null) {
      sourceName = sourceFile.getUri().toString();
    }
    outputStream.printf("%s:%d:%d: %s%s\n",
        sourceName,
        event.getLineNumber(),
        event.getColumnNumber(),
        event.getMessage(),
        includeFrom);
  }

  public String getImportString(Source sourceFile) {
    String includeFrom = "";
    if (sourceFile instanceof DartSource) {
      LibrarySource lib = ((DartSource) sourceFile).getLibrary();
      if (lib != null && !Objects.equal(sourceFile.getUri(), lib.getUri())) {
        includeFrom = " (sourced from " + lib.getUri() + ")";
      }
    }
    return includeFrom;
  }
}
