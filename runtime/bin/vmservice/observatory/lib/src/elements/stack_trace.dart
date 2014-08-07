// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stack_trace_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';
import 'package:observatory/service.dart';

@CustomTag('stack-trace')
class StackTraceElement extends ObservatoryElement {
  @published ServiceMap trace;

  StackTraceElement.created() : super.created();

  void refresh(var done) {
    trace.reload().whenComplete(done);
  }
}
