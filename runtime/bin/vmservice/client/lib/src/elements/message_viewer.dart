// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library message_viewer_element;

import 'package:logging/logging.dart';
import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

@CustomTag('message-viewer')
class MessageViewerElement extends ObservatoryElement {
  Map _message;
  @published Map get message => _message;
  @published ObservatoryApplication app;

  @published set message(Map m) {
    if (m == null) {
      Logger.root.info('Viewing null message.');
      return;
    }
    Logger.root.info('Viewing message of type \'${m['type']}\'');
    _message = m;
    notifyPropertyChange(#messageType, "", messageType);
  }

  MessageViewerElement.created() : super.created();

  String get messageType {
    if (message == null || message['type'] == null) {
      return 'Error';
    }
    return message['type'];
  }
}
