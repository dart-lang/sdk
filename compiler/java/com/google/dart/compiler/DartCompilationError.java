// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.parser.DartScanner.Location;
import com.google.dart.compiler.parser.DartScanner.Position;

/**
 * Information about a compilation error.
 *
 * @see DartCompilerListener
 */
public class DartCompilationError {

  /**
   * The character offset from the beginning of the source (zero based) where
   * the error occurred.
   */
  private int startPosition = 0;

  /**
   * The number of characters from the startPosition to the end of the source
   * which encompasses the compilation error.
   */
  private int length = 0;

  /**
   * The line number in the source (one based) where the error occurred or -1 if
   * it is undefined.
   */
  private int lineNumber = -1;

  /**
   * The column number in the source (one based) where the error occurred or -1
   * if it is undefined.
   */
  private int columnNumber = -1;

  /**
   * The error code associated with the error.
   */
  private ErrorCode errorCode;

  /**
   * The compilation error message.
   */
  private String message;

  /**
   * The source in which the error occurred or <code>null</code> if unknown.
   */
  private Source source;

  /**
   * Instantiate a new instance representing an error for the specified {@link Source}.
   *
   * @param source the {@link Source} for which the exception occurred
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  public DartCompilationError(Source source, ErrorCode errorCode, Object... arguments) {
    this.source = source;
    this.errorCode = errorCode;
    this.message = String.format(errorCode.getMessage(), arguments);
  }

  /**
   * Instantiate a new instance representing a compilation error at the specified location.
   *
   * @param location the source range where the error occurred
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  public DartCompilationError(SourceInfo location, ErrorCode errorCode, Object... arguments) {
    this.source = location.getSource();
    this.lineNumber = location.getSourceLine();
    this.columnNumber = location.getSourceColumn();
    this.startPosition = location.getSourceStart();
    this.length = location.getSourceLength();
    this.errorCode = errorCode;
    this.message = String.format(errorCode.getMessage(), arguments);
  }

  /**
   * Instantiate a new instance representing a compilation error at the specified location.
   *
   * @param source the source reference
   * @param location the source range where the error occurred
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  public DartCompilationError(Source source, Location location, ErrorCode errorCode, Object... arguments) {
    this.source = source;
    this.errorCode = errorCode;
    this.message = String.format(errorCode.getMessage(), arguments);
    if (location != null) {
      Position begin = location.getBegin();
      if (begin != null) {
        startPosition = begin.getPos();
        lineNumber = begin.getLine();
        columnNumber = begin.getCol();
      }
      Position end = location.getEnd();
      if (end != null) {
        length = end.getPos() - startPosition;
        if (length < 0) {
          length = 0;
        }
      }
    }
  }

  /**
   * The column number in the source (one based) where the error occurred.
   */
  public int getColumnNumber() {
    return columnNumber;
  }

  /**
   * Return the error code associated with the error.
   */
  public ErrorCode getErrorCode() {
    return errorCode;
  }

  /**
   * The line number in the source (one based) where the error occurred.
   */
  public int getLineNumber() {
    return lineNumber;
  }

  /**
   * The compilation error message.
   */
  public String getMessage() {
    return message;
  }

  /**
   * Return the source in which the error occurred or <code>null</code> if
   * unknown.
   */
  public Source getSource() {
    return source;
  }

  /**
   * The character offset from the beginning of the source (zero based) where
   * the error occurred.
   */
  public int getStartPosition() {
    return startPosition;
  }

  /**
   * The length of the error location.
   */
  public int getLength() {
    return length;
  }

  @Override
  public int hashCode() {
    int hashCode = startPosition;
    hashCode ^= (message != null) ? message.hashCode() : 0;
    hashCode ^= (source != null) ? source.getName().hashCode() : 0;
    return hashCode;
  }

  /**
   * Set the source in which the error occurred or <code>null</code> if unknown.
   */
  public void setSource(Source source) {
    this.source = source;
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append((source != null) ? source.getName() : "<unknown source>");
    sb.append("(" + lineNumber + ":" + columnNumber + "): ");
    sb.append(message);
    return sb.toString();
 }
}
