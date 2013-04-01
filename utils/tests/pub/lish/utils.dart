// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lish.utils;

import 'dart:io';
import 'dart:json' as json;

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';

import '../../../pub/io.dart';
import '../test_pub.dart';

void handleUploadForm(ScheduledServer server, [Map body]) {
  server.handle('GET', '/packages/versions/new.json', (request) {
    return server.url.then((url) {
      expect(request.headers.value('authorization'),
          equals('Bearer access token'));

      if (body == null) {
        body = {
          'url': url.resolve('/upload').toString(),
          'fields': {
            'field1': 'value1',
            'field2': 'value2'
          }
        };
      }

      request.response.headers.contentType =
          new ContentType("application", "json");
      request.response.write(json.stringify(body));
      request.response.close();
    });
  });
}

void handleUpload(ScheduledServer server) {
  server.handle('POST', '/upload', (request) {
    // TODO(nweiz): Once a multipart/form-data parser in Dart exists, validate
    // that the request body is correctly formatted. See issue 6952.
    return drainStream(request).then((_) {
      return server.url;
    }).then((url) {
      request.response.statusCode = 302;
      request.response.headers.set(
          'location', url.resolve('/create').toString());
      request.response.close();
    });
  });
}

