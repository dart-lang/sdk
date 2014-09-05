// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library microlytics.html_channels;

import 'dart:html';
import 'channels.dart';

class HttpRequestChannel extends Channel {
  void sendData(String data) {
    HttpRequest.request(ANALYTICS_URL, method: "POST", sendData: data);
  }
}
