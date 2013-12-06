// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_dartium;

import 'dart:isolate';
import 'vmservice.dart';

// The receive port that isolate startup / shutdown messages are delivered on.
RawReceivePort _receivePort;
// The receive port that service request messages are delivered on.
RawReceivePort _requestPort;

// The native method that is called to post the response back to DevTools.
void postResponse(String response, int cookie) native "PostResponse";

void handleRequest(service, String uri, cookie) {
  var serviceRequest = new ServiceRequest();
  var r = serviceRequest.parse(Uri.parse(uri));
  if (!r) {
    // Did not understand the request uri.
    serviceRequest.setErrorResponse('Invalid request uri: ${uri}');
  } else {
    var f = service.runningIsolates.route(serviceRequest);
    if (f != null) {
      f.then((_) {
        postResponse(serviceRequest.response, cookie);
      }).catchError((e) { });
      return;
    } else {
      // Nothing responds to this type of request.
      serviceRequest.setErrorResponse('No route for: $uri');
    }
  }
  postResponse(serviceRequest.response, cookie);
}

main() {
  // Create VmService.
  var service = new VMService();
  _receivePort = service.receivePort;
  _requestPort = new RawReceivePort((message) {
    if (message == null) {
      return;
    }
    if (message is! List) {
      return;
    }
    if (message.length != 2) {
      return;
    }
    var uri = message[0];
    if (uri is! String) {
      return;
    }
    var cookie = message[1];
    handleRequest(service, uri, cookie);
  });
}
