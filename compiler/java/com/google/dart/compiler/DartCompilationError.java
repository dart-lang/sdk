// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.common.HasSourceInfo;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.parser.DartScanner.Location;

/**
 * Information about a compilation error.
 * 
 * @see DartCompilerListener
 */
public class DartCompilationError {

  /**
   * The character offset from the beginning of the source (zero based) where the error occurred.
   */
  private int offset = 0;

  /**
   * The number of characters from the startPosition to the end of the source which encompasses the
   * compilation error.
   */
  private int length = 0;

  /**
   * The line number in the source (one based) where the error occurred or -1 if it is undefined.
   */
  private int lineNumber = -1;

  /**
   * The column number in the source (one based) where the error occurred or -1 if it is undefined.
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
   * Compilation error for the specified {@link Source}, without location.
   * 
   * @param source the {@link Source} for which the exception occurred
   * @param errorCode the {@link ErrorCode} to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  public DartCompilationError(Source source, ErrorCode errorCode, Object... arguments) {
    this.source = source;
    this.errorCode = errorCode;
    this.message = String.format(errorCode.getMessage(), arguments);
  }

  /**
   * Compilation error at the {@link SourceInfo} from specified {@link HasSourceInfo}.
   * 
   * @param hasSourceInfo the provider of {@link SourceInfo} where the error occurred
   * @param errorCode the {@link ErrorCode} to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  public DartCompilationError(HasSourceInfo hasSourceInfo, ErrorCode errorCode, Object... arguments) {
    this(hasSourceInfo.getSourceInfo(), errorCode, arguments);
  }

  /**
   * Compilation error at the specified {@link SourceInfo}.
   * 
   * @param sourceInfo the {@link SourceInfo} where the error occurred
   * @param errorCode the {@link ErrorCode} to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  public DartCompilationError(SourceInfo sourceInfo, ErrorCode errorCode, Object... arguments) {
    this.source = sourceInfo.getSource();
    this.lineNumber = sourceInfo.getLine();
    this.columnNumber = sourceInfo.getColumn();
    this.offset = sourceInfo.getOffset();
    this.length = sourceInfo.getLength();
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
  public DartCompilationError(Source source,
      Location location,
      ErrorCode errorCode,
      Object... arguments) {
    this.source = source;
    this.errorCode = errorCode;
    this.message = String.format(errorCode.getMessage(), arguments);
    if (location != null) {
      offset = location.getBegin();
      SourceInfo sourceInfo = new SourceInfo(source, offset, 0);
      lineNumber = sourceInfo.getLine();
      columnNumber = sourceInfo.getColumn();
      length = location.getEnd() - offset;
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
   * Return the source in which the error occurred or <code>null</code> if unknown.
   */
  public Source getSource() {
    return source;
  }

  /**
   * The character offset from the beginning of the source (zero based) where the error occurred.
   */
  public int getStartPosition() {
    return offset;
  }

  /**
   * The length of the error location.
   */
  public int getLength() {
    return length;
  }

  @Override
  public int hashCode() {
    int hashCode = offset;
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
