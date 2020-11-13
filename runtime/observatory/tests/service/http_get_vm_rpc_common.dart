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

Future<Null> testeeBefore() async {
  print('testee before');
  print(await Service.getInfo());
  // Start the web server.
  ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
  Expect.isNotNull(info.serverUri);
  var httpClient = new io.HttpClient();

  // Build the request.
  final pathSegments = <String>[]..addAll(info.serverUri!.pathSegments);
  String method = 'getVM';
  if (pathSegments.isNotEmpty) {
    pathSegments[pathSegments.length - 1] = method;
  } else {
    pathSegments.add(method);
  }
  final requestUri = info.serverUri!.replace(pathSegments: pathSegments);

  try {
    var request = await httpClient.getUrl(requestUri);
    Map response = await (await request.close())
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .first as Map;
    Map result = response['result'];
    Expect.equals(result['type'], 'VM');
    Expect.equals(result['name'], 'vm');
    Expect.isTrue(result['architectureBits'] > 0);
    Expect.type<String>(result['targetCPU']);
    Expect.type<String>(result['hostCPU']);
    Expect.type<String>(result['version']);
    Expect.type<int>(result['pid']);
    Expect.isTrue(result['startTime'] > 0);
    Expect.isTrue(result['isolates'].length > 0);
    Expect.equals(result['isolates'][0]['type'], '@Isolate');
    Expect.isTrue(result['isolateGroups'].length > 0);
    Expect.equals(result['isolateGroups'][0]['type'], '@IsolateGroup');
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
