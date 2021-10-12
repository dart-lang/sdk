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
 * An enumeration of the kinds of highlighting that can be applied to files.
 *
 * @coverage dart.server.generated.types
 */
public class HighlightRegionType {

  public static final String ANNOTATION = "ANNOTATION";

  public static final String BUILT_IN = "BUILT_IN";

  public static final String CLASS = "CLASS";

  public static final String COMMENT_BLOCK = "COMMENT_BLOCK";

  public static final String COMMENT_DOCUMENTATION = "COMMENT_DOCUMENTATION";

  public static final String COMMENT_END_OF_LINE = "COMMENT_END_OF_LINE";

  public static final String CONSTRUCTOR = "CONSTRUCTOR";

  public static final String CONSTRUCTOR_TEAR_OFF = "CONSTRUCTOR_TEAR_OFF";

  public static final String DIRECTIVE = "DIRECTIVE";

  /**
   * Deprecated - no longer sent.
   */
  public static final String DYNAMIC_TYPE = "DYNAMIC_TYPE";

  public static final String DYNAMIC_LOCAL_VARIABLE_DECLARATION = "DYNAMIC_LOCAL_VARIABLE_DECLARATION";

  public static final String DYNAMIC_LOCAL_VARIABLE_REFERENCE = "DYNAMIC_LOCAL_VARIABLE_REFERENCE";

  public static final String DYNAMIC_PARAMETER_DECLARATION = "DYNAMIC_PARAMETER_DECLARATION";

  public static final String DYNAMIC_PARAMETER_REFERENCE = "DYNAMIC_PARAMETER_REFERENCE";

  public static final String ENUM = "ENUM";

  public static final String ENUM_CONSTANT = "ENUM_CONSTANT";

  /**
   * Deprecated - no longer sent.
   */
  public static final String FIELD = "FIELD";

  /**
   * Deprecated - no longer sent.
   */
  public static final String FIELD_STATIC = "FIELD_STATIC";

  /**
   * Deprecated - no longer sent.
   */
  public static final String FUNCTION = "FUNCTION";

  /**
   * Deprecated - no longer sent.
   */
  public static final String FUNCTION_DECLARATION = "FUNCTION_DECLARATION";

  public static final String FUNCTION_TYPE_ALIAS = "FUNCTION_TYPE_ALIAS";

  /**
   * Deprecated - no longer sent.
   */
  public static final String GETTER_DECLARATION = "GETTER_DECLARATION";

  public static final String IDENTIFIER_DEFAULT = "IDENTIFIER_DEFAULT";

  public static final String IMPORT_PREFIX = "IMPORT_PREFIX";

  public static final String INSTANCE_FIELD_DECLARATION = "INSTANCE_FIELD_DECLARATION";

  public static final String INSTANCE_FIELD_REFERENCE = "INSTANCE_FIELD_REFERENCE";

  public static final String INSTANCE_GETTER_DECLARATION = "INSTANCE_GETTER_DECLARATION";

  public static final String INSTANCE_GETTER_REFERENCE = "INSTANCE_GETTER_REFERENCE";

  public static final String INSTANCE_METHOD_DECLARATION = "INSTANCE_METHOD_DECLARATION";

  public static final String INSTANCE_METHOD_REFERENCE = "INSTANCE_METHOD_REFERENCE";

  public static final String INSTANCE_METHOD_TEAR_OFF = "INSTANCE_METHOD_TEAR_OFF";

  public static final String INSTANCE_SETTER_DECLARATION = "INSTANCE_SETTER_DECLARATION";

  public static final String INSTANCE_SETTER_REFERENCE = "INSTANCE_SETTER_REFERENCE";

  public static final String INVALID_STRING_ESCAPE = "INVALID_STRING_ESCAPE";

  public static final String KEYWORD = "KEYWORD";

  public static final String LABEL = "LABEL";

  public static final String LIBRARY_NAME = "LIBRARY_NAME";

  public static final String LITERAL_BOOLEAN = "LITERAL_BOOLEAN";

  public static final String LITERAL_DOUBLE = "LITERAL_DOUBLE";

  public static final String LITERAL_INTEGER = "LITERAL_INTEGER";

  public static final String LITERAL_LIST = "LITERAL_LIST";

  public static final String LITERAL_MAP = "LITERAL_MAP";

  public static final String LITERAL_STRING = "LITERAL_STRING";

  public static final String LOCAL_FUNCTION_DECLARATION = "LOCAL_FUNCTION_DECLARATION";

  public static final String LOCAL_FUNCTION_REFERENCE = "LOCAL_FUNCTION_REFERENCE";

  public static final String LOCAL_FUNCTION_TEAR_OFF = "LOCAL_FUNCTION_TEAR_OFF";

  /**
   * Deprecated - no longer sent.
   */
  public static final String LOCAL_VARIABLE = "LOCAL_VARIABLE";

  public static final String LOCAL_VARIABLE_DECLARATION = "LOCAL_VARIABLE_DECLARATION";

  public static final String LOCAL_VARIABLE_REFERENCE = "LOCAL_VARIABLE_REFERENCE";

  /**
   * Deprecated - no longer sent.
   */
  public static final String METHOD = "METHOD";

  /**
   * Deprecated - no longer sent.
   */
  public static final String METHOD_DECLARATION = "METHOD_DECLARATION";

  /**
   * Deprecated - no longer sent.
   */
  public static final String METHOD_DECLARATION_STATIC = "METHOD_DECLARATION_STATIC";

  /**
   * Deprecated - no longer sent.
   */
  public static final String METHOD_STATIC = "METHOD_STATIC";

  /**
   * Deprecated - no longer sent.
   */
  public static final String PARAMETER = "PARAMETER";

  /**
   * Deprecated - no longer sent.
   */
  public static final String SETTER_DECLARATION = "SETTER_DECLARATION";

  /**
   * Deprecated - no longer sent.
   */
  public static final String TOP_LEVEL_VARIABLE = "TOP_LEVEL_VARIABLE";

  public static final String PARAMETER_DECLARATION = "PARAMETER_DECLARATION";

  public static final String PARAMETER_REFERENCE = "PARAMETER_REFERENCE";

  public static final String STATIC_FIELD_DECLARATION = "STATIC_FIELD_DECLARATION";

  public static final String STATIC_GETTER_DECLARATION = "STATIC_GETTER_DECLARATION";

  public static final String STATIC_GETTER_REFERENCE = "STATIC_GETTER_REFERENCE";

  public static final String STATIC_METHOD_DECLARATION = "STATIC_METHOD_DECLARATION";

  public static final String STATIC_METHOD_REFERENCE = "STATIC_METHOD_REFERENCE";

  public static final String STATIC_METHOD_TEAR_OFF = "STATIC_METHOD_TEAR_OFF";

  public static final String STATIC_SETTER_DECLARATION = "STATIC_SETTER_DECLARATION";

  public static final String STATIC_SETTER_REFERENCE = "STATIC_SETTER_REFERENCE";

  public static final String TOP_LEVEL_FUNCTION_DECLARATION = "TOP_LEVEL_FUNCTION_DECLARATION";

  public static final String TOP_LEVEL_FUNCTION_REFERENCE = "TOP_LEVEL_FUNCTION_REFERENCE";

  public static final String TOP_LEVEL_FUNCTION_TEAR_OFF = "TOP_LEVEL_FUNCTION_TEAR_OFF";

  public static final String TOP_LEVEL_GETTER_DECLARATION = "TOP_LEVEL_GETTER_DECLARATION";

  public static final String TOP_LEVEL_GETTER_REFERENCE = "TOP_LEVEL_GETTER_REFERENCE";

  public static final String TOP_LEVEL_SETTER_DECLARATION = "TOP_LEVEL_SETTER_DECLARATION";

  public static final String TOP_LEVEL_SETTER_REFERENCE = "TOP_LEVEL_SETTER_REFERENCE";

  public static final String TOP_LEVEL_VARIABLE_DECLARATION = "TOP_LEVEL_VARIABLE_DECLARATION";

  public static final String TYPE_ALIAS = "TYPE_ALIAS";

  public static final String TYPE_NAME_DYNAMIC = "TYPE_NAME_DYNAMIC";

  public static final String TYPE_PARAMETER = "TYPE_PARAMETER";

  public static final String UNRESOLVED_INSTANCE_MEMBER_REFERENCE = "UNRESOLVED_INSTANCE_MEMBER_REFERENCE";

  public static final String VALID_STRING_ESCAPE = "VALID_STRING_ESCAPE";

}
