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
 * An enumeration of the kinds of FlutterOutline elements. The list of kinds might be expanded with
 * time, clients must be able to handle new kinds in some general way.
 *
 * @coverage dart.server.generated.types
 */
public class FlutterOutlineKind {

  /**
   * A dart element declaration.
   */
  public static final String DART_ELEMENT = "DART_ELEMENT";

  /**
   * A generic Flutter element, without additional information.
   */
  public static final String GENERIC = "GENERIC";

  /**
   * A new instance creation.
   */
  public static final String NEW_INSTANCE = "NEW_INSTANCE";

  /**
   * An invocation of a method, a top-level function, a function expression, etc.
   */
  public static final String INVOCATION = "INVOCATION";

  /**
   * A reference to a local variable, or a field.
   */
  public static final String VARIABLE = "VARIABLE";

  /**
   * The parent node has a required Widget. The node works as a placeholder child to drop a new
   * Widget to.
   */
  public static final String PLACEHOLDER = "PLACEHOLDER";

}
