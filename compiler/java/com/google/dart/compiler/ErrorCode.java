// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

import com.google.dart.compiler.util.apache.StringUtils;

/**
 * The behavior common to objects representing error codes associated with
 * {@link DartCompilationError Dart compilation errors}.
 */
public interface ErrorCode {
  /**
   * Return the message template used to create the message to be displayed for this error.
   */
  String getMessage();

  /**
   * @return the {@link ErrorSeverity} of this error.
   */
  ErrorSeverity getErrorSeverity();

  /**
   * @return the {@link SubSystem} which issued this error.
   */
  SubSystem getSubSystem();

  /**
   * @return <code>true</code> if this {@link ErrorCode} should cause recompilation of the source
   *         during next incremental compilation.
   */
  boolean needsRecompilation();
  
  public class Helper {
    /**
     * @return the "qualified name" of the given {@link ErrorCode} enumeration, good for passing it
     *         to {@link #forQualifiedName(String)}.
     */
    public static String toQualifiedName(ErrorCode errorCode) {
      return errorCode.getClass().getCanonicalName() + "." + ((Enum<?>) errorCode).name();
    }

    /**
     * @return the {@link ErrorCode} enumeration constant for string from
     *         {@link #toQualifiedName(ErrorCode)}.
     */
    public static ErrorCode forQualifiedName(String qualifiedName) {
      try {
        String className = StringUtils.substringBeforeLast(qualifiedName, ".");
        String fieldName = StringUtils.substringAfterLast(qualifiedName, ".");
        Class<?> errorCodeClass = Class.forName(className);
        return (ErrorCode) errorCodeClass.getField(fieldName).get(null);
      } catch (Throwable e) {
        return null;
      }
    }
  }
}
