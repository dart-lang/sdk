// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';

import '../common/expect.dart';
import '../common/service_test_common.dart';
import 'http_request_helpers.dart';

Future<String> _getIsolateId(Uri serverUri) async {
  final result = await makeHttpServiceRequest(
    serverUri: serverUri,
    method: 'getVM',
  );
  return result['isolates'][0]['id'] as String;
}

final httpGetIsolateRpcTests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final wsUri = Uri.parse(service.wsUri!);
    final serverUri = Uri.parse('http://${wsUri.authority}');

    try {
      // Build the request.
      final params = <String, String>{
        'isolateId': await _getIsolateId(serverUri),
      };

      final result = createServiceObject(
        await makeHttpServiceRequest(
          serverUri: serverUri,
          method: 'getIsolate',
          params: params,
        ),
        ['Isolate'],
      )! as Isolate;
      Expect.isTrue(result.id!.startsWith('isolates/'), 'id was ${result.id}');
      Expect.isNotNull(result.number);
      Expect.isTrue(result.startTime! > 0, 'startTime was ${result.startTime}');
      Expect.isTrue(result.livePorts! > 0, 'livePorts was ${result.livePorts}');
      Expect.isFalse(result.pauseOnExit);
      Expect.isNotNull(result.pauseEvent);
      Expect.isNull(result.error);
      Expect.isNotNull(result.rootLib);
      Expect.isTrue(result.libraries!.isNotEmpty, 'libraries was empty');
      Expect.isTrue(
          result.breakpoints!.isEmpty, 'breakpoints was ${result.breakpoints}',);
      Expect.equals(result.json!['_heaps']['new']['type'], 'HeapSpace');
      Expect.equals(result.json!['_heaps']['old']['type'], 'HeapSpace');
      Expect.equals(result.json!['isolate_group']['type'], '@IsolateGroup');
    } catch (e) {
      Expect.fail('invalid request: $e');
    }
  },
];
