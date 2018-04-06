// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/flutter/flutter_correction.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';

/**
 * A [RequestHandler] that handles requests in the `flutter` domain.
 */
class FlutterDomainHandler extends AbstractRequestHandler {
  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  FlutterDomainHandler(AnalysisServer server) : super(server);

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName ==
          FLUTTER_REQUEST_GET_CHANGE_ADD_FOR_DESIGN_TIME_CONSTRUCTOR) {
        getChangeAddForDesignTimeConstructor(request);
        return Response.DELAYED_RESPONSE;
      }
      if (requestName == FLUTTER_REQUEST_SET_SUBSCRIPTIONS) {
        return setSubscriptions(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Implement the 'flutter.setSubscriptions' request.
   */
  Response setSubscriptions(Request request) {
    var params = new FlutterSetSubscriptionsParams.fromRequest(request);
    Map<FlutterService, Set<String>> subMap = mapMap(params.subscriptions,
        valueCallback: (List<String> subscriptions) => subscriptions.toSet());
    server.setFlutterSubscriptions(subMap);
    return new FlutterSetSubscriptionsResult().toResponse(request.id);
  }

  /**
   * Implement the 'flutter.getChangeAddForDesignTimeConstructor' request.
   */
  Future getChangeAddForDesignTimeConstructor(Request request) async {
    var params =
        new FlutterGetChangeAddForDesignTimeConstructorParams.fromRequest(
            request);
    String file = params.file;
    int offset = params.offset;

    ResolveResult result = await server.getAnalysisResult(file);
    if (result != null) {
      var corrections = new FlutterCorrections(
          file: file,
          fileContent: result.content,
          selectionOffset: offset,
          selectionLength: 0,
          session: result.session,
          unit: result.unit);
      SourceChange change = await corrections.addForDesignTimeConstructor();
      if (change != null) {
        server.sendResponse(
            new FlutterGetChangeAddForDesignTimeConstructorResult(change)
                .toResponse(request.id));
        return;
      }
    }
    server.sendResponse(
        new Response.invalidParameter(request, 'file', 'No change'));
  }
}
