// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library log_view_element;

import 'observatory_element.dart';
import 'package:observatory/service.dart';

import 'package:polymer/polymer.dart';

@CustomTag('log-entry')
class LogEntryElement extends ObservatoryElement {
  @published ServiceMap entry;

  @observable String time;
  @observable String message;

  entryChanged(oldValue) {
    var t = new DateTime.fromMillisecondsSinceEpoch(entry['time']);
    time = '${t.hour}:${t.minute}:${t.second}';
    message = entry['message'];
  }

  LogEntryElement.created() : super.created();
}



@CustomTag('log-view')
class LogViewElement extends ObservatoryElement {
  @published ServiceMap log;
  LogViewElement.created() : super.created();
}
