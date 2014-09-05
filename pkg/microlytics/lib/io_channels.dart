// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library microlytics.io_channels;

import 'dart:io';
import 'channels.dart';

class HttpClientChannel extends Channel {
  void sendData(String data) {
    HttpClient client = new HttpClient();
    client.postUrl(Uri.parse(ANALYTICS_URL)).then((HttpClientRequest req) {
      req.write(data);
      return req.close();
    }).then((HttpClientResponse response) {
      response.drain();
    });
  }
}

