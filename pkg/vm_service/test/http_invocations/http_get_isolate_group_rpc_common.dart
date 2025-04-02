// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/expect.dart';
import '../common/service_test_common.dart';
import 'http_request_helpers.dart';

Future<String> _getIsolateGroupId(
  Uri serverUri,
) async {
  final result = await makeHttpServiceRequest(
    serverUri: serverUri,
    method: 'getVM',
  );
  return result['isolateGroups'][0]['id'] as String;
}

final httpGetIsolateGroupRpcTests = <IsolateTest>[
  (VmService service, _) async {
    final wsUri = Uri.parse(service.wsUri!);
    final serverUri = Uri.parse('http://${wsUri.authority}');

    try {
      final result = createServiceObject(
        await makeHttpServiceRequest(
          serverUri: serverUri,
          method: 'getIsolateGroup',
          params: {'isolateGroupId': await _getIsolateGroupId(serverUri)},
        ),
        ['IsolateGroup'],
      )! as IsolateGroup;
      Expect.isTrue(result.id!.startsWith('isolateGroups/'));
      Expect.isNotNull(result.number);
      Expect.isFalse(result.isSystemIsolateGroup);
      Expect.isTrue(result.isolates!.isNotEmpty);
    } catch (e) {
      fail('invalid request: $e');
    }
  }
];
