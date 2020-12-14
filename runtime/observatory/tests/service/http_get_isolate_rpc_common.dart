// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;
import 'package:expect/expect.dart';
import 'package:observatory/service_io.dart' as S;
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
      .first as Map;
  Map result = response['result'];
  return result['isolates'][0]['id'] as String;
}

Future<Null> testeeBefore() async {
  print('testee before');
  print(await Service.getInfo());
  // Start the web server.
  ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
  Expect.isNotNull(info.serverUri);
  var httpClient = new io.HttpClient();

  // Build the request.
  final params = <String, String>{
    'isolateId': await getIsolateId(httpClient, info.serverUri!),
  };

  String method = 'getIsolate';
  final pathSegments = <String>[]..addAll(info.serverUri!.pathSegments);
  if (pathSegments.isNotEmpty) {
    pathSegments[pathSegments.length - 1] = method;
  } else {
    pathSegments.add(method);
  }
  final requestUri = info.serverUri!
      .replace(pathSegments: pathSegments, queryParameters: params);

  try {
    var request = await httpClient.getUrl(requestUri);
    Map response = await (await request.close())
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .first as Map;
    Map result = response['result'];
    Expect.equals(result['type'], 'Isolate');
    Expect.isTrue(result['id'].startsWith('isolates/'));
    Expect.type<String>(result['number']);
    Expect.equals(result['_originNumber'], result['number']);
    Expect.isTrue(result['startTime'] > 0);
    Expect.isTrue(result['livePorts'] > 0);
    Expect.isFalse(result['pauseOnExit']);
    Expect.equals(result['pauseEvent']['type'], 'Event');
    Expect.isNull(result['error']);
    Expect.equals(result['rootLib']['type'], '@Library');
    Expect.isTrue(result['libraries'].length > 0);
    Expect.equals(result['libraries'][0]['type'], '@Library');
    Expect.equals(result['breakpoints'].length, 0);
    Expect.equals(result['_heaps']['new']['type'], 'HeapSpace');
    Expect.equals(result['_heaps']['old']['type'], 'HeapSpace');
    Expect.equals(result['isolate_group']['type'], '@IsolateGroup');
  } catch (e) {
    Expect.fail('invalid request: $e');
  }
}

var tests = <IsolateTest>[
  (S.Isolate isolate) async {
    await isolate.reload();
    // Just getting here means that the testee enabled the service protocol
    // web server.
  }
];
