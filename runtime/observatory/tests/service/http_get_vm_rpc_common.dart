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

Future<Null> testeeBefore() async {
  print('testee before');
  print(await Service.getInfo());
  // Start the web server.
  ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
  expect(info.serverUri, isNotNull);
  var httpClient = new io.HttpClient();

  // Build the request.
  final pathSegments = <String>[]..addAll(info.serverUri.pathSegments);
  String method = 'getVM';
  if (pathSegments.isNotEmpty) {
    pathSegments[pathSegments.length - 1] = method;
  } else {
    pathSegments.add(method);
  }
  final requestUri = info.serverUri.replace(pathSegments: pathSegments);

  try {
    var request = await httpClient.getUrl(requestUri);
    Map response = await (await request.close())
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .first;
    Map result = response['result'];
    expect(result['type'], equals('VM'));
    expect(result['name'], equals('vm'));
    expect(result['architectureBits'], isPositive);
    expect(result['targetCPU'], new isInstanceOf<String>());
    expect(result['hostCPU'], new isInstanceOf<String>());
    expect(result['version'], new isInstanceOf<String>());
    expect(result['pid'], new isInstanceOf<int>());
    expect(result['startTime'], isPositive);
    expect(result['isolates'].length, isPositive);
    expect(result['isolates'][0]['type'], equals('@Isolate'));
    expect(result['isolateGroups'].length, isPositive);
    expect(result['isolateGroups'][0]['type'], equals('@IsolateGroup'));
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
