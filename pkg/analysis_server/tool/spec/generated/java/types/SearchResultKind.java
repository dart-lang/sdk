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
 * An enumeration of the kinds of search results returned by the search domain.
 *
 * @coverage dart.server.generated.types
 */
public class SearchResultKind {

  /**
   * The declaration of an element.
   */
  public static final String DECLARATION = "DECLARATION";

  /**
   * The invocation of a function or method.
   */
  public static final String INVOCATION = "INVOCATION";

  /**
   * A reference to a field, parameter or variable where it is being read.
   */
  public static final String READ = "READ";

  /**
   * A reference to a field, parameter or variable where it is being read and written.
   */
  public static final String READ_WRITE = "READ_WRITE";

  /**
   * A reference to an element.
   */
  public static final String REFERENCE = "REFERENCE";

  /**
   * Some other kind of search result.
   */
  public static final String UNKNOWN = "UNKNOWN";

  /**
   * A reference to a field, parameter or variable where it is being written.
   */
  public static final String WRITE = "WRITE";

}
