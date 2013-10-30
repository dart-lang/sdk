// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library message_viewer_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

@CustomTag('message-viewer')
class MessageViewerElement extends ObservatoryElement {
  Map _message;
  @published Map get message => _message;

  @published set message(Map m) {
    _message = m;
    this.notifyPropertyChange(#messageType, null, null);
    this.notifyPropertyChange(#members, null, null);
  }

  String get messageType {
    if (message == null || message['type'] == null) {
      return 'Error';
    }
    return message['type'];
  }

  List<Map> get members {
    if (message == null || message['members'] == null) {
      return [];
    }
    return message['members'];
  }
}
