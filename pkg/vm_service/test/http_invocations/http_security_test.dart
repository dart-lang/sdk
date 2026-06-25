// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:vm_service/vm_service.dart';
import '../common/expect.dart';
import '../common/service_test_common.dart';
import 'http_auth_get_vm_rpc_lib.dart' as testee_lib;

final securityTests = <IsolateTest>[
  (VmService service, _) async {
    final wsUri = Uri.parse(service.wsUri!);
    final authority = wsUri.authority;
    final token = wsUri.pathSegments.first;

    final client = HttpClient();

    // 1. Test legitimate GET request (should succeed)
    {
      final request =
          await client.getUrl(Uri.parse('http://$authority/$token/getVM'));
      final response = await request.close();
      Expect.equals(HttpStatus.ok, response.statusCode);
      await response.drain();
    }

    // 2. Test GET request with bad Host header (should be blocked with 403)
    {
      final request =
          await client.getUrl(Uri.parse('http://$authority/$token/getVM'));
      request.headers.set(HttpHeaders.hostHeader, 'evil.example.com');
      final response = await request.close();
      Expect.equals(HttpStatus.forbidden, response.statusCode);
      await response.drain();
    }

    // 3. Test GET request with bad Origin header (should be blocked with 403)
    {
      final request =
          await client.getUrl(Uri.parse('http://$authority/$token/getVM'));
      request.headers.set('Origin', 'http://evil.example.com');
      final response = await request.close();
      Expect.equals(HttpStatus.forbidden, response.statusCode);
      await response.drain();
    }

    // 4. Test DevFS PUT request without token (should be blocked with 403)
    {
      final request =
          await client.putUrl(Uri.parse('http://$authority/devfs/test'));
      final response = await request.close();
      Expect.equals(HttpStatus.forbidden, response.statusCode);
      await response.drain();
    }

    // 5. Test DevFS PUT request with wrong token (should be blocked with 403)
    {
      final request = await client
          .putUrl(Uri.parse('http://$authority/wrong-token/devfs/test'));
      final response = await request.close();
      Expect.equals(HttpStatus.forbidden, response.statusCode);
      await response.drain();
    }

    // 6. Test DevFS PUT request with correct token
    // It should pass authentication. It might fail with 500/400 later because
    // we don't provide valid DevFS headers/body, but it should NOT return 403!
    {
      final request =
          await client.putUrl(Uri.parse('http://$authority/$token/devfs/test'));
      final response = await request.close();
      Expect.isTrue(response.statusCode != HttpStatus.forbidden);
      await response.drain();
    }

    client.close();
  }
];

void main([args = const <String>[]]) {
  final harness = IsolateTestHarness(
    'http_auth_get_vm_rpc_lib.dart',
    args,
  );
  for (final test in securityTests) {
    harness.addCustomTest(test);
  }
  harness.run(testeeMain: testee_lib.main, useAuthToken: true);
}
