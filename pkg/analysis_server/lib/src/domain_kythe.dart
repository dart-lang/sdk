// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/services/kythe/kythe_visitors.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/**
 * Instances of the class [KytheDomainHandler] implement a [RequestHandler]
 * that handles requests in the `kythe` domain.
 */
class KytheDomainHandler implements RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  KytheDomainHandler(this.server);

  /**
   * Implement the `kythe.getKytheEntries` request.
   */
  Future<Null> getKytheEntries(Request request) async {
    String file = new KytheGetKytheEntriesParams.fromRequest(request).file;
    AnalysisResult result = await server.getAnalysisResult(file);
    List<KytheEntry> entries = <KytheEntry>[];
    // TODO(brianwilkerson) Figure out how to get the list of files.
    List<String> files = <String>[];
    result.unit.accept(new KytheDartVisitor([] /*entries*/, file,
        new InheritanceManager(result.libraryElement), result.content));
    server.sendResponse(
        new KytheGetKytheEntriesResult(entries, files).toResponse(request.id));
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == KYTHE_REQUEST_GET_KYTHE_ENTRIES) {
        getKytheEntries(request);
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}
