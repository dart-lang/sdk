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
 * An enumeration of the kinds of server long entries.
 *
 * @coverage dart.server.generated.types
 */
public class ServerLogEntryKind {

  /**
   * A notification from the server, such as "analysis.highlights". The "data" field contains a JSON
   * object with abbreviated notification.
   */
  public static final String NOTIFICATION = "NOTIFICATION";

  /**
   * Arbitrary string, describing some event that happened in the server, e.g. starting a file
   * analysis, and details which files were accessed. These entries are not structured, but provide
   * context information about requests and notification, and can be related by "time" for further
   * manual analysis.
   */
  public static final String RAW = "RAW";

  /**
   * A request from the client, as the server views it, e.g. "edit.getAssists". The "data" field
   * contains a JSON object with abbreviated request.
   */
  public static final String REQUEST = "REQUEST";

  /**
   * Various counters and measurements related to execution of a request. The "data" field contains a
   * JSON object with following fields:
   *
   * - "id" - the id of the request - copied from the request.
   * - "method" - the method of the request, e.g. "edit.getAssists".
   * - "clientRequestTime" - the time (milliseconds since epoch) at which the client made the request
   *   - copied from the request.
   * - "serverRequestTime" - the time (milliseconds since epoch) at which the server received and
   *   decoded the JSON request.
   * - "responseTime" - the time (milliseconds since epoch) at which the server created the response
   *   to be encoded into JSON and sent to the client.
   */
  public static final String RESPONSE = "RESPONSE";

}
