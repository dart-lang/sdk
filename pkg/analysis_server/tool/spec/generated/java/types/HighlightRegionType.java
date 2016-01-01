/*
 * Copyright (c) 2015, the Dart project authors.
 *
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 *
 * This file has been automatically generated.  Please do not edit it manually.
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

  public static final String DIRECTIVE = "DIRECTIVE";

  /**
   * Only for version 1 of highlight.
   */
  public static final String DYNAMIC_TYPE = "DYNAMIC_TYPE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String DYNAMIC_LOCAL_VARIABLE_DECLARATION = "DYNAMIC_LOCAL_VARIABLE_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String DYNAMIC_LOCAL_VARIABLE_REFERENCE = "DYNAMIC_LOCAL_VARIABLE_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String DYNAMIC_PARAMETER_DECLARATION = "DYNAMIC_PARAMETER_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String DYNAMIC_PARAMETER_REFERENCE = "DYNAMIC_PARAMETER_REFERENCE";

  public static final String ENUM = "ENUM";

  public static final String ENUM_CONSTANT = "ENUM_CONSTANT";

  /**
   * Only for version 1 of highlight.
   */
  public static final String FIELD = "FIELD";

  /**
   * Only for version 1 of highlight.
   */
  public static final String FIELD_STATIC = "FIELD_STATIC";

  /**
   * Only for version 1 of highlight.
   */
  public static final String FUNCTION = "FUNCTION";

  /**
   * Only for version 1 of highlight.
   */
  public static final String FUNCTION_DECLARATION = "FUNCTION_DECLARATION";

  public static final String FUNCTION_TYPE_ALIAS = "FUNCTION_TYPE_ALIAS";

  /**
   * Only for version 1 of highlight.
   */
  public static final String GETTER_DECLARATION = "GETTER_DECLARATION";

  public static final String IDENTIFIER_DEFAULT = "IDENTIFIER_DEFAULT";

  public static final String IMPORT_PREFIX = "IMPORT_PREFIX";

  /**
   * Only for version 2 of highlight.
   */
  public static final String INSTANCE_FIELD_DECLARATION = "INSTANCE_FIELD_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String INSTANCE_FIELD_REFERENCE = "INSTANCE_FIELD_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String INSTANCE_GETTER_DECLARATION = "INSTANCE_GETTER_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String INSTANCE_GETTER_REFERENCE = "INSTANCE_GETTER_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String INSTANCE_METHOD_DECLARATION = "INSTANCE_METHOD_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String INSTANCE_METHOD_REFERENCE = "INSTANCE_METHOD_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String INSTANCE_SETTER_DECLARATION = "INSTANCE_SETTER_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String INSTANCE_SETTER_REFERENCE = "INSTANCE_SETTER_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String INVALID_STRING_ESCAPE = "INVALID_STRING_ESCAPE";

  public static final String KEYWORD = "KEYWORD";

  public static final String LABEL = "LABEL";

  /**
   * Only for version 2 of highlight.
   */
  public static final String LIBRARY_NAME = "LIBRARY_NAME";

  public static final String LITERAL_BOOLEAN = "LITERAL_BOOLEAN";

  public static final String LITERAL_DOUBLE = "LITERAL_DOUBLE";

  public static final String LITERAL_INTEGER = "LITERAL_INTEGER";

  public static final String LITERAL_LIST = "LITERAL_LIST";

  public static final String LITERAL_MAP = "LITERAL_MAP";

  public static final String LITERAL_STRING = "LITERAL_STRING";

  /**
   * Only for version 2 of highlight.
   */
  public static final String LOCAL_FUNCTION_DECLARATION = "LOCAL_FUNCTION_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String LOCAL_FUNCTION_REFERENCE = "LOCAL_FUNCTION_REFERENCE";

  /**
   * Only for version 1 of highlight.
   */
  public static final String LOCAL_VARIABLE = "LOCAL_VARIABLE";

  public static final String LOCAL_VARIABLE_DECLARATION = "LOCAL_VARIABLE_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String LOCAL_VARIABLE_REFERENCE = "LOCAL_VARIABLE_REFERENCE";

  /**
   * Only for version 1 of highlight.
   */
  public static final String METHOD = "METHOD";

  /**
   * Only for version 1 of highlight.
   */
  public static final String METHOD_DECLARATION = "METHOD_DECLARATION";

  /**
   * Only for version 1 of highlight.
   */
  public static final String METHOD_DECLARATION_STATIC = "METHOD_DECLARATION_STATIC";

  /**
   * Only for version 1 of highlight.
   */
  public static final String METHOD_STATIC = "METHOD_STATIC";

  /**
   * Only for version 1 of highlight.
   */
  public static final String PARAMETER = "PARAMETER";

  /**
   * Only for version 1 of highlight.
   */
  public static final String SETTER_DECLARATION = "SETTER_DECLARATION";

  /**
   * Only for version 1 of highlight.
   */
  public static final String TOP_LEVEL_VARIABLE = "TOP_LEVEL_VARIABLE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String PARAMETER_DECLARATION = "PARAMETER_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String PARAMETER_REFERENCE = "PARAMETER_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String STATIC_FIELD_DECLARATION = "STATIC_FIELD_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String STATIC_GETTER_DECLARATION = "STATIC_GETTER_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String STATIC_GETTER_REFERENCE = "STATIC_GETTER_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String STATIC_METHOD_DECLARATION = "STATIC_METHOD_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String STATIC_METHOD_REFERENCE = "STATIC_METHOD_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String STATIC_SETTER_DECLARATION = "STATIC_SETTER_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String STATIC_SETTER_REFERENCE = "STATIC_SETTER_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String TOP_LEVEL_FUNCTION_DECLARATION = "TOP_LEVEL_FUNCTION_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String TOP_LEVEL_FUNCTION_REFERENCE = "TOP_LEVEL_FUNCTION_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String TOP_LEVEL_GETTER_DECLARATION = "TOP_LEVEL_GETTER_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String TOP_LEVEL_GETTER_REFERENCE = "TOP_LEVEL_GETTER_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String TOP_LEVEL_SETTER_DECLARATION = "TOP_LEVEL_SETTER_DECLARATION";

  /**
   * Only for version 2 of highlight.
   */
  public static final String TOP_LEVEL_SETTER_REFERENCE = "TOP_LEVEL_SETTER_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String TOP_LEVEL_VARIABLE_DECLARATION = "TOP_LEVEL_VARIABLE_DECLARATION";

  public static final String TYPE_NAME_DYNAMIC = "TYPE_NAME_DYNAMIC";

  public static final String TYPE_PARAMETER = "TYPE_PARAMETER";

  /**
   * Only for version 2 of highlight.
   */
  public static final String UNRESOLVED_INSTANCE_MEMBER_REFERENCE = "UNRESOLVED_INSTANCE_MEMBER_REFERENCE";

  /**
   * Only for version 2 of highlight.
   */
  public static final String VALID_STRING_ESCAPE = "VALID_STRING_ESCAPE";

}
