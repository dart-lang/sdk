// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testrunner_test;

import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';

main() {
  var get = (String what, int code, String text) {
    var c = new Completer();
    HttpClient client = new HttpClient();
    client
        .getUrl(Uri.parse("http://127.0.0.1:3456/$what"))
        .then((HttpClientRequest request) {
      // Prepare the request then call close on it to send it.
      return request.close();
    }).then((HttpClientResponse response) {
      // Process the response.
      expect(response.statusCode, code);
      var sb = new StringBuffer();
      response.transform(UTF8.decoder).listen((data) {
        sb.write(data);
      }, onDone: () {
        expect(sb.toString(), text);
        c.complete();
      });
    });
    return c.future;
  };
  test('test1', () {
    return get('test.txt', 200, "Hello world!\n");
  });
  test('test2', () {
    return get('fail.txt', 404, "");
  });
}
