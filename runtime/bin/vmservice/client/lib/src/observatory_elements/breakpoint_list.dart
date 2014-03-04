// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library breakpoint_list_element;

import 'observatory_element.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

@CustomTag('breakpoint-list')
class BreakpointListElement extends ObservatoryElement {
  @published Map msg = toObservable({});

  BreakpointListElement.created() : super.created();

  void refresh(var done) {
    var url = app.locationManager.currentIsolateRelativeLink("breakpoints");
    app.requestManager.requestMap(url).then((map) {
        msg = map;
    }).catchError((e, trace) {
          Logger.root.severe('Error while refreshing breakpoint-list: $e\n$trace');
    }).whenComplete(done);
  }
}
