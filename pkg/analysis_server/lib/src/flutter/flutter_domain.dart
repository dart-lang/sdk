// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/session.dart';

/// A [RequestHandler] that handles requests in the `flutter` domain.
class FlutterDomainHandler extends AbstractRequestHandler {
  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  FlutterDomainHandler(AnalysisServer server) : super(server);

  /// Implement the 'flutter.getWidgetDescription' request.
  void getWidgetDescription(Request request) async {
    var params = FlutterGetWidgetDescriptionParams.fromRequest(request);
    var file = params.file;
    var offset = params.offset;

    if (server.sendResponseErrorIfInvalidFilePath(request, file)) {
      return;
    }

    var resolvedUnit = await server.getResolvedUnit(file);
    if (resolvedUnit == null) {
      // TODO(scheglov) report error
    }

    var computer = server.flutterWidgetDescriptions;

    FlutterGetWidgetDescriptionResult result;
    try {
      result = await computer.getDescription(
        resolvedUnit,
        offset,
      );
    } on InconsistentAnalysisException {
      server.sendResponse(
        Response(
          request.id,
          error: RequestError(
            RequestErrorCode.FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED,
            'Concurrent modification detected.',
          ),
        ),
      );
      return;
    }

    if (result == null) {
      server.sendResponse(
        Response(
          request.id,
          error: RequestError(
            RequestErrorCode.FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET,
            'No Flutter widget at the given location.',
          ),
        ),
      );
      return;
    }

    server.sendResponse(
      result.toResponse(request.id),
    );
  }

  @override
  Response handleRequest(Request request) {
    try {
      var requestName = request.method;
      if (requestName == FLUTTER_REQUEST_GET_WIDGET_DESCRIPTION) {
        getWidgetDescription(request);
        return Response.DELAYED_RESPONSE;
      }
      if (requestName == FLUTTER_REQUEST_SET_WIDGET_PROPERTY_VALUE) {
        setPropertyValue(request);
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

  /// Implement the 'flutter.setPropertyValue' request.
  void setPropertyValue(Request request) async {
    var params = FlutterSetWidgetPropertyValueParams.fromRequest(request);

    var result = await server.flutterWidgetDescriptions.setPropertyValue(
      params.id,
      params.value,
    );

    if (result.errorCode != null) {
      server.sendResponse(
        Response(
          request.id,
          error: RequestError(result.errorCode, ''),
        ),
      );
    }

    server.sendResponse(
      FlutterSetWidgetPropertyValueResult(
        result.change,
      ).toResponse(request.id),
    );
  }

  /// Implement the 'flutter.setSubscriptions' request.
  Response setSubscriptions(Request request) {
    var params = FlutterSetSubscriptionsParams.fromRequest(request);
    var subMap =
        mapMap<FlutterService, List<String>, FlutterService, Set<String>>(
            params.subscriptions,
            valueCallback: (List<String> subscriptions) =>
                subscriptions.toSet());
    server.setFlutterSubscriptions(subMap);
    return FlutterSetSubscriptionsResult().toResponse(request.id);
  }
}
