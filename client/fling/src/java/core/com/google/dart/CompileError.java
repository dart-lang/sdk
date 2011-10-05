// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart;

import java.io.Serializable;

import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.Source;

@SuppressWarnings("serial")
public class CompileError implements Serializable {
  public static CompileError from(DartCompilationError error) {
    final Source source = error.getSource();
    return new CompileError(error.getStartPosition(),
        error.getLength(),
        error.getLineNumber(),
        error.getColumnNumber(),
        error.getMessage(),
        source != null ? source.getName() : "<unknown source>");
  }
  private final int start;
  private final int length;
  private final int line;
  private final int column;
  private final String message;
  
  private final String source;
  
  private CompileError(int start, int length, int line, int column, String message, String source) {
    this.start = start;
    this.length = length;
    this.line = line;
    this.column = column;
    this.message = message;
    this.source = source;
  }

  public int getColumn() {
    return column;
  }

  public int getLength() {
    return length;
  }

  public int getLine() {
    return line;
  }

  public String getMessage() {
    return message;
  }

  public String getSource() {
    return source;
  }

  public int getStart() {
    return start;
  }
  
  @Override
  public String toString() {
    StringBuilder buffer = new StringBuilder();
    buffer.append(source);
    buffer.append("(" + line + ":" + column + "): ");
    buffer.append(message);
    return buffer.toString();
  }
}
