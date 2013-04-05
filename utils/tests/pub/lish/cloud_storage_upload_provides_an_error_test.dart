// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:json' as json;

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';

import '../../../pub/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  setUp(d.validPackage.create);

  integration('cloud storage upload provides an error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);

    server.handle('POST', '/upload', (request) {
      return drainStream(request).then((_) {
        request.response.statusCode = 400;
        request.response.headers.contentType =
            new ContentType('application', 'xml');
        request.response.write('<Error><Message>Your request sucked.'
            '</Message></Error>');
        request.response.close();
      });
    });

    // TODO(nweiz): This should use the server's error message once the client
    // can parse the XML.
    expect(pub.nextErrLine(),
        completion(equals('Failed to upload the package.')));
    pub.shouldExit(1);
  });
}
