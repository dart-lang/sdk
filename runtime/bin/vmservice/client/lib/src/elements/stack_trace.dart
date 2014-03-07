// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stack_trace_element;

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'isolate_element.dart';

@CustomTag('stack-trace')
class StackTraceElement extends IsolateElement {
  @published Map trace = toObservable({});

  StackTraceElement.created() : super.created();

  void refresh(var done) {
    isolate.getMap('stacktrace').then((map) {
        trace = map;
    }).catchError((e, trace) {
        Logger.root.severe('Error while reloading stack trace: $e\n$trace');
    }).whenComplete(done);
  }
}
