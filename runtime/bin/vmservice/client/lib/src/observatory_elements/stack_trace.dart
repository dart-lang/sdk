// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stack_trace_element;

import 'dart:html';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

@CustomTag('stack-trace')
class StackTraceElement extends ObservatoryElement {
  @published Map trace = toObservable({});

  StackTraceElement.created() : super.created();

  void refresh(var done) {
    var url = app.locationManager.currentIsolateRelativeLink('stacktrace');
    app.requestManager.requestMap(url).then((map) {
        trace = map;
    }).catchError((e, trace) {
        Logger.root.severe('Error while reloading stack trace: $e\n$trace');
    }).whenComplete(done);
  }
}
