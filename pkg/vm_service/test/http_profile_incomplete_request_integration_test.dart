// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'http_profile_incomplete_request_integration_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'http_profile_incomplete_request_integration_lib.dart',
      args,
    ).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;

      // Fetch HTTP profiles which calls _createHttpProfileRequestFromProfileMap
      // on this incomplete connection. Safely logic should assert safely no TypeError.
      final profile = await service.getHttpProfile(isolateId);
      expect(profile.requests.length, greaterThanOrEqualTo(1));

      final requestId = profile.requests.first.id;
      await service.getHttpProfileRequest(isolateId, requestId);
    }).run(testeeMain: testee_lib.main);
