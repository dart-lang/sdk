// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/handler/legacy/flutter_get_widget_description.dart';
import 'package:analysis_server/src/handler/legacy/flutter_set_subscriptions.dart';
import 'package:analysis_server/src/handler/legacy/flutter_set_widget_property_value.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// A [RequestHandler] that handles requests in the `flutter` domain.
class FlutterDomainHandler extends AbstractRequestHandler {
  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  FlutterDomainHandler(super.server);

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    try {
      var requestName = request.method;
      if (requestName == FLUTTER_REQUEST_GET_WIDGET_DESCRIPTION) {
        FlutterGetWidgetDescriptionHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      }
      if (requestName == FLUTTER_REQUEST_SET_WIDGET_PROPERTY_VALUE) {
        FlutterSetWidgetPropertyValueHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      }
      if (requestName == FLUTTER_REQUEST_SET_SUBSCRIPTIONS) {
        FlutterSetSubscriptionsHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}
