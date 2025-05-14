// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import '../common/expect.dart';
import '../common/service_test_common.dart';
import 'http_request_helpers.dart';

final httpGetVmRpcTests = <IsolateTest>[
  (VmService service, _) async {
    final wsUri = Uri.parse(service.wsUri!);
    final serverUri = Uri.parse('http://${wsUri.authority}');

    try {
      final result = createServiceObject(
        await makeHttpServiceRequest(
          serverUri: serverUri,
          method: 'getVM',
        ),
        ['VM'],
      )! as VM;
      Expect.equals(result.name, 'vm');
      Expect.isTrue(result.architectureBits! > 0);
      Expect.isNotNull(result.targetCPU);
      Expect.isNotNull(result.hostCPU);
      Expect.isNotNull(result.version);
      Expect.isNotNull(result.pid);
      Expect.isTrue(result.startTime! > 0);
      Expect.isTrue(result.isolates!.isNotEmpty);
      Expect.isTrue(result.isolateGroups!.isNotEmpty);
    } catch (e) {
      Expect.fail('invalid request: $e');
    }
  }
];
