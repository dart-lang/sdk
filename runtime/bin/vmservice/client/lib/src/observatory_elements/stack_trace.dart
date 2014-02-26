// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stack_trace_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

@CustomTag('stack-trace')
class StackTraceElement extends ObservatoryElement {
  @published Map trace = toObservable({});

  StackTraceElement.created() : super.created();

  void refresh(Event e, var detail, Node target) {
    var url = app.locationManager.currentIsolateRelativeLink('stacktrace');
    app.requestManager.requestMap(url).then((map) {
        trace = map;
    }).catchError((e, trace) {
        Logger.root.severe('Error while reloading stack trace: $e\n$trace');
    });
  }
}
