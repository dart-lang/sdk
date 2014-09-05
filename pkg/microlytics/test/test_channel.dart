// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library microlytics.test_channel;

import 'package:microlytics/channels.dart';

class TestChannel extends Channel {
  List<String> _channelLog = [];

  void sendData(String data) {
    _channelLog.add(data);
  }

  bool contains(String data) {
    return _channelLog.contains(data);
  }
}
