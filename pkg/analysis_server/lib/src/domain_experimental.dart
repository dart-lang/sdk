// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library src.domain_experimental;

import 'dart:core' hide Resource;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';

/**
 * Instances of the class [ExperimentalDomainHandler] implement a
 * [RequestHandler] that handles requests in the `experimental` domain.
 */
class ExperimentalDomainHandler implements RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * The name of the request used to get diagnostic information.
   */
  static const String EXPERIMENTAL_DIAGNOSTICS = 'experimental.diagnostics';

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  ExperimentalDomainHandler(this.server);

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == EXPERIMENTAL_DIAGNOSTICS) {
        return computeDiagnostics(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Implement the `experimental.diagnostics` request.
   */
  Response computeDiagnostics(Request request) {
    return new Response.unknownRequest(request);
  }
}
