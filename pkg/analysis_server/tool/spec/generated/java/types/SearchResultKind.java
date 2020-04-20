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
