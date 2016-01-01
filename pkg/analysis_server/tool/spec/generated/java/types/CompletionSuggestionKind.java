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
 * An enumeration of the kinds of elements that can be included in a completion suggestion.
 *
 * @coverage dart.server.generated.types
 */
public class CompletionSuggestionKind {

  /**
   * A list of arguments for the method or function that is being invoked. For this suggestion kind,
   * the completion field is a textual representation of the invocation and the parameterNames,
   * parameterTypes, and requiredParameterCount attributes are defined.
   */
  public static final String ARGUMENT_LIST = "ARGUMENT_LIST";

  public static final String IMPORT = "IMPORT";

  /**
   * The element identifier should be inserted at the completion location. For example "someMethod"
   * in import 'myLib.dart' show someMethod; . For suggestions of this kind, the element attribute is
   * defined and the completion field is the element's identifier.
   */
  public static final String IDENTIFIER = "IDENTIFIER";

  /**
   * The element is being invoked at the completion location. For example, "someMethod" in
   * x.someMethod(); . For suggestions of this kind, the element attribute is defined and the
   * completion field is the element's identifier.
   */
  public static final String INVOCATION = "INVOCATION";

  /**
   * A keyword is being suggested. For suggestions of this kind, the completion is the keyword.
   */
  public static final String KEYWORD = "KEYWORD";

  /**
   * A named argument for the current callsite is being suggested. For suggestions of this kind, the
   * completion is the named argument identifier including a trailing ':' and space.
   */
  public static final String NAMED_ARGUMENT = "NAMED_ARGUMENT";

  public static final String OPTIONAL_ARGUMENT = "OPTIONAL_ARGUMENT";

  public static final String PARAMETER = "PARAMETER";

}
