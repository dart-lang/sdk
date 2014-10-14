// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library oauth2.utils;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../lib/src/utils.dart';

void authorizePub(ScheduledProcess pub, ScheduledServer server,
    [String accessToken = "access token"]) {
  pub.stdout.expect(
      'Pub needs your authorization to upload packages on your ' 'behalf.');

  schedule(() {
    return pub.stdout.next().then((line) {
      var match =
          new RegExp(r'[?&]redirect_uri=([0-9a-zA-Z.%+-]+)[$&]').firstMatch(line);
      expect(match, isNotNull);

      var redirectUrl = Uri.parse(Uri.decodeComponent(match.group(1)));
      redirectUrl = addQueryParameters(redirectUrl, {
        'code': 'access code'
      });
      return (new http.Request('GET', redirectUrl)..followRedirects =
          false).send();
    }).then((response) {
      expect(
          response.headers['location'],
          equals('http://pub.dartlang.org/authorized'));
    });
  });

  handleAccessTokenRequest(server, accessToken);
}

void handleAccessTokenRequest(ScheduledServer server, String accessToken) {
  server.handle('POST', '/token', (request) {
    return request.readAsString().then((body) {
      expect(body, matches(new RegExp(r'(^|&)code=access\+code(&|$)')));

      return new shelf.Response.ok(JSON.encode({
        "access_token": accessToken,
        "token_type": "bearer"
      }), headers: {
        'content-type': 'application/json'
      });
    });
  });
}

