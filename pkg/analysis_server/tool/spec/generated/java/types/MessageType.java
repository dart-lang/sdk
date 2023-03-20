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
 * The type of a message that the server is requesting the client to display to the user. The type
 * can be used by the client to control the way in which the message is displayed.
 *
 * @coverage dart.server.generated.types
 */
public class MessageType {

  /**
   * The message is an error message.
   */
  public static final String ERROR = "ERROR";

  /**
   * The message is a warning message.
   */
  public static final String WARNING = "WARNING";

  /**
   * The message is an informational message.
   */
  public static final String INFO = "INFO";

  /**
   * The message is a log message.
   */
  public static final String LOG = "LOG";

}
