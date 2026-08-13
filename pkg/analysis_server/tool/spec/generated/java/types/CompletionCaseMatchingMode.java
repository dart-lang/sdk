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
 * An enumeration of the character case matching modes that the user may set in the client.
 *
 * @coverage dart.server.generated.types
 */
public class CompletionCaseMatchingMode {

  /**
   * Match the first character case only when filtering completions, the default for this
   * enumeration.
   */
  public static final String FIRST_CHAR = "FIRST_CHAR";

  /**
   * Match all character cases when filtering completion lists.
   */
  public static final String ALL_CHARS = "ALL_CHARS";

  /**
   * Do not match character cases when filtering completion lists.
   */
  public static final String NONE = "NONE";

}
