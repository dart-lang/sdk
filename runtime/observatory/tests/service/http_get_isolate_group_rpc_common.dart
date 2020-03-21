// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;
import 'package:observatory/service_io.dart' as S;
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

Future<String> getIsolateGroupId(
    io.HttpClient httpClient, Uri serverUri) async {
  // Build the request.
  final pathSegments = <String>[]..addAll(serverUri.pathSegments);
  const method = 'getVM';
  if (pathSegments.isNotEmpty) {
    pathSegments[pathSegments.length - 1] = method;
  } else {
    pathSegments.add(method);
  }
  final requestUri = serverUri.replace(pathSegments: pathSegments);
  final request = await httpClient.getUrl(requestUri);
  final Map response = await (await request.close())
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(json.decoder)
      .first;
  final result = response['result'];
  return result['isolateGroups'][0]['id'];
}

Future<Null> testeeBefore() async {
  print('testee before');
  print(await Service.getInfo());
  // Start the web server.
  final ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
  expect(info.serverUri, isNotNull);
  final httpClient = new io.HttpClient();

  // Build the request.
  final params = <String, String>{
    'isolateGroupId': await getIsolateGroupId(httpClient, info.serverUri),
  };

  const method = 'getIsolateGroup';
  final pathSegments = <String>[]..addAll(info.serverUri.pathSegments);
  if (pathSegments.isNotEmpty) {
    pathSegments[pathSegments.length - 1] = method;
  } else {
    pathSegments.add(method);
  }
  final requestUri = info.serverUri
      .replace(pathSegments: pathSegments, queryParameters: params);

  try {
    final request = await httpClient.getUrl(requestUri);
    final response = await request.close();
    final Map jsonResponse = await response
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .first;
    final result = jsonResponse['result'];
    expect(result['type'], equals('IsolateGroup'));
    expect(result['id'], startsWith('isolateGroups/'));
    expect(result['number'], new isInstanceOf<String>());
    expect(result['isolates'].length, isPositive);
    expect(result['isolates'][0]['type'], equals('@Isolate'));
  } catch (e) {
    fail('invalid request: $e');
  }
}

var tests = <IsolateTest>[
  (S.Isolate isolate) async {
    await isolate.reload();
    // Just getting here means that the testee enabled the service protocol
    // web server.
    expect(true, true);
  }
];
