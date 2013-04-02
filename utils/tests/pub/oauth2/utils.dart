// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library oauth2.utils;

import 'dart:io';
import 'dart:json' as json;
import 'dart:uri';

import 'package:http/http.dart' as http;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';

import '../../../pub/io.dart';
import '../../../pub/utils.dart';
import '../test_pub.dart';

void authorizePub(ScheduledProcess pub, ScheduledServer server,
    [String accessToken="access token"]) {
  // TODO(rnystrom): The confirm line is run together with this one because
  // in normal usage, the user will have entered a newline on stdin which
  // gets echoed to the terminal. Do something better here?
  expect(pub.nextLine(), completion(equals(
      'Looks great! Are you ready to upload your package (y/n)? '
      'Pub needs your authorization to upload packages on your behalf.')));

  expect(pub.nextLine().then((line) {
    var match = new RegExp(r'[?&]redirect_uri=([0-9a-zA-Z%+-]+)[$&]')
        .firstMatch(line);
    expect(match, isNotNull);

    var redirectUrl = Uri.parse(decodeUriComponent(match.group(1)));
    redirectUrl = addQueryParameters(redirectUrl, {'code': 'access code'});
    return (new http.Request('GET', redirectUrl)..followRedirects = false)
      .send();
  }).then((response) {
    expect(response.headers['location'],
        equals('http://pub.dartlang.org/authorized'));
  }), completes);

  handleAccessTokenRequest(server, accessToken);
}

void handleAccessTokenRequest(ScheduledServer server, String accessToken) {
  server.handle('POST', '/token', (request) {
    return new ByteStream(request).toBytes().then((bytes) {
      var body = new String.fromCharCodes(bytes);
      expect(body, matches(new RegExp(r'(^|&)code=access\+code(&|$)')));

      request.response.headers.contentType =
          new ContentType("application", "json");
      request.response.write(json.stringify({
        "access_token": accessToken,
        "token_type": "bearer"
      }));
      request.response.close();
    });
  });
}

