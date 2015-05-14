// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_reconnect_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

@CustomTag('isolate-reconnect')
class IsolateReconnectElement extends ObservatoryElement {
  IsolateReconnectElement.created() : super.created();

  get missingIsolateId {
    return app.locationManager.uri.queryParameters['originalIsolateId'];
  }

  linkToContinueIn(isolate) {
    var parameters = new Map.from(app.locationManager.uri.queryParameters);
    parameters['isolateId'] = isolate.id;
    parameters.remove('originalIsolateId');
    var path = parameters.remove('originalPath');
    path = "/$path";
    var generatedUri = new Uri(path: path, queryParameters: parameters);
    return app.locationManager.makeLink(generatedUri.toString());
  }
}
