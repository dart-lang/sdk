// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/expect.dart';
import '../common/test_helper.dart';
import 'http_request_helpers.dart';

Future<String> getIsolateGroupId(
  Uri serverUri,
) async {
  final result = await makeHttpServiceRequest(
    serverUri: serverUri,
    method: 'getVM',
  );
  return result['isolateGroups'][0]['id'] as String;
}

Future<void> testeeBefore() async {
  final info = await Service.getInfo();
  final serverUri = info.serverUri!;
  try {
    final result = createServiceObject(
      await makeHttpServiceRequest(
          serverUri: serverUri,
          method: 'getIsolateGroup',
          params: {'isolateGroupId': await getIsolateGroupId(serverUri)}),
      ['IsolateGroup'],
    )! as IsolateGroup;
    Expect.isTrue(result.id!.startsWith('isolateGroups/'));
    Expect.isNotNull(result.number);
    Expect.isFalse(result.isSystemIsolateGroup);
    Expect.isTrue(result.isolates!.length > 0);
  } catch (e) {
    fail('invalid request: $e');
  }
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolate) async {
    // Just getting here means that the testee enabled the service protocol
    // web server.
  }
];
