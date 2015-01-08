// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library breakpoint_list_element;

import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

// TODO(turnidge): Is a breakpoint list associated with a VM or an isolate?
@CustomTag('breakpoint-list')
class BreakpointListElement extends ObservatoryElement {
  @published ServiceMap msg;

  BreakpointListElement.created() : super.created();

  void refresh(var done) {
    msg.reload().whenComplete(done);
  }
}
