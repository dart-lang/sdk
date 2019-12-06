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

Future<String> getIsolateId(io.HttpClient httpClient, Uri serverUri) async {
  // Build the request.
  final pathSegments = <String>[]..addAll(serverUri.pathSegments);
  String method = 'getVM';
  if (pathSegments.isNotEmpty) {
    pathSegments[pathSegments.length - 1] = method;
  } else {
    pathSegments.add(method);
  }
  final requestUri = serverUri.replace(pathSegments: pathSegments);
  var request = await httpClient.getUrl(requestUri);
  Map response = await (await request.close())
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(json.decoder)
      .first;
  Map result = response['result'];
  return result['isolates'][0]['id'];
}

Future<Null> testeeBefore() async {
  print('testee before');
  print(await Service.getInfo());
  // Start the web server.
  ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
  expect(info.serverUri, isNotNull);
  var httpClient = new io.HttpClient();

  // Build the request.
  final params = <String, String>{
    'isolateId': await getIsolateId(httpClient, info.serverUri),
  };

  String method = 'getIsolate';
  final pathSegments = <String>[]..addAll(info.serverUri.pathSegments);
  if (pathSegments.isNotEmpty) {
    pathSegments[pathSegments.length - 1] = method;
  } else {
    pathSegments.add(method);
  }
  final requestUri = info.serverUri
      .replace(pathSegments: pathSegments, queryParameters: params);

  try {
    var request = await httpClient.getUrl(requestUri);
    Map response = await (await request.close())
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .first;
    Map result = response['result'];
    expect(result['type'], equals('Isolate'));
    expect(result['id'], startsWith('isolates/'));
    expect(result['number'], new isInstanceOf<String>());
    expect(result['_originNumber'], equals(result['number']));
    expect(result['startTime'], isPositive);
    expect(result['livePorts'], isPositive);
    expect(result['pauseOnExit'], isFalse);
    expect(result['pauseEvent']['type'], equals('Event'));
    expect(result['error'], isNull);
    expect(result['_numZoneHandles'], isPositive);
    expect(result['_numScopedHandles'], isPositive);
    expect(result['rootLib']['type'], equals('@Library'));
    expect(result['libraries'].length, isPositive);
    expect(result['libraries'][0]['type'], equals('@Library'));
    expect(result['breakpoints'].length, isZero);
    expect(result['_heaps']['new']['type'], equals('HeapSpace'));
    expect(result['_heaps']['old']['type'], equals('HeapSpace'));
    expect(result['isolate_group']['type'], equals('@IsolateGroup'));
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
