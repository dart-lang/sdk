// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.parser.DartScanner.Location;
import com.google.dart.compiler.parser.DartScanner.Position;

import java.io.IOException;

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
   * The exception associated with this compilation error or <code>null</code>
   * if none.
   */
  private Exception exception;

  /**
   * Instantiate a new instance representing an {@link IOException} that
   * occurred when reading a source file.
   *
   * @param source the source file in which the exception occurred
   * @param exception the exception that occurred
   */
  public DartCompilationError(Source source, Exception exception) {
    setSource(source);
    setException(exception);
    message = exception.getMessage();

    // TODO (danrubel) Remove once JSON parsing is removed
    parseJSONException();
  }

  /**
   * This function is only necessary for processing a JSONException and can be
   * removed once ApplicationSourceFile and LibrarySourceFile no longer throw
   * JSONException
   */
  protected void parseJSONException() {
    if (message == null) {
      return;
    }

    // Strip filename off beginning of message
    if (message.startsWith("Error reading ")) {
      for (int i = 14; i < message.length(); i++) {
        if (!Character.isWhitespace(message.charAt(i)))
          continue;
        i++;
        if (i >= message.length() || Character.isWhitespace(message.charAt(i)))
          break;
        message = message.substring(i);
        break;
      }
    }

    // Strip " at character ###" off the end of the message
    for (int i = message.length() - 2; i > 0; i--) {
      if (Character.isDigit(message.charAt(i)))
        continue;
      i++;
      if (!message.substring(0, i).endsWith(" at character "))
        break;
      try {
        startPosition = Integer.valueOf(message.substring(i));
        message = message.substring(0, i - 14);
      } catch (NumberFormatException ignored) {
        // Fall through without modifying the error message
      }
      break;
    }

    // Strip JSON reference off beginning of error message
    if (message.startsWith("JSONObject[\"")) {
      int i = message.indexOf('"', 12);
      if (i > 12 && i + 2 < message.length())
        message = message.substring(11, i + 1) + message.substring(i + 2);
    }
  }

  /**
   * Instantiate a new instanced representing a compilation error at the
   * specified location.
   *
   * @param location The source location reference..
   * @param message The compilation error message.
   * @deprecated use {@link #DartCompilationError(SourceInfo, ErrorCode, Object...)}
   */
  @Deprecated
  public DartCompilationError(SourceInfo location, String message) {
    if (location != null) {
      this.lineNumber = location.getSourceLine();
      this.columnNumber = location.getSourceColumn();
      this.startPosition = location.getSourceStart();
      this.length = location.getSourceLength();
    }
    this.message = message;
    this.source = location.getSource();
  }

  /**
   * Instantiate a new instance representing a compilation error at the specified location.
   *
   * @param location the source range where the error occurred
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  public DartCompilationError(SourceInfo location, ErrorCode errorCode, Object... arguments) {
    this.lineNumber = location.getSourceLine();
    this.columnNumber = location.getSourceColumn();
    this.startPosition = location.getSourceStart();
    this.length = location.getSourceLength();
    this.errorCode = errorCode;
    this.message = String.format(errorCode.getMessage(), arguments);
    this.source = location.getSource();
  }

  /**
   * Instantiate a new instance representing a compilation error at the specified location.
   *
   * @param location the source range where the error occurred
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  public DartCompilationError(Location location, ErrorCode errorCode, Object... arguments) {
    this((Source)null, location, errorCode, arguments);
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
   * The exception associated with this compilation error or <code>null</code>
   * if none.
   */
  public Exception getException() {
    return exception;
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
   * Set the exception associated with this compilation error or
   * <code>null</code> if none.
   */
  public void setException(Exception exception) {
    this.exception = exception;
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
