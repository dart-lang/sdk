// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.PrintStream;

/**
 * An error formatter that simply prints the file name with the line and column
 * location.
 */
public class DefaultErrorFormatter implements ErrorFormatter {
  protected PrintStream outputStream = System.err;

  public void setOutputStream(PrintStream outputStream) {
    this.outputStream = outputStream;
  }

  @Override
  public void format(DartCompilationError event) {
    outputStream.printf("%s:%d:%d: %s\n",
        (event.getSource() != null)
            ? event.getSource().getUri() : "<unknown-source-file>",
        event.getLineNumber(),
        event.getColumnNumber(),
        event.getMessage());
  }
}
