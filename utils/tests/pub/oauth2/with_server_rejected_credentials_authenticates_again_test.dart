// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:json' as json;

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';

import '../../../pub/io.dart';
import '../../../pub/utils.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration('with server-rejected credentials, authenticates again and saves '
      'credentials.json', () {
    d.validPackage.create();
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    server.handle('GET', '/packages/versions/new.json', (request) {
      var response = request.response;
      response.statusCode = 401;
      response.headers.set('www-authenticate', 'Bearer error="invalid_token",'
          ' error_description="your token sucks"');
      response.write(json.stringify({
        'error': {'message': 'your token sucks'}
      }));
      response.close();
    });

    expect(pub.nextErrLine(), completion(equals('OAuth2 authorization failed '
        '(your token sucks).')));
    // TODO(rnystrom): The confirm line is run together with this one because
    // in normal usage, the user will have entered a newline on stdin which
    // gets echoed to the terminal. Do something better here?
    expect(pub.nextLine(), completion(equals(
        'Looks great! Are you ready to upload your package (y/n)? '
        'Pub needs your authorization to upload packages on your behalf.')));
    pub.kill();
  });
}
