// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/handler/legacy/kythe_get_kythe_entries.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// Instances of the class [KytheDomainHandler] implement a [RequestHandler]
/// that handles requests in the `kythe` domain.
class KytheDomainHandler extends AbstractRequestHandler {
  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  KytheDomainHandler(AnalysisServer server) : super(server);

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    try {
      var requestName = request.method;
      if (requestName == KYTHE_REQUEST_GET_KYTHE_ENTRIES) {
        KytheGetKytheEntriesHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}
