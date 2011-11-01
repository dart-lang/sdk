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
  WARNING("W");
  final String name;

  ErrorSeverity(String name) {
    this.name = name;
  }

  public String getName() {
    return name;
  }
}