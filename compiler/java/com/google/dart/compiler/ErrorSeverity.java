// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

/**
 * The severity of {@link ErrorCode}.
 */
public enum ErrorSeverity {
  /**
   * Fatal error.
   */
  ERROR("E"),
  /**
   * Warning, may become error with -Werror command line flag.
   */
  WARNING("W"),
  /**
   * Info, not considered an official warning
   */
  INFO("I");

  final String name;

  ErrorSeverity(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }
}