/*
 * Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * This file has been automatically generated. Please do not edit it manually.
 * To regenerate the file, use the script "pkg/analysis_server/tool/spec/generate_files".
 */
package org.dartlang.analysis.server.protocol;

/**
 * An enumeration of the severities of problems that can be returned by the refactoring requests.
 *
 * @coverage dart.server.generated.types
 */
public class RefactoringProblemSeverity {

  /**
   * A minor code problem. No example, because it is not used yet.
   */
  public static final String INFO = "INFO";

  /**
   * A minor code problem. For example names of local variables should be camel case and start with a
   * lower case letter. Staring the name of a variable with an upper case is OK from the language
   * point of view, but it is nice to warn the user.
   */
  public static final String WARNING = "WARNING";

  /**
   * The refactoring technically can be performed, but there is a logical problem. For example the
   * name of a local variable being extracted conflicts with another name in the scope, or duplicate
   * parameter names in the method being extracted, or a conflict between a parameter name and a
   * local variable, etc. In some cases the location of the problem is also provided, so the IDE can
   * show user the location and the problem, and let the user decide whether they want to perform the
   * refactoring. For example the name conflict might be expected, and the user wants to fix it
   * afterwards.
   */
  public static final String ERROR = "ERROR";

  /**
   * A fatal error, which prevents performing the refactoring. For example the name of a local
   * variable being extracted is not a valid identifier, or selection is not a valid expression.
   */
  public static final String FATAL = "FATAL";

}
