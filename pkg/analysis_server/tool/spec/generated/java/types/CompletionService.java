/*
 * Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * This file has been automatically generated. Please do not edit it manually.
 * To regenerate the file, use the script "pkg/analysis_server/tool/spec/generate_files".
 */
package org.dartlang.analysis.server.protocol;

/**
 * An enumeration of the completion services to which a client can subscribe.
 *
 * @coverage dart.server.generated.types
 */
public class CompletionService {

  /**
   * The client will receive notifications once subscribed with completion suggestion sets from the
   * libraries of interest. The client should keep an up-to-date record of these in memory so that it
   * will be able to union these candidates with other completion suggestions when applicable at
   * completion time.
   */
  public static final String AVAILABLE_SUGGESTION_SETS = "AVAILABLE_SUGGESTION_SETS";

}
