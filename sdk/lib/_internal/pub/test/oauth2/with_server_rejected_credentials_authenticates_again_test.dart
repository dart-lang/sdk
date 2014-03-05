// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:scheduled_test/scheduled_server.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration('with server-rejected credentials, authenticates again and saves '
      'credentials.json', () {
    d.validPackage.create();
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    server.handle('GET', '/api/packages/versions/new', (request) {
      var response = request.response;
      response.statusCode = 401;
      response.headers.set('www-authenticate', 'Bearer error="invalid_token",'
          ' error_description="your token sucks"');
      response.write(JSON.encode({
        'error': {'message': 'your token sucks'}
      }));
      response.close();
    });

    pub.stderr.expect('OAuth2 authorization failed (your token sucks).');
    pub.stdout.expect('Uploading...');
    pub.kill();
  });
}
