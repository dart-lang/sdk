// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import '../common/expect.dart';
import '../common/test_helper.dart';
import 'http_request_helpers.dart';

Future<String> getIsolateId(Uri serverUri) async {
  final result = await makeHttpServiceRequest(
    serverUri: serverUri,
    method: 'getVM',
  );
  return result['isolates'][0]['id'] as String;
}

Future<void> testeeBefore() async {
  final info = await Service.getInfo();
  final serverUri = info.serverUri!;

  try {
    // Build the request.
    final params = <String, String>{
      'isolateId': await getIsolateId(serverUri),
    };

    final result = createServiceObject(
      await makeHttpServiceRequest(
        serverUri: serverUri,
        method: 'getIsolate',
        params: params,
      ),
      ['Isolate'],
    )! as Isolate;
    Expect.isTrue(result.id!.startsWith('isolates/'));
    Expect.isNotNull(result.number);
    Expect.equals(result.json!['_originNumber'], result.number);
    Expect.isTrue(result.startTime! > 0);
    Expect.isTrue(result.livePorts! > 0);
    Expect.isFalse(result.pauseOnExit);
    Expect.isNotNull(result.pauseEvent);
    Expect.isNull(result.error);
    Expect.isNotNull(result.rootLib);
    Expect.isTrue(result.libraries!.isNotEmpty);
    Expect.isTrue(result.breakpoints!.isEmpty);
    Expect.equals(result.json!['_heaps']['new']['type'], 'HeapSpace');
    Expect.equals(result.json!['_heaps']['old']['type'], 'HeapSpace');
    Expect.equals(result.json!['isolate_group']['type'], '@IsolateGroup');
  } catch (e) {
    Expect.fail('invalid request: $e');
  }
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    // Just getting here means that the testee enabled the service protocol
    // web server.
  }
];
